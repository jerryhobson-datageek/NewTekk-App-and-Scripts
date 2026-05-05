# NewTekk App and Scripts

[![Deploy](https://github.com/jerryhobson-datageek/NewTekk-App-and-Scripts/actions/workflows/deploy.yml/badge.svg)](https://github.com/jerryhobson-datageek/NewTekk-App-and-Scripts/actions/workflows/deploy.yml)
[![Security Audit](https://github.com/jerryhobson-datageek/NewTekk-App-and-Scripts/actions/workflows/security-audit.yml/badge.svg)](https://github.com/jerryhobson-datageek/NewTekk-App-and-Scripts/actions/workflows/security-audit.yml)

Master repository for NewTekk infrastructure, applications, and automation scripts.

Managed by [Claude AI](https://claude.ai) — from code to deployment.

---

## What This Repo Does

| Area | Description |
|------|-------------|
| 🖥️ **Linode VMs** | Provision, configure, update, and destroy Ubuntu 24.04 VMs |
| 🐳 **Docker** | Build, deploy, and manage containers and images |
| 🔒 **Security** | Automated audits, CVE scanning, VM hardening, detailed reports |
| 🚀 **Deployment** | CI/CD via GitHub Actions — push to deploy |
| 🔄 **Maintenance** | Automated OS updates, Docker image updates, cleanup |

---

## Repository Structure

```
NewTekk-App-and-Scripts/
├── .github/
│   ├── workflows/          # GitHub Actions CI/CD pipelines
│   └── ISSUE_TEMPLATE/     # Bug & security issue templates
├── infrastructure/
│   ├── linode/             # Linode VM provisioning scripts
│   └── docker/             # Docker management scripts & Compose files
├── apps/
│   ├── web/                # Web applications
│   ├── api/                # API services
│   └── tools/              # Internal tools & dashboards
├── scripts/
│   ├── deploy/             # Deployment & rollback scripts
│   ├── maintenance/        # OS & Docker update scripts
│   └── security/           # Security audit & hardening scripts
├── security/
│   ├── audits/             # Generated security audit reports
│   ├── policies/           # Security policies
│   └── baseline/           # CIS benchmark checklists
├── reports/
│   └── templates/          # Report templates
└── docs/                   # Architecture & operational guides
```

---

## Quick Start

### Prerequisites

- [GitHub CLI](https://cli.github.com/) — `gh auth login`
- [Linode CLI](https://www.linode.com/docs/products/tools/cli/) — `pip install linode-cli`
- [Docker](https://docs.docker.com/engine/install/) installed on your local machine
- A Linode API token (stored as GitHub secret `LINODE_TOKEN`)

### Provision a New VM

```bash
cd infrastructure/linode
./provision-vm.sh --label my-server --type g6-standard-2 --region us-east
```

### Run a Security Audit

```bash
cd scripts/security
./audit.sh --target 192.168.1.100 --output ../../security/audits/
```

### Update All VMs

```bash
cd scripts/maintenance
./update-vms.sh
```

### Deploy an App

```bash
cd scripts/deploy
./deploy-app.sh --app web --env production
```

---

## GitHub Secrets Required

Set these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `LINODE_TOKEN` | Linode API token |
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub password or PAT |
| `SSH_PRIVATE_KEY` | SSH key for VM access |
| `KNOWN_HOSTS` | SSH known_hosts for your VMs |

---

## Automated Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `deploy.yml` | Push to `main` | Deploy apps to Linode VMs |
| `docker-build.yml` | Push to `main` | Build & push Docker images |
| `security-audit.yml` | Weekly (Mon 6am) + manual | Full security scan & report |
| `update-vms.yml` | Weekly (Sun 2am) + manual | OS updates on all VMs |

---

## Documentation

- [Deployment Guide](docs/deployment-guide.md)
- [Linode Setup Guide](docs/linode-setup.md)

---

## Security

Audit reports are stored in `security/audits/` and generated automatically every Monday.
