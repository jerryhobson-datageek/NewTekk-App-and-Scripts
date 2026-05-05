#!/usr/bin/env bash
# audit.sh — Full security audit of a remote VM
# Usage: ./audit.sh --target <IP> [--output <dir>] [--user deploy]
set -euo pipefail

TARGET=""; OUTPUT_DIR="$(dirname "$0")/../../security/audits"
SSH_USER="deploy"; SSH_KEY="$HOME/.ssh/id_rsa"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2";     shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --user)   SSH_USER="$2";   shift 2 ;;
    --key)    SSH_KEY="$2";    shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$TARGET" ]] && { echo "Usage: $0 --target <host>"; exit 1; }
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/security-audit-${TARGET//[.:]/-}-$(date +%Y%m%d-%H%M%S).md"
SSH="ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$TARGET"

echo "Starting audit of $TARGET → $REPORT"
{
echo "# Security Audit: $TARGET"
echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S') | **User:** $SSH_USER"
echo ""

for section in \
  "System Info::uname -a; lsb_release -a 2>/dev/null; uptime" \
  "Listening Ports::ss -tlnpu" \
  "UFW Firewall::sudo ufw status verbose 2>/dev/null || echo 'UFW not active'" \
  "Fail2ban::sudo fail2ban-client status 2>/dev/null || echo 'Not running'" \
  "User Accounts::getent passwd | grep -v nologin | grep -v false" \
  "SSH Config::sudo sshd -T 2>/dev/null | grep -E 'permitrootlogin|passwordauth|maxauthtries'" \
  "Failed Logins::sudo grep 'Failed password' /var/log/auth.log 2>/dev/null | tail -10 || echo 'No log'" \
  "Pending Updates::apt list --upgradable 2>/dev/null | head -20" \
  "Docker Containers::docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null || echo 'Docker not running'"
do
  TITLE="${section%%::*}"; CMD="${section##*::}"
  echo "## $TITLE"
  echo '```'
  $SSH "$CMD" 2>&1 || echo "(command failed)"
  echo '```'
  echo ""
done

echo "## Checklist"
echo "- [ ] Root SSH login disabled"
echo "- [ ] Password auth disabled"
echo "- [ ] No unexpected open ports"
echo "- [ ] No failed login brute-force attempts"
echo "- [ ] Pending OS updates applied"
echo "- [ ] Docker containers not running as root"
} 2>&1 | tee "$REPORT"

echo "Audit complete: $REPORT"
