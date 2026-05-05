# Linode Setup Guide

## 1. Create a Linode API Token

1. Log into cloud.linode.com
2. Go to Profile → API Tokens → Create a Personal Access Token
3. Grant Read/Write for: Linodes, Volumes, NodeBalancers
4. Copy the token — you only see it once

## 2. Install the Linode CLI

```bash
pip install linode-cli
linode-cli configure   # Paste your API token when prompted
linode-cli linodes list  # Verify it works
```

## 3. Add Secrets to GitHub

Settings → Secrets and variables → Actions

| Secret | Value |
|--------|-------|
| `LINODE_TOKEN` | Your Linode API token |
| `SSH_PRIVATE_KEY` | Contents of ~/.ssh/id_rsa |
| `KNOWN_HOSTS` | Run: ssh-keyscan <your-vm-ip> |

Variables tab:
| Variable | Value |
|----------|-------|
| `PRODUCTION_IP` | Your main VM's IP address |

## 4. Provision a VM

```bash
cd infrastructure/linode
./provision-vm.sh --label newtekk-prod --type g6-standard-2 --region us-east
```

| Type | vCPU | RAM | Price |
|------|------|-----|-------|
| g6-nanode-1 | 1 | 1GB | ~$5/mo |
| g6-standard-1 | 1 | 2GB | ~$10/mo |
| g6-standard-2 | 2 | 4GB | ~$20/mo |
| g6-standard-4 | 4 | 8GB | ~$40/mo |

## 5. SSH Into Your VM

```bash
ssh deploy@<your-vm-ip>
```

Root login is disabled after hardening. Always use the `deploy` user.
