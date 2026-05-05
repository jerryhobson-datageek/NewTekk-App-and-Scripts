#!/usr/bin/env bash
# destroy-vm.sh — Safely destroy a Linode VM (requires double confirmation)
# Usage: ./destroy-vm.sh --label <name>  OR  --id <id>
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

LINODE_ID=""; LABEL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)    LINODE_ID="$2"; shift 2 ;;
    --label) LABEL="$2";     shift 2 ;;
    *) error "Unknown: $1" ;;
  esac
done

command -v linode-cli &>/dev/null || error "linode-cli not found"
command -v jq         &>/dev/null || error "jq not found"

if [[ -z "$LINODE_ID" && -n "$LABEL" ]]; then
  LINODE_ID=$(linode-cli linodes list --json | jq -r --arg l "$LABEL" \
    '.[] | select(.label==$l) | .id')
  [[ -z "$LINODE_ID" ]] && error "No VM found: $LABEL"
fi
[[ -z "$LINODE_ID" ]] && error "Provide --id or --label"

VM=$(linode-cli linodes view "$LINODE_ID" --json | jq '.[0]')
VM_LABEL=$(echo "$VM" | jq -r '.label')
VM_IP=$(echo "$VM" | jq -r '.ipv4[0]')

echo -e "\n${RED}⚠️  DESTRUCTIVE — VM WILL BE PERMANENTLY DELETED${NC}"
echo "  Label: $VM_LABEL  |  IP: $VM_IP  |  ID: $LINODE_ID"
read -rp "Type the VM label to confirm: " CONFIRM
[[ "$CONFIRM" != "$VM_LABEL" ]] && error "Label mismatch. Aborted."
read -rp "Type YES to proceed: " FINAL
[[ "$FINAL" != "YES" ]] && { info "Aborted."; exit 0; }

info "Destroying $VM_LABEL..."
linode-cli linodes delete "$LINODE_ID"
info "VM $VM_LABEL destroyed."
