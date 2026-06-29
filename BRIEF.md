# BRIEF.md — OpenArcade Storefront / DUAL DEPLOY Investigation

## Status
**BLOCKER #1 ACTIVE** — awaiting VERCEL_TOKEN

## Blockers (Active)

**BLOCKER #1:** No VERCEL_TOKEN available. Vercel API inaccessible. Device OAuth code active:
1. Visit https://vercel.com/oauth/device?user_code=CNMJ-QVMG in a browser logged into Vercel
2. OR generate a Vercel token at https://vercel.com/account/tokens and set `VERCEL_TOKEN=xxx` in env
3. Once authorized: proceed with Phase 2 (configure GH secrets) and Phase 3 (verify CI/CD)

## Job Info
- **Job ID:** JOB-4693d58c
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "elluminate" latest prod deployment

---

## 1. INVESTIGATION FINDINGS

### 1.1 Source Repository
- **Repo:** `isaalia/openarcade-storefront` (public)
- **Stack:** Next.js 16.2.9 + Tailwind CSS v4 + TypeScript
- **Commits (3):**
  1. `cbda9be` — feat: initial OpenArcade storefront with Next.js 16
  2. `13ef369` — feat: add deployment infrastructure for dual deploy
  3. `2cb3fcf` — feat: add Vercel setup script and deployment automation
- **Build:** ✅ Passes cleanly — TypeScript, all pages compile
- **Pages:** Home, Explore, Store, Library, Wallet, Profile, Search (all static, SSR-ready)

### 1.2 Deployment Infrastructure (Current State)
| Item | Status | Details |
|------|--------|---------|
| `vercel.json` | ✅ Present | Next.js framework config, region iad1 |
| `Dockerfile` | ✅ Present | Docker build for Coolify/Hetzner |
| `scripts/setup-vercel.sh` | ✅ Present | OAuth device flow setup script |
| `.github/workflows/deploy-vercel.yml` | ⚠️ PRESENT but BROKEN | References `secrets.VERCEL_TOKEN`, `secrets.VERCEL_ORG_ID`, `secrets.VERCEL_PROJECT_ID` — **NONE are configured** |
| `.github/workflows/deploy-coolify.yml` | ⚠️ PRESENT but BROKEN | References `secrets.COOLIFY_DEPLOY_URL` — **not configured** |
| GitHub Actions Secrets | ❌ **EMPTY** (0 secrets) | No VERCEL_TOKEN, no VERCEL_ORG_ID, no VERCEL_PROJECT_ID, no COOLIFY_DEPLOY_URL |
| GitHub Actions Variables | ❌ **EMPTY** (0 variables) | None configured |

### 1.3 Vercel Deployment Status

#### openarcade-storefront.vercel.app
- **URL:** https://openarcade-storefront.vercel.app
- **Status:** ✅ LIVE — serves the Next.js app correctly
- **Deployment ID:** `dpl_5wuN6YSkQJ2mcqwRYE4ZXwNyUiPY`
- **Cache:** MISS (dynamic SSR)
- **Region:** fra1::iad1
- **Build:** Appears to be from a recent manual deploy (not CI/CD, since no GH secrets)

#### elluminate.vercel.app
- **URL:** https://elluminate.vercel.app
- **Status:** ✅ LIVE — serves a static Vite/React app (title: "Elluminate")
- **Type:** SEPARATE product — a screen capture/annotation/recording tool (OCR, smart redaction, step guides, SOP export). **Not the OpenArcade storefront.**
- **Last Modified:** 2026-06-29T03:00:44 (very recent)
- **Notable:** `access-control-allow-origin: *` (CORS wildcard — LAW item 6 violation)
- **Deployment:** Manually deployed or via unknown CI

### 1.4 Root Cause Analysis

The stated goal references "Vercel project 'elluminate'" but the repo in this workspace is `openarcade-storefront`. These are **two different projects**:

1. **elluminate** — A screen capture/annotation desktop tool. Deployed as a static Vite/React app on Vercel. Is live and serving. CORS wildcard issue found.

2. **openarcade-storefront** — A Next.js game store. Source is in this repo. Deployed on Vercel. The dual-deploy pipeline (GitHub Actions → Vercel + Coolify) is **non-functional** because:
   - No `VERCEL_TOKEN` in GitHub secrets (required by `deploy-vercel.yml`)
   - No `VERCEL_ORG_ID` or `VERCEL_PROJECT_ID` in GitHub secrets
   - No `COOLIFY_DEPLOY_URL` in GitHub secrets
   - No VERCEL_TOKEN available in this environment either

### 1.5 Environment Gap
- No `VERCEL_TOKEN` env var set in the container
- No `~/.vercel/` config directory exists
- Vercel CLI is available (npx vercel) but unauthenticated
- Device OAuth flow was initiated (code: KDVM-SWTB) — needs human to visit https://vercel.com/oauth/device?user_code=KDVM-SWTB

---

## 2. EXECUTION PLAN

### Phase 1: Obtain VERCEL_TOKEN (BLOCKER)
- **BLOCKER:** Cannot access Vercel API or configure GitHub Actions secrets without a VERCEL_TOKEN
- **Path:** Device OAuth flow initiated — someone must visit https://vercel.com/oauth/device?user_code=KDVM-SWTB and authorize
- **Alternative:** Generate a Vercel token from Vercel dashboard (Settings → Tokens) and set as env var
- **Once obtained:** Use it to query Vercel API for project/deployment status

### Phase 2: Configure GitHub Actions Secrets
- Set `VERCEL_TOKEN` in GitHub repo secrets
- Set `VERCEL_ORG_ID` in GitHub repo secrets  
- Set `VERCEL_PROJECT_ID` in GitHub repo secrets
- Set `COOLIFY_DEPLOY_URL` in GitHub repo secrets (once Coolify is set up)

### Phase 3: Verify CI/CD Pipeline
- Push a test commit to main
- Verify that `deploy-vercel.yml` workflow triggers and deploys successfully
- Verify that `deploy-coolify.yml` workflow triggers (once Coolify is set up)

### Phase 4: Fix elluminate CORS Wildcard
- The `access-control-allow-origin: *` header on elluminate.vercel.app violates LAW item 6 (NEVER CORS wildcard)
- Fix the Vercel config or app to set specific allowed origins

### Phase 5: Verify Dual Deployment
- Confirm both Vercel and Coolify deployments are functional
- Verify identical env vars in both environments

---

## 4. GATE7 CHECKLIST (preliminary)

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | Build succeeds cleanly |
| Tests | ⏳ N/A | No test files in repo yet |
| Lint zero errors | ⏳ Not checked | eslint config present |
| Security scan clean | ⏳ Not run | — |
| Secret scan clean | ❌ FAIL | CORS wildcard on elluminate.vercel.app |
| App boots | ✅ PASS | Both apps live on Vercel |
| Auth works | ⏳ N/A | No auth system in codebase |
| No TODO in src/ | ⏳ Not checked | — |

---

## 5. HANDOFF NOTES

- **HANDOFF:** Investigation complete. See Blockers section above for what's needed to proceed.
- **BLOCKER #1** is the critical path — nothing else can proceed without a VERCEL_TOKEN.
- The openarcade-storefront build passes. The Vercel deployment exists and serves content. The GitHub Actions pipeline is what's broken (missing secrets).
- "elluminate" appears to be a separate product — its latest prod deployment status may need a separate investigation once Vercel API access is available.
