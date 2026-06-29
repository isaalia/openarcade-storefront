# BRIEF.md — OpenArcade Storefront / DUAL DEPLOY Fix (Job JOB-926262d6)

## Status
**INVESTIGATING** — Root cause identified. Awaiting VERCEL_TOKEN via device auth.

⚠️ **USER ACTION NEEDED:** Visit https://vercel.com/oauth/device?user_code=GNDN-SCRD to authorize Vercel CLI access.

## Job Info
- **Job ID:** JOB-926262d6
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap (~$0 used — all work local)
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "storefront" latest prod deployment

---

## ✅ DONE (Investigation Complete)

1. **Workspace populated** — `isaalia/openarcade-storefront` cloned from GitHub
2. **Build verified** — `npm run build` passes cleanly (Next.js 16, TypeScript, all 8 pages)
   ```
   ✓ Compiled successfully in 1254ms
   ✓ TypeScript passed
   ┌ ○ /
   ├ ○ /explore
   ├ ○ /library
   ├ ○ /profile
   ├ ○ /search
   ├ ○ /store
   └ ○ /wallet
   ```
3. **Vercel deployment verified** — `openarcade-storefront.vercel.app` serves all pages HTTP 200
4. **Root cause identified:** All GitHub Actions secrets are EMPTY:
   - `VERCEL_TOKEN` — empty → CI/CD fails immediately
   - `VERCEL_ORG_ID` — empty
   - `VERCEL_PROJECT_ID` — empty
   - `COOLIFY_DEPLOY_URL` — empty
5. **Workflow logs confirmed:** All 4 Deploy to Vercel runs fail with:
   ```
   Error: You defined "--token", but it's missing a value
   ```
6. **GitHub deployments API** — empty (no recorded deployments)
7. **No VERCEL_TOKEN in environment** — session has no Vercel credentials

---

## ⏳ REMAINING — Execution Plan

### Phase 1: Get VERCEL_TOKEN (BLOCKING — needs human auth)

Device auth code: `GNDN-SCRD`
Polling URL: `https://vercel.com/oauth/device?user_code=GNDN-SCRD`

**Action:** Visit the URL above and authorize. The device auth poller is running in background.

When token arrives, it will be saved to `/tmp/vercel_token.txt`.

### Phase 2: Get VERCEL_ORG_ID and VERCEL_PROJECT_ID

```bash
# Get project info to find org and project IDs
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/openarcade-storefront" \
  | grep -o '"id":"[^"]*"\|"orgId":"[^"]*"\|"accountId":"[^"]*"'

# Also check what projects exist
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects?limit=20" | grep '"name"\|"id"'
```

### Phase 3: Set GitHub Actions Secrets

```bash
# Get public key
PUB_KEY_DATA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/isaalia/openarcade-storefront/actions/secrets/public-key")
PUB_KEY_ID=$(echo "$PUB_KEY_DATA" | grep -o '"key_id":"[^"]*"' | cut -d'"' -f4)
PUB_KEY=$(echo "$PUB_KEY_DATA" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)

# Set VERCEL_TOKEN secret
# (libsodium sealed box encryption required — prepare a script)
```

### Phase 4: Deploy to Vercel

```bash
# Deploy production
vercel deploy --prod --token=$VERCEL_TOKEN --yes

# Verify deployment
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v6/deployments?app=openarcade-storefront&target=production&limit=1"
```

### Phase 5: Set Up Coolify/Hetzner (Dual Deploy)

```bash
# Build Docker image
docker build -t openarcade-storefront .

# Configure Coolify deployment webhook URL
# Set COOLIFY_DEPLOY_URL as GitHub secret
```

---

## Root Cause Analysis

**What's broken:** "DUAL DEPLOY BROKEN: Vercel project 'storefront' latest prod deployment is unknown"

| Component | Status | Root Cause |
|-----------|--------|------------|
| Vercel app | ✅ LIVE | Serving HTTP 200 at openarcade-storefront.vercel.app |
| Vercel CI/CD | ❌ FAILING | All 4 workflow runs fail — `--token=` is empty |
| GitHub Secrets | ❌ EMPTY | 0 secrets, 0 variables configured |
| Coolify Deploy | ❌ NOT SETUP | No COOLIFY_DEPLOY_URL |
| Coolify CI/CD | ❌ FAILING | workflow runs fail due to missing secret |

**Why "unknown":** The Vercel project exists and serves traffic, but:
1. No CI/CD pipeline connects GitHub pushes → Vercel deploys
2. No VERCEL_TOKEN exists to query the API for status
3. The project was likely deployed manually via Vercel dashboard, not linked to GitHub

**Fix requires:** VERCEL_TOKEN from device auth → then set secrets → deploy → set up Coolify

---

## 4. GATE7 CHECKLIST

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | Build succeeds cleanly |
| Tests | ⏳ N/A | No test files in repo yet |
| Lint zero errors | ✅ PASS | ESLint passes clean |
| Security scan clean | ⏳ Not run | Need tools (gitleaks, grype) |
| Secret scan clean | ⏳ Pending | Will check after deploy fixed |
| App boots | ✅ PASS | openarcade-storefront.vercel.app live |
| Auth works | ⏳ N/A | No auth system in codebase |
| No TODO in src/ | ✅ PASS | Grep returned nothing |

---

## Blockers

**BLOCKER #1 (awaiting human action):** Need `VERCEL_TOKEN`. 
Device auth link: https://vercel.com/oauth/device?user_code=GNDN-SCRD
Once authorized, token will arrive via polling and fix can proceed.
