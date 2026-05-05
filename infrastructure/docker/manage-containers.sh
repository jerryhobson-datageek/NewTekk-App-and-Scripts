#!/usr/bin/env bash
# manage-containers.sh — Docker container lifecycle management
# Usage: ./manage-containers.sh <list|start|stop|restart|logs|stats|prune> [name]
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

command -v docker &>/dev/null || error "Docker is not installed"
COMMAND="${1:-list}"; shift || true

case "$COMMAND" in
  list)
    echo -e "\n${CYAN}━━━ Running ━━━${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo -e "\n${CYAN}━━━ Stopped ━━━${NC}"
    docker ps -a --filter "status=exited" \
      --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
    ;;
  start)
    T="${1:-}"; [[ -z "$T" ]] && error "Usage: $0 start <name>"
    docker start "$T" && info "Started $T"
    ;;
  stop)
    T="${1:-}"; [[ -z "$T" ]] && error "Usage: $0 stop <name>"
    docker stop "$T" && info "Stopped $T"
    ;;
  restart)
    T="${1:-}"; [[ -z "$T" ]] && error "Usage: $0 restart <name>"
    docker restart "$T" && info "Restarted $T"
    ;;
  logs)
    T="${1:-}"; [[ -z "$T" ]] && error "Usage: $0 logs <name>"
    docker logs --tail=100 --follow "$T"
    ;;
  stats)
    docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    ;;
  prune)
    read -rp "Remove stopped containers, dangling images, unused volumes? [y/N] " c
    [[ "$c" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
    docker container prune -f && docker image prune -f
    docker volume prune -f && docker network prune -f
    info "Prune complete."
    ;;
  *) error "Commands: list | start | stop | restart | logs | stats | prune" ;;
esac
