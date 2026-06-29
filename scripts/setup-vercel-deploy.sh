#!/bin/bash
# scripts/setup-vercel-deploy.sh
# Automated Vercel deployment setup for GitHub Actions CI/CD
# Run after: user visits https://vercel.com/oauth/device?user_code=BPJF-CBGP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
# GITHUB_TOKEN must be set in the environment (do NOT hardcode)
: "${GITHUB_TOKEN:?GITHUB_TOKEN environment variable is required}"
GITHUB_REPO="isaalia/openarcade-storefront"

echo "=== Vercel Deployment Setup ==="
echo ""

# ============================================================
# STEP 1: Wait for Vercel token
# ============================================================
echo "[1/5] Waiting for Vercel authentication..."
VTOKEN=""

# Check if vercel login already completed
if [ -f "$HOME/.vercel/auth.json" ]; then
    VTOKEN=$(cat "$HOME/.vercel/auth.json" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token)}catch(e){console.error('no token')}})")
fi

if [ -z "$VTOKEN" ]; then
    # Poll for auth completion — wait for .vercel/auth.json
    for i in $(seq 1 60); do
        if [ -f "$HOME/.vercel/auth.json" ]; then
            VTOKEN=$(cat "$HOME/.vercel/auth.json" | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token)}catch(e){console.error('no token')}})")
            if [ -n "$VTOKEN" ]; then
                echo "  ✅ Authenticated!"
                break
            fi
        fi
        echo "  Waiting... (${i}s)"
        sleep 1
    done
fi

if [ -z "$VTOKEN" ]; then
    echo "  ❌ FAILED: No VERCEL_TOKEN obtained. Visit: https://vercel.com/oauth/device?user_code=TKBK-FSFX"
    exit 1
fi

echo "  Token: ${VTOKEN:0:8}..."

# ============================================================
# STEP 2: Query Vercel API for project info
# ============================================================
echo "[2/5] Querying Vercel API for project and org IDs..."

PROJECT_RESPONSE=$(curl -s -H "Authorization: Bearer $VTOKEN" \
  "https://api.vercel.com/v9/projects?limit=50")

PROJECTS=$(echo "$PROJECT_RESPONSE" | node -e "
process.stdin.resume();
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
    try {
        const r = JSON.parse(d);
        if (r.projects) {
            r.projects.forEach(p => {
                console.log(p.name + '|' + p.id + '|' + p.accountId);
            });
        } else if (r.error) {
            console.error('API Error:', r.error.message);
        }
    } catch(e) {
        console.error('Parse error:', e.message);
    }
});
")

echo "  Projects found:"
echo "$PROJECTS" | while IFS='|' read -r name id accountId; do
    echo "    - $name ($id, account: $accountId)"
done

# Find the project
PROJECT_INFO=$(echo "$PROJECTS" | grep "^openarcade-storefront|" | head -1)
if [ -z "$PROJECT_INFO" ]; then
    # Try alternative names
    PROJECT_INFO=$(echo "$PROJECTS" | grep -i "storefront\|openarcade\|designai" | head -1)
fi

if [ -z "$PROJECT_INFO" ]; then
    echo "  ⚠️  Project not found by name. Trying detailed project query..."
    # Try listing all deployments
    DEPLOY_RESPONSE=$(curl -s -H "Authorization: Bearer $VTOKEN" \
      "https://api.vercel.com/v6/deployments?limit=10")
    echo "  Deployments:"
    echo "$DEPLOY_RESPONSE" | node -e "
    process.stdin.resume();
    let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
        try {
            const r = JSON.parse(d);
            if (r.deployments) {
                r.deployments.forEach(dep => {
                    console.log('  - ' + dep.name + ' (' + dep.uid + ') target:' + dep.target + ' state:' + dep.state);
                });
            } else if (r.error) {
                console.error('API Error:', r.error.message);
            }
        } catch(e) {
            console.error('Parse error:', e.message);
        }
    });
    "
fi

# Extract project ID and org ID
VERCEL_PROJECT_ID=""
VERCEL_ORG_ID=""

if [ -n "$PROJECT_INFO" ]; then
    VERCEL_PROJECT_ID=$(echo "$PROJECT_INFO" | cut -d'|' -f2)
    VERCEL_ORG_ID=$(echo "$PROJECT_INFO" | cut -d'|' -f3)
fi

if [ -z "$VERCEL_PROJECT_ID" ]; then
    # Try fetching the project directly
    echo "  Trying direct project lookup..."
    DIRECT_RESPONSE=$(curl -s -H "Authorization: Bearer $VTOKEN" \
      "https://api.vercel.com/v9/projects/openarcade-storefront")
    VERCEL_PROJECT_ID=$(echo "$DIRECT_RESPONSE" | node -e "
    process.stdin.resume();
    let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
        try {
            const r = JSON.parse(d);
            if (r.id) console.log(r.id);
            else if (r.error && r.error.code==='not_found') process.exit(2);
        } catch(e) { console.error('Parse error:', e.message); }
    });
    " 2>/dev/null || echo "")
    VERCEL_ORG_ID=$(echo "$DIRECT_RESPONSE" | node -e "
    process.stdin.resume();
    let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
        try {
            const r = JSON.parse(d);
            if (r.accountId) console.log(r.accountId);
        } catch(e) {}
    });
    " 2>/dev/null || echo "")
fi

echo "  Project ID: ${VERCEL_PROJECT_ID:-NOT FOUND}"
echo "  Org ID: ${VERCEL_ORG_ID:-NOT FOUND}"

if [ -z "$VERCEL_PROJECT_ID" ]; then
    echo "  ❌ FAILED: Could not find Vercel project 'openarcade-storefront'"
    echo "  Creating project via API..."
    CREATE_RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $VTOKEN" \
      -H "Content-Type: application/json" \
      -d '{"name":"openarcade-storefront","framework":"nextjs","gitRepository":{"type":"github","repo":"isaalia/openarcade-storefront"}}' \
      "https://api.vercel.com/v9/projects")
    echo "$CREATE_RESPONSE" | node -e "
    process.stdin.resume();
    let d='';
    process.stdin.on('data',c=>d+=c);
    process.stdin.on('end',()=>{
        try {
            const r = JSON.parse(d);
            if (r.id) console.log('  ✅ Created project: ' + r.id + ' (org: ' + (r.accountId||'?') + ')');
            else if (r.error) console.error('  ❌ Create error:', r.error.message);
        } catch(e) { console.error('Parse error:', e.message); }
    });
    "
fi

# ============================================================
# STEP 3: Set GitHub Actions secrets
# ============================================================
echo "[3/5] Setting GitHub Actions secrets..."

# Get the public key for the repo
PUB_KEY_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPO/actions/secrets/public-key")
PUB_KEY_ID=$(echo "$PUB_KEY_DATA" | node -e "
process.stdin.resume();
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
    try { console.log(JSON.parse(d).key_id); }
    catch(e) { console.error('Parse error:', e.message); }
});
")
PUB_KEY=$(echo "$PUB_KEY_DATA" | node -e "
process.stdin.resume();
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
    try { console.log(JSON.parse(d).key); }
    catch(e) { console.error('Parse error:', e.message); }
});
")

echo "  Public key ID: $PUB_KEY_ID"

# Use Node.js with libsodium to encrypt and set secrets
node -e "
const libsodium = require('libsodium-wrappers');
const https = require('https');

async function setSecret(name, value) {
    await libsodium.ready;
    const keyBytes = Buffer.from('$PUB_KEY', 'base64');
    const valueBytes = Buffer.from(value);
    const encryptedBytes = libsodium.crypto_box_seal(valueBytes, keyBytes);
    const encryptedValue = Buffer.from(encryptedBytes).toString('base64');

    return new Promise((resolve, reject) => {
        const data = JSON.stringify({
            encrypted_value: encryptedValue,
            key_id: '$PUB_KEY_ID'
        });
        const req = https.request({
            hostname: 'api.github.com',
            path: '/repos/$GITHUB_REPO/actions/secrets/' + name,
            method: 'PUT',
            headers: {
                'Authorization': 'Bearer $GITHUB_TOKEN',
                'Content-Type': 'application/json',
                'User-Agent': 'openarcade-deploy-script',
                'Content-Length': Buffer.byteLength(data)
            }
        }, (res) => {
            let body = '';
            res.on('data', c => body += c);
            res.on('end', () => {
                if (res.statusCode === 201 || res.statusCode === 204) {
                    console.log('  ✅ Set ' + name + ' (' + res.statusCode + ')');
                    resolve();
                } else {
                    console.log('  ⚠️  Set ' + name + ' returned ' + res.statusCode + ': ' + body);
                    resolve();
                }
            });
        });
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

(async () => {
    console.log('  Encrypting and setting secrets...');
    try {
        await setSecret('VERCEL_TOKEN', process.env.VTOKEN);
        await setSecret('VERCEL_ORG_ID', process.env.VORGID);
        await setSecret('VERCEL_PROJECT_ID', process.env.VPROJID);
    } catch(e) {
        console.error('  ❌ Error setting secrets:', e.message);
        process.exit(1);
    }
})();
" 2>&1

# Verify secrets were set
echo ""
echo "[4/5] Verifying secrets..."
SECRET_CHECK=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPO/actions/secrets")
echo "  Secrets configured: $(echo "$SECRET_CHECK" | node -e "
process.stdin.resume();
let d='';
process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>{
    try {
        const r = JSON.parse(d);
        console.log(r.total_count + ' secrets: ' + (r.secrets||[]).map(s => s.name).join(', '));
    } catch(e) { console.error('Parse error:', e.message); }
});
")"

# ============================================================
# STEP 5: Trigger deployment
# ============================================================
echo "[5/5] Triggering Vercel deployment..."
# Try deploying via CLI
cd "$WORKSPACE"
npx vercel deploy --prod --token="$VTOKEN" --yes 2>&1 || echo "  Trying GitHub Actions dispatch..."

# Also trigger GitHub Actions workflow
curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ref":"main"}' \
  "https://api.github.com/repos/$GITHUB_REPO/actions/workflows/deploy-vercel.yml/dispatches" \
  && echo "  ✅ Triggered deploy-vercel workflow"

echo ""
echo "=== Setup Complete ==="
echo "Vercel CI/CD should now work on next push to main."
