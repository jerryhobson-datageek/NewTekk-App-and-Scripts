#!/usr/bin/env bash
# list-vms.sh — List all Linode VMs with status, IP, and specs
# Usage: ./list-vms.sh [--json]
set -euo pipefail

command -v linode-cli &>/dev/null || { echo "linode-cli not found"; exit 1; }
command -v jq         &>/dev/null || { echo "jq not found"; exit 1; }

[[ "${1:-}" == "--json" ]] && { linode-cli linodes list --json; exit 0; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-8s %-25s %-12s %-18s %-12s %s\n" "ID" "LABEL" "STATUS" "IP" "TYPE" "REGION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

linode-cli linodes list --json | jq -r '.[] | [
  (.id|tostring), .label, .status, (.ipv4[0]//"N/A"), .type, .region
] | @tsv' | while IFS=$'\t' read -r id label status ip type region; do
  case "$status" in
    running)  sfmt="\033[0;32m$status\033[0m" ;;
    offline)  sfmt="\033[0;31m$status\033[0m" ;;
    *)        sfmt="$status" ;;
  esac
  printf "%-8s %-25s %-22b %-18s %-12s %s\n" "$id" "$label" "$sfmt" "$ip" "$type" "$region"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total: $(linode-cli linodes list --json | jq 'length') VMs"
