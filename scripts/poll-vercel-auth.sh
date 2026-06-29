#!/bin/bash
# poll-vercel-auth.sh — Vercel Device Authorization Poller
# Generates a device code, prints the URL for human to visit,
# and polls until the token is received or the code expires.
#
# Usage: ./scripts/poll-vercel-auth.sh
#
# On success: saves VERCEL_TOKEN to /tmp/vercel_token.txt and prints it

set -e

VERCEL_CLIENT_ID="cl_HYyOPBNtFMfHhaUn9L4QPfTZz6TP47bp"

echo "=========================================="
echo "  Vercel Device Authorization"
echo "=========================================="
echo ""

# Step 1: Request device code
echo "Requesting device code..."
RESPONSE=$(curl -s -X POST "https://api.vercel.com/login/oauth/device-authorization" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$VERCEL_CLIENT_ID&scope=openid+offline_access")

DEVICE_CODE=$(echo "$RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(d.device_code);
")
USER_CODE=$(echo "$RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(d.user_code);
")
VERIFICATION_URL=$(echo "$RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(d.verification_uri_complete);
")
EXPIRES_IN=$(echo "$RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(d.expires_in);
")
INTERVAL=$(echo "$RESPONSE" | node -e "
  const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  console.log(d.interval);
")

if [ -z "$DEVICE_CODE" ] || [ "$DEVICE_CODE" = "undefined" ]; then
  echo "❌ Failed to get device code. Response:"
  echo "$RESPONSE"
  exit 1
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │                                                     │"
echo "  │  1. Visit: $VERIFICATION_URL  │"
echo "  │                                                     │"
echo "  │  2. Enter code: $USER_CODE                           │"
echo "  │                                                     │"
echo "  │  Code expires in ${EXPIRES_IN}s                          │"
echo "  │                                                     │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""

echo "Polling every ${INTERVAL}s for authorization..."
echo "(Press Ctrl+C to cancel)"
echo ""

# Step 2: Poll for token
END_TIME=$((SECONDS + EXPIRES_IN))
TOKEN=""

while [ $SECONDS -lt $END_TIME ]; do
  sleep $INTERVAL

  TOKEN_RESPONSE=$(curl -s -X POST "https://api.vercel.com/login/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$VERCEL_CLIENT_ID&device_code=$DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code")

  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | node -e "
    const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
    console.log(d.access_token || '');
  " 2>/dev/null)

  if [ -n "$ACCESS_TOKEN" ]; then
    TOKEN="$ACCESS_TOKEN"
    echo ""
    echo "  ✅ Authorization successful!"
    echo ""
    echo "$TOKEN" > /tmp/vercel_token.txt
    echo "  Token saved to: /tmp/vercel_token.txt"
    echo ""
    echo "  VERCEL_TOKEN=$TOKEN"
    echo ""
    echo "  Next steps:"
    echo "  1. Run: export VERCEL_TOKEN=\"$TOKEN\""
    echo "  2. Get project IDs:"
    echo "     curl -H \"Authorization: Bearer \$VERCEL_TOKEN\""
    echo "       https://api.vercel.com/v9/projects?limit=20"
    echo "  3. Set GitHub secrets: ./scripts/setup-gh-secrets.sh"
    exit 0
  fi

  ERROR=$(echo "$TOKEN_RESPONSE" | node -e "
    const d = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
    console.log(d.error || '');
  " 2>/dev/null)

  if [ "$ERROR" != "authorization_pending" ] && [ -n "$ERROR" ]; then
    echo "  Error: $TOKEN_RESPONSE"
  fi
done

echo ""
echo "❌ Timed out waiting for authorization."
echo "   Run this script again to generate a new code."
exit 1
