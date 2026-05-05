#!/usr/bin/env bash
# ubuntu-24.04-stackscript.sh
# Run on a fresh Ubuntu 24.04 VM — installs Docker, hardens SSH, sets up UFW + fail2ban
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "=== [1/7] System update ==="
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq curl wget git unzip jq htop fail2ban ufw \
  ca-certificates gnupg lsb-release apt-transport-https software-properties-common

echo "=== [2/7] Install Docker ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker && systemctl start docker

echo "=== [3/7] Create deploy user ==="
if ! id "deploy" &>/dev/null; then
  useradd -m -s /bin/bash deploy
  usermod -aG docker,sudo deploy
  mkdir -p /home/deploy/.ssh
  cp /root/.ssh/authorized_keys /home/deploy/.ssh/
  chown -R deploy:deploy /home/deploy/.ssh
  chmod 700 /home/deploy/.ssh && chmod 600 /home/deploy/.ssh/authorized_keys
  echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
fi

echo "=== [4/7] Harden SSH ==="
cat > /etc/ssh/sshd_config.d/99-newtekk.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 30
EOF
systemctl restart sshd

echo "=== [5/7] Configure UFW ==="
ufw --force reset
ufw default deny incoming && ufw default allow outgoing
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw --force enable

echo "=== [6/7] Configure fail2ban ==="
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
[sshd]
enabled = true
EOF
systemctl enable fail2ban && systemctl restart fail2ban

echo "=== [7/7] Auto security updates ==="
apt-get install -y -qq unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades

echo "NewTekk VM setup complete. SSH user: deploy | Docker: $(docker --version)"
