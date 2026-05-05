#!/usr/bin/env bash
# update-docker.sh — Pull latest images and recreate containers on all VMs
# Usage: ./update-docker.sh [--target <ip>] [--compose-path <path>]
set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }

SSH_USER="deploy"; SSH_KEY="$HOME/.ssh/id_rsa"
COMPOSE_PATH="/home/deploy/app"; TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)       TARGET="$2";       shift 2 ;;
    --compose-path) COMPOSE_PATH="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

update_vm() {
  local IP="$1"
  local SSH="ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$IP"
  info "[$IP] Pulling latest images..."
  $SSH "cd $COMPOSE_PATH && docker compose pull"
  info "[$IP] Recreating containers..."
  $SSH "cd $COMPOSE_PATH && docker compose up -d --remove-orphans"
  info "[$IP] Cleaning old images..."
  $SSH "docker image prune -f"
  info "[$IP] Status:"
  $SSH "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
}

if [[ -n "$TARGET" ]]; then
  update_vm "$TARGET"
else
  IPS=$(linode-cli linodes list --json | jq -r '.[] | select(.status=="running") | .ipv4[0]')
  while IFS= read -r IP; do [[ -z "$IP" ]] && continue; update_vm "$IP"; done <<< "$IPS"
fi
info "All Docker updates complete."
