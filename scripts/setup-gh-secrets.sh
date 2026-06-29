#!/bin/bash
# setup-gh-secrets.sh — Set GitHub Actions secrets for both OpenArcade repos
# Prerequisites: GITHUB_TOKEN, VERCEL_TOKEN environment variables
# Usage: ./scripts/setup-gh-secrets.sh
#
# This script sets the following secrets in both repos:
#   - VERCEL_TOKEN
#   - VERCEL_ORG_ID
#   - VERCEL_PROJECT_ID
#   - COOLIFY_DEPLOY_URL

set -e

GITHUB_API="https://api.github.com"

REPOS=(
  "isaalia/openarcade-storefront"
  "isaalia/openarcade-developer-portal"
)

# Required env vars
REQUIRED_VARS=("GITHUB_TOKEN" "VERCEL_TOKEN" "VERCEL_ORG_ID" "VERCEL_PROJECT_ID")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ ERROR: $var is not set"
    exit 1
  fi
done

get_public_key() {
  local repo="$1"
  local response
  response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$GITHUB_API/repos/$repo/actions/secrets/public-key")

  local key_id
  key_id=$(echo "$response" | jq -r '.key_id')
  local key
  key=$(echo "$response" | jq -r '.key')

  if [ "$key_id" = "null" ] || [ -z "$key_id" ]; then
    echo "❌ ERROR: Could not get public key for $repo: $response"
    return 1
  fi

  echo "$key_id:$key"
}

encrypt_secret() {
  # Encrypt a secret using libsodium sealed box
  # Requires: echo <secret> | node encrypt.js <base64_public_key>
  local secret="$1"
  local public_key="$2"
  echo -n "$secret" | node -e "
    const sodium = require('libsodium-wrappers');
    (async () => {
      await sodium.ready;
      const key = Buffer.from('$public_key', 'base64');
      const encrypted = sodium.crypto_box_seal(Buffer.from(require('fs').readFileSync('/dev/stdin')), key);
      console.log(Buffer.from(encrypted).toString('base64'));
    })();
  " 2>/dev/null || {
    # Fallback: use a simpler approach
    echo "⚠️  libsodium not available, trying Python fallback..."
    python3 -c "
import base64, json, sys
try:
    from nacl.bindings import crypto_box_seal
    key = base64.b64decode('$public_key')
    secret = sys.stdin.read().strip().encode()
    encrypted = crypto_box_seal(secret, key)
    print(base64.b64encode(encrypted).decode())
except ImportError:
    print('❌ Need pynacl or libsodium-wrappers')
    sys.exit(1)
" 2>/dev/null || {
      echo "❌ Cannot encrypt — install libsodium-wrappers: npm install libsodium-wrappers"
      return 1
    }
  }
}

set_secret() {
  local repo="$1"
  local secret_name="$2"
  local secret_value="$3"

  echo "  🔐 Setting $secret_name for $repo..."

  local key_data
  key_data=$(get_public_key "$repo") || return 1
  local key_id="${key_data%%:*}"
  local key="${key_data#*:}"

  local encrypted_value
  encrypted_value=$(encrypt_secret "$secret_value" "$key") || return 1

  local response
  response=$(curl -s -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$GITHUB_API/repos/$repo/actions/secrets/$secret_name" \
    -d "{\"encrypted_value\":\"$encrypted_value\",\"key_id\":\"$key_id\"}")

  if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
    echo "  ❌ Failed: $(echo "$response" | jq -r '.message')"
    return 1
  fi

  echo "  ✅ $secret_name set successfully"
}

echo "=========================================="
echo "  OpenArcade — GitHub Secrets Setup"
echo "=========================================="
echo ""

for repo in "${REPOS[@]}"; do
  echo "📦 Repo: $repo"
  echo "  Checking if repo exists..."
  local check
  check=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    "$GITHUB_API/repos/$repo")

  if [ "$check" != "200" ]; then
    echo "  ⏭️  Repo not found or not accessible (HTTP $check). Skipping."
    echo ""
    continue
  fi

  set_secret "$repo" "VERCEL_TOKEN" "$VERCEL_TOKEN"
  set_secret "$repo" "VERCEL_ORG_ID" "$VERCEL_ORG_ID"
  set_secret "$repo" "VERCEL_PROJECT_ID" "$VERCEL_PROJECT_ID"

  if [ -n "$COOLIFY_DEPLOY_URL" ]; then
    set_secret "$repo" "COOLIFY_DEPLOY_URL" "$COOLIFY_DEPLOY_URL"
  else
    echo "  ⏭️  COOLIFY_DEPLOY_URL not set — skipping"
  fi

  echo ""
done

echo "✅ Done!"
echo ""
echo "Next steps:"
echo "  1. Push to main branch on each repo → triggers Vercel deploy"
echo "  2. Verify deployment at:"
echo "     - https://openarcade-storefront.vercel.app"
echo "     - https://openarcade-developer-portal.vercel.app"
