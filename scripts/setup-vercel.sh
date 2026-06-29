#!/bin/bash
# Vercel Setup Script — OpenArcade Storefront
# Generates device code and waits for browser authorization
# Once authorized, links the project and creates project.json

set -e

VERCEL_CLI="/home/agent/.local/node_modules/.bin/vercel"
VERCEL_BIN="/home/agent/.local/node_modules/vercel/dist/vc.js"

echo "=== Vercel Setup for OpenArcade Storefront ==="
echo ""
echo "This script will:"
echo "1. Generate a device authorization code"
echo "2. Ask you to visit a URL to authorize"
echo "3. Link the project to Vercel"
echo ""

# Check if already logged in
if node "$VERCEL_BIN" whoami --token "$VERCEL_TOKEN" 2>/dev/null; then
  echo "Already logged in to Vercel."
else
  echo "Step 1: Device Authorization"
  echo "------------------------------"
  echo "Requesting device code..."

  # Request device code
  RESPONSE=$(curl -s -X POST "https://api.vercel.com/login/oauth/device-authorization" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=cl_HYyOPBNtFMfHhaUn9L4QPfTZz6TP47bp&scope=openid+offline_access")

  DEVICE_CODE=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.device_code)")
  USER_CODE=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.user_code)")
  VERIFICATION_URL=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.verification_uri_complete)")
  EXPIRES_IN=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.expires_in)")
  INTERVAL=$(echo "$RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.interval)")

  echo ""
  echo "  Your device code: $USER_CODE"
  echo "  Visit: $VERIFICATION_URL"
  echo "  Code expires in: $EXPIRES_IN seconds"
  echo ""
  echo "Waiting for authorization..."
  echo "(Polling every ${INTERVAL}s up to ${EXPIRES_IN}s)"

  # Poll for token
  END_TIME=$((SECONDS + EXPIRES_IN))
  TOKEN=""

  while [ $SECONDS -lt $END_TIME ]; do
    sleep $INTERVAL

    TOKEN_RESPONSE=$(curl -s -X POST "https://api.vercel.com/login/oauth/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=cl_HYyOPBNtFMfHhaUn9L4QPfTZz6TP47bp&device_code=$DEVICE_CODE&grant_type=urn:ietf:params:oauth:grant-type:device_code")

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.access_token || '')" 2>/dev/null)

    if [ -n "$ACCESS_TOKEN" ]; then
      TOKEN="$ACCESS_TOKEN"
      echo "  ✓ Authorization successful!"
      break
    fi

    ERROR=$(echo "$TOKEN_RESPONSE" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.error || '')" 2>/dev/null)
    if [ "$ERROR" != "authorization_pending" ]; then
      echo "  Error: $TOKEN_RESPONSE"
    fi
  done

  if [ -z "$TOKEN" ]; then
    echo ""
    echo "  ✗ Authorization timed out or failed."
    echo "  Run this script again to generate a new code."
    exit 1
  fi

  export VERCEL_TOKEN="$TOKEN"
  echo ""
  echo "VERCEL_TOKEN=$TOKEN"
fi

echo ""
echo "Step 2: Linking Project"
echo "------------------------"

# Link project
node "$VERCEL_BIN" link --token="$VERCEL_TOKEN" --yes --project=openarcade-storefront 2>&1 || true

# Check if project.json was created
if [ -f ".vercel/project.json" ]; then
  echo ""
  echo "  ✓ Project linked!"
  echo "  Project ID: $(node -e "const p=require('./.vercel/project.json'); console.log(p.projectId)")"
  echo "  Org ID: $(node -e "const p=require('./.vercel/project.json'); console.log(p.orgId)")"
else
  echo "  Creating project..."
  node "$VERCEL_BIN" deploy --token="$VERCEL_TOKEN" --yes --public --name=openarcade-storefront 2>&1 || true
fi

echo ""
echo "Step 3: Deployment"
echo "-------------------"

# Deploy
node "$VERCEL_BIN" deploy --token="$VERCEL_TOKEN" --prod --yes 2>&1

echo ""
echo "=== Setup complete ==="
