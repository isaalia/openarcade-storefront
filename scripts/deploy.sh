#!/bin/bash
# deploy.sh — OpenArcade Master Deploy Script
# Handles dual deployment to Vercel and Coolify/Hetzner
#
# Usage:
#   ./scripts/deploy.sh vercel          — Deploy to Vercel
#   ./scripts/deploy.sh coolify          — Deploy to Coolify/Hetzner
#   ./scripts/deploy.sh all              — Deploy to both
#   ./scripts/deploy.sh setup-secrets    — Set up GitHub secrets
#
# Prerequisites:
#   - VERCEL_TOKEN environment variable
#   - vercel CLI installed
#   - Docker installed (for Coolify deploy)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

deploy_vercel() {
  echo ""
  echo "  🚀 Deploying to Vercel..."
  echo ""

  if [ -z "$VERCEL_TOKEN" ]; then
    echo "  ❌ VERCEL_TOKEN not set"
    echo "     Run ./scripts/poll-vercel-auth.sh first"
    exit 1
  fi

  # Build
  echo "  Building..."
  npm run build

  # Deploy
  echo "  Deploying..."
  npx vercel deploy --prod --token="$VERCEL_TOKEN" --yes

  echo ""
  echo "  ✅ Vercel deployment complete!"
}

deploy_coolify() {
  echo ""
  echo "  🐳 Deploying to Coolify/Hetzner..."
  echo ""

  if [ -z "$COOLIFY_DEPLOY_URL" ]; then
    echo "  ❌ COOLIFY_DEPLOY_URL not set"
    echo "     Set it as a GitHub secret or export it"
    exit 1
  fi

  # Build Docker image
  echo "  Building Docker image..."
  docker build -t openarcade-storefront:latest .

  # Trigger Coolify deployment
  echo "  Triggering Coolify deployment..."
  curl -s -X GET "$COOLIFY_DEPLOY_URL" -H "Accept: application/json"

  echo ""
  echo "  ✅ Coolify deployment triggered!"
}

case "${1:-all}" in
  vercel)
    deploy_vercel
    ;;
  coolify)
    deploy_coolify
    ;;
  all)
    deploy_vercel
    deploy_coolify
    ;;
  setup-secrets)
    ./scripts/setup-gh-secrets.sh
    ;;
  *)
    echo "Usage: $0 {vercel|coolify|all|setup-secrets}"
    exit 1
    ;;
esac
