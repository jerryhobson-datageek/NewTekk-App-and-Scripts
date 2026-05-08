#!/usr/bin/env bash
# deploy-app.sh — Deploy an application to a Linode VM
# Usage: ./deploy-app.sh --app <name> --env <production|staging> --target <ip>
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

APP=""; ENV="production"; TARGET=""
SSH_USER="deploy"; SSH_KEY="$HOME/.ssh/id_rsa"; SSH_PORT="22"
COMPOSE_PATH="/home/deploy/app"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)    APP="$2";    shift 2 ;;
    --env)    ENV="$2";    shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --port)   SSH_PORT="$2"; shift 2 ;;
    *) error "Unknown: $1" ;;
  esac
done

[[ -z "$APP" ]]    && error "Provide --app <name>"
[[ -z "$TARGET" ]] && error "Provide --target <ip>"

SSH="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$TARGET"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deploying: $APP | Env: $ENV | Target: $TARGET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

info "Pulling latest image..."
$SSH "cd $COMPOSE_PATH && docker compose pull $APP"

info "Deploying..."
$SSH "cd $COMPOSE_PATH && docker compose up -d --no-deps --remove-orphans $APP"

info "Waiting 10s for container to stabilise..."
sleep 10

STATUS=$($SSH "docker inspect --format='{{.State.Status}}' $APP 2>/dev/null || echo unknown")
[[ "$STATUS" == "running" ]] && info "Deployment successful — $APP is running" \
  || error "Deployment may have failed — status: $STATUS. Check: docker logs $APP"

$SSH "docker image prune -f"
echo "Deploy complete: $APP → $TARGET"
