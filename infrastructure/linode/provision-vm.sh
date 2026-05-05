#!/usr/bin/env bash
# =============================================================================
# provision-vm.sh — Spin up a new Linode VM (Ubuntu 24.04 LTS)
# Usage: ./provision-vm.sh --label <name> --type <linode-type> --region <region>
# =============================================================================
set -euo pipefail

LABEL=""
TYPE="g6-standard-2"
REGION="us-east"
IMAGE="linode/ubuntu24.04"
SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
STACKSCRIPT_FILE="$(dirname "$0")/configs/ubuntu-24.04-stackscript.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)   LABEL="$2";   shift 2 ;;
    --type)    TYPE="$2";    shift 2 ;;
    --region)  REGION="$2";  shift 2 ;;
    --ssh-key) SSH_KEY_FILE="$2"; shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

[[ -z "$LABEL" ]] && error "Please provide --label <vm-name>"
command -v linode-cli &>/dev/null || error "linode-cli not found. Run: pip install linode-cli"
command -v jq         &>/dev/null || error "jq not found."

ROOT_PASS=$(openssl rand -base64 24)
info "Generated root password (save this): $ROOT_PASS"

[[ ! -f "$SSH_KEY_FILE" ]] && error "SSH public key not found at $SSH_KEY_FILE"
SSH_PUBKEY=$(cat "$SSH_KEY_FILE")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Label : $LABEL  |  Type: $TYPE  |  Region: $REGION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -rp "Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }

info "Creating Linode VM '$LABEL'..."
RESPONSE=$(linode-cli linodes create \
  --label "$LABEL" --type "$TYPE" --region "$REGION" \
  --image "$IMAGE" --root_pass "$ROOT_PASS" \
  --authorized_keys "$SSH_PUBKEY" --booted true --json)

LINODE_ID=$(echo "$RESPONSE" | jq -r '.[0].id')
IP=$(echo "$RESPONSE" | jq -r '.[0].ipv4[0]')
info "VM created! ID=$LINODE_ID  IP=$IP"
info "Waiting for VM to boot..."

for i in $(seq 1 30); do
  STATUS=$(linode-cli linodes view "$LINODE_ID" --json | jq -r '.[0].status')
  [[ "$STATUS" == "running" ]] && break
  echo -n "."; sleep 10
done
echo ""

[[ "$STATUS" == "running" ]] && info "VM is running!" || warn "VM status: $STATUS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ID: $LINODE_ID  |  IP: $IP"
echo " SSH: ssh root@$IP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
