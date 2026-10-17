#!/usr/bin/env bash
set -euo pipefail

ITYPE_LIST="${1:-m8i.large,c8i.large,m7i.large,c7i.large}" # comma or space separated
MONTHS="${2:-24}"
PRODUCT="${3:-Linux/UNIX (Amazon VPC)}"

START="$(date -u -d "$MONTHS months ago" +%Y-%m-%dT%H:%M:%SZ)"
END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Normalize to array (split on commas/spaces)
_tmp="${ITYPE_LIST//,/ }"
read -r -a ITYPES <<<"$_tmp"

# Spot interruption frequency (last month) per region and instance type, shown as availability (100% - frequency)
ADVISOR="$(curl -sf https://spot-bid-advisor.s3.amazonaws.com/spot-advisor-data.json)"

render_table_for_type() {
  local ITYPE="$1"

  echo
  echo "### ${ITYPE}"
  echo
  echo '| region | avg_usd | min_usd | std_dev | availability |'
  echo '|:--|--:|--:|--:|--:|'

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

      # avg, min, stddev via jq
      stats=$(jq -r '
        [ .SpotPriceHistory[].SpotPrice | tonumber ] as $p
        | ($p | length) as $n
        | ($p | add / $n) as $mean
        | ($p | min) as $min
        | ([$p[] | (.-$mean) | . * .] | add / $n | sqrt) as $std
        | "\($mean) \($min) \($std)"
      ' <<<"$json")

      read -r avg min std <<<"$stats"

      # availability, e.g. ">95%" for an interruption frequency of "<5%"
      avail=$(jq -r --arg r "$r" --arg t "$ITYPE" '
        .spot_advisor[$r].Linux[$t].r as $i
        | if $i == null then "n/a" else [">95%", "90-95%", "85-90%", "80-85%", "<80%"][$i] end
      ' <<<"$ADVISOR")

      # Emit TSV (for numeric sort), convert to MD later
      printf "%s\t%.5f\t%.5f\t%.5f\t%s\n" "$r" "$avg" "$min" "$std" "$avail"
    done
  } | sort -k2,2n | head -20 | awk -F'\t' 'BEGIN{OFS=" | "} {print "| " $1, $2, $3, $4, $5 " |"}'
}

for it in "${ITYPES[@]}"; do
  render_table_for_type "$it"
done
