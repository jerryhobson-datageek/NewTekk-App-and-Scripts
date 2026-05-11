#!/usr/bin/env bash
# update-vms.sh – Run apt update/upgrade on all running Linode VMs
# Usage: ./update-vms.sh [--dry-run] [--reboot-if-needed] [--hosts IP1,IP2] [--port PORT]
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

DRY_RUN=false; REBOOT=false; HOSTS_OVERRIDE=""
SSH_USER="deploy"; SSH_KEY="$HOME/.ssh/id_rsa"; SSH_PORT="22"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)          DRY_RUN=true; shift ;;
    --reboot-if-needed) REBOOT=true;  shift ;;
    --user)  SSH_USER="$2"; shift 2 ;;
    --port)  SSH_PORT="$2"; shift 2 ;;
    --hosts) HOSTS_OVERRIDE="$2"; shift 2 ;;
    *)  echo "Unknown: $1"; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$0")/../../reports"
REPORT="$(dirname "$0")/../../reports/update-report-$(date +%Y%m%d-%H%M%S).md"

# Discover IPs: use --hosts if provided, otherwise use linode-cli
if [ -n "$HOSTS_OVERRIDE" ]; then
  info "Using provided hosts: $HOSTS_OVERRIDE"
  IPS=$(echo "$HOSTS_OVERRIDE" | tr ',' '\n')
else
  command -v linode-cli &>/dev/null || { echo "linode-cli not found; use --hosts to specify IPs"; exit 1; }
  command -v jq         &>/dev/null || { echo "jq not found"; exit 1; }
  IPS=$(linode-cli linodes list --json | jq -r '.[] | select(.status=="running") | .ipv4[0]')
fi

$DRY_RUN && warn "DRY RUN – no changes will be made"

{
echo "# VM Update Report – $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "| VM | Result | Reboot Needed |"
echo "|----|--------|---------------|"

while IFS= read -r IP; do
  [[ -z "$IP" ]] && continue
  if $DRY_RUN; then
    PENDING=$(ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
      "sudo apt-get update -qq 2>/dev/null; apt list --upgradable 2>/dev/null | wc -l")
    echo "| $IP | ~$PENDING pending (dry run) | unknown |"
  else
    ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
      "sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq" 2>&1
    REBOOT_NEEDED=$(ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$IP" \
      "[ -f /var/run/reboot-required ] && echo yes || echo no")
    echo "| $IP | updated | $REBOOT_NEEDED |"
    info "$IP updated (reboot: $REBOOT_NEEDED)"
    if [[ "$REBOOT_NEEDED" == "yes" ]] && $REBOOT; then
      warn "Rebooting $IP..."; ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$IP" "sudo reboot" || true
    fi
  fi
done <<< "$IPS"
} | tee "$REPORT"

info "Done. Report: $REPORT"
