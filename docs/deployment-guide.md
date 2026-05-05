# Deployment Guide

## How Deployments Work

Every push to `main` automatically triggers the deploy pipeline:
1. GitHub Actions picks up the change
2. SSH into the target Linode VM
3. Pull the latest Docker image
4. Recreate the container
5. Run a health check and report status

## Manual Deployment

```bash
cd scripts/deploy
./deploy-app.sh --app web --env production --target <VM_IP>
```

## Environment Variables

Copy `.env.example` to `.env` in your app directory. Never commit `.env` files.

## Rollback

If a deployment fails, redeploy from a known-good image tag:

```bash
ssh deploy@<VM_IP>
cd /home/deploy/app
docker compose up -d web
```

## Staging vs Production

- **Staging**: deploy to a separate Linode VM with `--env staging`
- **Production**: protected branch — requires PR approval before merging to `main`
