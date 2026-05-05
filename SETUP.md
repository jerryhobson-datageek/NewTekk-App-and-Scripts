# Getting Started — Push to GitHub

Follow these steps to get the NewTekk-App-and-Scripts repository live on GitHub.

---

## Step 1 — Install GitHub CLI

Download from: https://cli.github.com/

Or on Windows with winget:
```powershell
winget install GitHub.cli
```

Verify (open a NEW PowerShell window after installing):
```bash
gh --version
```

---

## Step 2 — Authenticate with GitHub

```bash
gh auth login
```

Choose: GitHub.com → HTTPS → Login with a web browser

---

## Step 3 — Create the GitHub Repository

```powershell
cd "C:\Users\jerry\Documents\NewTekk-App-and-Scripts"
git init
git add .
git commit -m "Initial commit — NewTekk App and Scripts"
gh repo create NewTekk-App-and-Scripts --public --source=. --remote=origin --push
```

Your repo will be live at:
https://github.com/jerryhobson-datageek/NewTekk-App-and-Scripts

---

## Step 4 — Add GitHub Secrets

Go to: Settings → Secrets and variables → Actions → New repository secret

| Secret Name | What to paste |
|-------------|---------------|
| `LINODE_TOKEN` | Your Linode API token |
| `SSH_PRIVATE_KEY` | Run: `cat ~/.ssh/id_rsa` and paste the full key |
| `KNOWN_HOSTS` | Run: `ssh-keyscan <your-vm-ip>` and paste output |
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub password or access token |

Add repository variables (Variables tab):

| Variable | Value |
|----------|-------|
| `PRODUCTION_IP` | Your main Linode VM IP address |

---

## Step 5 — Test a Workflow

1. Go to your repo on GitHub → Actions
2. Click Security Audit → Run workflow
3. Check the uploaded report artifact

---

## You're Done!

- Push to `main` → auto-deploys your apps
- Every Monday 6am → security audit runs automatically
- Every Sunday 2am → VM OS updates run automatically
