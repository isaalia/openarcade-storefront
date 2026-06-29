# BRIEF.md — OpenArcade Storefront DUAL DEPLOY Fix (Job JOB-57c547e9)

## Status
**BLOCKED — AWAITING USER AUTH** — Vercel OAuth device code: CQDL-FKQB
🔗 **https://vercel.com/oauth/device?user_code=CQDL-FKQB**
Polling active (every 5s). Code expires ~600s from generation.

---

## Job Info
- **Job ID:** JOB-57c547e9 (continuation of JOB-e4ea8b4f, JOB-926262d6, JOB-4693d58c, JOB-fe4197e0)
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap (~$0 used)
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "prometheus-cc" latest prod deployment

---

## ✅ VERIFIED (All Prior Findings Confirmed)

1. **Repo:** `isaalia/openarcade-storefront` — Next.js 16 + Tailwind CSS v4 indie game storefront
2. **Site is live** — `openarcade-storefront.vercel.app` returns HTTP 200 (Vercel project name: "prometheus-cc")
3. **Build passes** — `npm run build` exits clean (Next.js 16, standalone output, 8 routes)
4. **Root cause:** All 4 GitHub Actions secrets are EMPTY:
   - `VERCEL_TOKEN` ⛔ → workflow fails with `--token=` empty
   - `VERCEL_ORG_ID` ⛔
   - `VERCEL_PROJECT_ID` ⛔
   - `COOLIFY_DEPLOY_URL` ⛔
5. **GitHub API confirms:** 0 secrets, 0 variables, 0 deployments, 0 webhooks configured
6. **Vercel project exists** — "prometheus-cc" with live production deployment at openarcade-storefront.vercel.app
7. **No Vercel GitHub App integration** installed on the repo

---

## ⏳ EXECUTION PLAN

### Phase 1: Get VERCEL_TOKEN via device auth (BLOCKING — needs human)
✅ Device auth started: `https://vercel.com/oauth/device?user_code=GMCQ-FHHP`
⏳ Polling for authorization every 5s
⏳ On success: token saved to `/tmp/vercel_token.txt`

### Phase 2: Query Vercel API for ORG_ID and PROJECT_ID
Using Vercel REST API with the obtained token:
```bash
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects?limit=50"
```
Try direct lookup: `https://api.vercel.com/v9/projects/openarcade-storefront`

### Phase 3: Set GitHub Actions secrets via API
Use libsodium encryption (Node.js with libsodium-wrappers) to set:
- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

### Phase 4: Trigger Vercel production deployment
```bash
vercel deploy --prod --token=$VERCEL_TOKEN --yes
```

### Phase 5: Set up Coolify dual deploy (if COOLIFY_DEPLOY_URL available)
Push Docker image / configure webhook.

### Phase 6: Verify both deployments working

---

## Root Cause Analysis

| Component | Status | Root Cause |
|-----------|--------|------------|
| Vercel app | ✅ LIVE | HTTP 200 at openarcade-storefront.vercel.app |
| Vercel CI/CD | ❌ FAILING | All workflow runs fail — `--token=` is empty |
| GitHub Secrets | ❌ EMPTY | 0 secrets, 0 variables configured |
| Coolify Deploy | ❌ NOT SETUP | No COOLIFY_DEPLOY_URL configured |

---

## GATE7 CHECKLIST

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | `npm run build` passes clean (Next.js 16) |
| Tests | ⏳ N/A | No test files |
| Lint zero errors | ✅ PASS | Prior agent confirmed |
| Security scan clean | ⏳ Not run | |
| Secret scan clean | ⏳ Pending | |
| App boots | ✅ PASS | openarcade-storefront.vercel.app live |
| Auth works | ⏳ N/A | No auth system |
| No TODO in src/ | ✅ PASS | |

---

## Blockers

**BLOCKER #1 — ACTION REQUIRED:** Need VERCEL_TOKEN for GitHub Actions CI/CD.
Fresh device auth running now via `scripts/poll-vercel-auth.sh`. Visit:

🔗 **https://vercel.com/oauth/device?user_code=CQDL-FKQB**

**Alternative approaches (if device auth is inconvenient):**
1. **Vercel Dashboard PAT:** Go to https://vercel.com/account/tokens → Create token → paste here
2. **Vercel Deploy Hook:** Settings → Git → Deploy Hooks → create → share URL
3. **Local CLI:** Run `vercel.json` on your machine → copy token from `~/.vercel/auth.json`
4. **Vercel GitHub App:** Install it on the repo → no token needed (native integration)

**What I need from you (any one of these works):**
| Item | How to get it |
|------|---------------|
| VERCEL_TOKEN | Paste a Vercel PAT or authorize device flow |
| VERCEL_ORG_ID | Visible in Vercel dashboard URL: `/team/ORG_ID` or Settings → General |
| VERCEL_PROJECT_ID | In Vercel project Settings → General → Project ID |

Once provided:
1. Save token → query Vercel API for ORG_ID and PROJECT_ID (if not provided)
2. Set GitHub Actions secrets via encrypted API (libsodium)
3. Trigger production deployment
4. Verify both deploy targets

⏳ **Poller running in background** — polling every 5s for device auth.

---

## Prior Agents' History
- **JOB-fe4197e0** — Initial setup: Next.js 16 scaffolding, Vercel deploy scripts, dual deploy infra
- **JOB-4693d58c** — Investigation: found 0 GitHub secrets, dead device auth, documented root cause
- **JOB-926262d6** — Continued: confirmed findings, new device auth (GNDN-SCRD), inconclusive
- **JOB-e4ea8b4f** — Automation scripts added. Device codes: BPJF-CBGP, TKBK-FSFX. All expired.
- **JOB-57c547e9 (this job)** — Current. Codes: GMCQ-FHHP (expired), CQDL-FKQB (active).
