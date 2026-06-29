#!/bin/bash
# deploy.sh — OpenArcade Master Deploy Script
# Handles dual deployment to Vercel and Coolify/Hetzner
#
# Usage:
#   ./scripts/deploy.sh vercel              — Deploy to Vercel (needs VERCEL_TOKEN)
#   ./scripts/deploy.sh hook                — Deploy via Vercel deploy hook (DEPLOY_HOOK_URL)
#   ./scripts/deploy.sh coolify             — Deploy to Coolify/Hetzner
#   ./scripts/deploy.sh all                 — Deploy to all configured targets
#   ./scripts/deploy.sh setup-secrets       — Set up GitHub secrets
#   ./scripts/deploy.sh status              — Check deployment status
#
# Prerequisites:
#   - VERCEL_TOKEN (for vercel mode) or DEPLOY_HOOK_URL (for hook mode)
#   - vercel CLI installed
#   - Docker installed (for Coolify deploy)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

deploy_vercel() {
  echo ""
  echo -e "${CYAN}  🚀 Deploying to Vercel (token mode)...${NC}"
  echo ""

  if [ -z "$VERCEL_TOKEN" ]; then
    echo -e "  ${RED}❌ VERCEL_TOKEN not set${NC}"
    echo "     Run ./scripts/poll-vercel-auth.sh first or use './deploy.sh hook'"
    exit 1
  fi

  # Build
  echo -e "  ${YELLOW}Building...${NC}"
  npm run build

  # Deploy
  echo -e "  ${YELLOW}Deploying...${NC}"
  npx vercel deploy --prod --token="$VERCEL_TOKEN" --yes

  echo ""
  echo -e "  ${GREEN}✅ Vercel deployment complete!${NC}"
}

deploy_hook() {
  echo ""
  echo -e "${CYAN}  🚀 Deploying via Vercel Deploy Hook...${NC}"
  echo ""

  if [ -z "$DEPLOY_HOOK_URL" ]; then
    echo -e "  ${RED}❌ DEPLOY_HOOK_URL not set${NC}"
    echo "     Set it as a GitHub secret or export it"
    echo "     Create one at: Vercel Dashboard → Settings → Git → Deploy Hooks"
    exit 1
  fi

  # Build (validate)
  echo -e "  ${YELLOW}Building (validation)...${NC}"
  npm run build

  # Trigger hook
  echo -e "  ${YELLOW}Triggering deploy hook...${NC}"
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$DEPLOY_HOOK_URL")
  echo -e "  Response: HTTP $RESPONSE"

  if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "201" ]; then
    echo -e "  ${GREEN}✅ Deploy hook triggered successfully!${NC}"
  else
    echo -e "  ${YELLOW}⚠️ Hook returned HTTP $RESPONSE — check Vercel dashboard${NC}"
  fi

  echo ""
  echo -e "  ${GREEN}✅ Hook deploy triggered!${NC}"
  echo "     Check status at: https://vercel.com/dashboard"
}

deploy_coolify() {
  echo ""
  echo -e "${CYAN}  🐳 Deploying to Coolify/Hetzner...${NC}"
  echo ""

  if [ -z "$COOLIFY_DEPLOY_URL" ]; then
    echo -e "  ${RED}❌ COOLIFY_DEPLOY_URL not set${NC}"
    echo "     Set it as a GitHub secret or export it"
    exit 1
  fi

  # Build Docker image
  echo -e "  ${YELLOW}Building Docker image...${NC}"
  docker build -t openarcade-storefront:latest .

  # Trigger Coolify deployment
  echo -e "  ${YELLOW}Triggering Coolify deployment...${NC}"
  curl -s -X GET "$COOLIFY_DEPLOY_URL" -H "Accept: application/json"

  echo ""
  echo -e "  ${GREEN}✅ Coolify deployment triggered!${NC}"
}

deploy_status() {
  echo ""
  echo -e "${CYAN}  📡 Deployment Status${NC}"
  echo ""
  echo -e "  ${YELLOW}Vercel:${NC}"
  echo -e "    URL: https://openarcade-storefront.vercel.app"
  echo -e "    $(curl -s -o /dev/null -w 'HTTP %{http_code}' --max-time 5 https://openarcade-storefront.vercel.app/ || echo 'unreachable')"
  echo ""
  echo -e "  ${YELLOW}GitHub Secrets:${NC}"
  echo -e "    VERCEL_TOKEN:     $([ -n "$VERCEL_TOKEN" ] && echo '✅ set' || echo '❌ not set')"
  echo -e "    DEPLOY_HOOK_URL:  $([ -n "$DEPLOY_HOOK_URL" ] && echo '✅ set' || echo '❌ not set')"
  echo -e "    COOLIFY_DEPLOY_URL: $([ -n "$COOLIFY_DEPLOY_URL" ] && echo '✅ set' || echo '❌ not set')"
  echo ""
  echo -e "  ${YELLOW}Secret approach:${NC}"
  if [ -n "$VERCEL_TOKEN" ]; then
    echo -e "    Will use token-based deploy (deploy-vercel.yml)"
  elif [ -n "$DEPLOY_HOOK_URL" ]; then
    echo -e "    Will use hook-based deploy (deploy-hook.yml)"
  else
    echo -e "    ${RED}No deploy method configured${NC}"
    echo -e "    Set VERCEL_TOKEN or DEPLOY_HOOK_URL"
  fi
}

case "${1:-all}" in
  vercel)
    deploy_vercel
    ;;
  hook)
    deploy_hook
    ;;
  coolify)
    deploy_coolify
    ;;
  all)
    deploy_vercel || true
    deploy_hook || true
    deploy_coolify || true
    ;;
  setup-secrets)
    node "$PROJECT_DIR/scripts/setup-secrets.js"
    ;;
  status)
    deploy_status
    ;;
  *)
    echo "Usage: $0 {vercel|coolify|hook|all|setup-secrets|status}"
    exit 1
    ;;
esac
