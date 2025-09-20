#!/usr/bin/env bash
# Usage:
#   ./cheapest-spot.sh "<itype[,itype2 ...]>" [hours] [product] [target-capacity] [sps-samples]
# Examples:
#   ./cheapest-spot.sh "t3.medium,t4g.small" 168 "Linux/UNIX (Amazon VPC)" 1 3
#   ./cheapest-spot.sh "t3.medium t4g.small"

set -euo pipefail

ITYPE_LIST="${1:-t4g.small,t3.small,t4g.medium,t3.medium,c8g.medium,t4g.large,t3.large,c8g.large}" # comma or space separated
HOURS="${2:-168}"
PRODUCT="${3:-Linux/UNIX (Amazon VPC)}"

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
  echo '| region | avg_usd | min_usd |'
  echo '|:--|--:|--:|'

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

      # Emit TSV (for numeric sort), convert to MD later
      printf "%s\t%.5f\t%.5f\n" "$r" "$avg" "$min"
    done
  } | sort -k2,2n | head -11 | awk -F'\t' 'BEGIN{OFS=" | "} {print "| " $1, $2, $3 " |"}'
}

for it in "${ITYPES[@]}"; do
  render_table_for_type "$it"
done
