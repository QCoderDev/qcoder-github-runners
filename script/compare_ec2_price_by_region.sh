#!/usr/bin/env bash
# Usage:
#   ./cheapest-spot.sh "<itype[,itype2 ...]>" [hours] [product] [target-capacity] [sps-samples]
# Examples:
#   ./cheapest-spot.sh "t3.medium,t4g.small" 168 "Linux/UNIX (Amazon VPC)" 1 3
#   ./cheapest-spot.sh "t3.medium t4g.small"

set -euo pipefail

ITYPE_LIST="${1:-t4g.small,t4g.medium,t3.small,t3.medium}"                  # comma or space separated
HOURS="${2:-168}"
PRODUCT="${3:-Linux/UNIX (Amazon VPC)}"
TARGET_CAPACITY="${4:-1}"                     # units (see --target-capacity-unit-type)
SPS_SAMPLES="${5:-1}"                         # take N instantaneous samples and average them

START="$(date -u -d "$HOURS hours ago" +%Y-%m-%dT%H:%M:%SZ)"
END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Normalize to array (split on commas/spaces)
_tmp="${ITYPE_LIST//,/ }"
read -r -a ITYPES <<<"$_tmp"

render_table_for_type() {
  local ITYPE="$1"

  echo
  echo "### ${ITYPE}"
  echo
  echo '| region | avg_usd | min_usd | az_samples | avg_sps | sps_az_n |'
  echo '|:--|--:|--:|--:|--:|--:|'

  {
    for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
      # ----- spot price history -----
      json=$(aws ec2 describe-spot-price-history \
        --region "$r" \
        --instance-types "$ITYPE" \
        --product-description "$PRODUCT" \
        --start-time "$START" \
        --end-time "$END" \
        --output json 2>/dev/null || true)

      count=$(jq '[.SpotPriceHistory[]] | length' <<<"$json")
      if [[ "$count" -eq 0 ]]; then continue; fi

      avg=$(jq -r '[.SpotPriceHistory[].SpotPrice|tonumber] | (add/length)' <<<"$json")
      min=$(jq -r '[.SpotPriceHistory[].SpotPrice|tonumber] | min' <<<"$json")
      azs=$(jq -r '[.SpotPriceHistory[].AvailabilityZone] | unique | length' <<<"$json")

      # ----- spot placement score (instantaneous, averaged) -----
      sps_sum=0
      sps_n=0
      sps_az_n_total=0

      for _ in $(seq 1 "$SPS_SAMPLES"); do
        sps_json=$(aws ec2 get-spot-placement-scores \
          --region "$r" \
          --instance-types "$ITYPE" \
          --target-capacity "$TARGET_CAPACITY" \
          --single-availability-zone \
          --region-names "$r" \
          --output json 2>/dev/null || true)

        sps_avg_one=$(jq -r '
          (.SpotPlacementScores // []) as $s
          | if ($s|length)==0 then empty
            else ($s | map(.Score) | add / length)
            end
        ' <<<"$sps_json")

        sps_az_n_one=$(jq -r '(.SpotPlacementScores // []) | length' <<<"$sps_json")

        if [[ -n "${sps_avg_one:-}" ]]; then
          sps_sum=$(awk -v a="$sps_sum" -v b="$sps_avg_one" 'BEGIN{printf "%.6f", a+b}')
          sps_n=$((sps_n+1))
          sps_az_n_total=$((sps_az_n_total + sps_az_n_one))
        fi
      done

      if [[ "$sps_n" -gt 0 ]]; then
        avg_sps=$(awk -v s="$sps_sum" -v n="$sps_n" 'BEGIN{printf "%.5f", s/n}')
      else
        avg_sps="NA"
      fi

      # Emit TSV (for numeric sort), convert to MD later
      printf "%s\t%.5f\t%.5f\t%s\t%s\t%s\n" "$r" "$avg" "$min" "$azs" "$avg_sps" "${sps_az_n_total:-0}"
    done
  } | sort -k2,2n | head -11 | awk -F'\t' 'BEGIN{OFS=" | "} {print "| " $1, $2, $3, $4, $5, $6 " |"}'
}

for it in "${ITYPES[@]}"; do
  render_table_for_type "$it"
done
