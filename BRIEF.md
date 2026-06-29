# BRIEF.md — FormPilot / DUAL DEPLOY Fix (Job JOB-d2cd8ca9)

## Status
**BLOCKED — AWAITING USER AUTH** — Root cause confirmed. Build verified. Need VERCEL_TOKEN.
**🔗 VISIT: https://vercel.com/oauth/device?user_code=NKWX-TGHL**
Once authorized, run `/goal` to continue with: query Vercel API → set GitHub secrets → trigger deploy.

---

## Job Info
- **Job ID:** JOB-d2cd8ca9 (was empty workspace, cloned repo at start)
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap (~$0 used)
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "formpilot" latest prod deployment

---

## ✅ INVESTIGATION FINDINGS

### Environment State
- Workspace was empty (bare .git, no commits, no code)
- No BRIEF.md, FILE_MAP.md, CHANGES.md, ONBOARDING.md, or session journals
- GitHub token available (user: `isaalia`), no Vercel token found anywhere
- Node.js v22.23.0, Vercel CLI 54.18.2, no `gh` CLI, no Python
- Prior agent BRIEF.md found in cloned repo (JOB-e4ea8b4f continuation chain)

### Assets
1. **Repo:** `isaalia/openarcade-storefront` (public, only repo for isaalia)
2. **Repo cloned:** `/workspace/storefront/` — OpenArcade indie game storefront (Next.js 16)
3. **Live site A:** `openarcade-storefront.vercel.app` — ✅ **HTTP 200**, OpenArcade store works
4. **Live site B:** `formpilot.vercel.app` — ❌ **HTTP 500**, `MIDDLEWARE_INVOCATION_FAILED` (different app — has Clerk auth, Form Builder branding)

### Root Cause

| Component | Status | Root Cause |
|-----------|--------|------------|
| Vercel app (openarcade-storefront.vercel.app) | ✅ LIVE | OpenArcade store live and serving |
| Vercel app (formpilot.vercel.app) | ❌ BROKEN | MIDDLEWARE_INVOCATION_FAILED — different codebase (Clerk + Form Builder), not from this repo |
| GitHub Actions CI/CD | ❌ FAILING | Both workflows fail — `--token=` empty |
| GitHub Secrets | ❌ EMPTY | 0 secrets configured. All 4 missing: VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, COOLIFY_DEPLOY_URL |
| Build locally | ✅ PASS | `npm run build` exits 0 (8 static routes) |
| Prior job chain | ⚠️ 6 prior jobs | All blocked on same issue — human never visited device auth URL |

### Prior Job History (from git log)
- JOB-57c547e9: Device code CQDL-FKQB, alternative auth approaches documented
- JOB-e4ea8b4f: Auth URL BPJF-CBGP, setup script, extended watcher
- JOB-926262d6: Initial BRIEF.md with findings
- JOB-4693d58c: INCOMPLETE_GOAL signal
- JOB-fe4197e0: Vercel setup script + deployment infrastructure

### Key Discovery: Two different Vercel apps
- `openarcade-storefront.vercel.app` = THIS repo (OpenArcade). Works.
- `formpilot.vercel.app` = DIFFERENT app (Clerk + Form Builder). Broken. Not in this repo's git history at all (no middleware, no Clerk ever committed).
- No Vercel webhooks or deploy keys on this GitHub repo → Vercel project was deployed from outside GitHub
- The "formpilot" Vercel project and this GitHub repo may NOT be connected. The mission title references "formpilot" but the actual repo is `openarcade-storefront`.

---

## ⏳ EXECUTION PLAN

### Phase 1: Investigate ✅ DONE
- Cloned repo, read BRIEF.md, checked git log, built project
- Confirmed build passes, confirmed GitHub secrets empty, confirmed site live

### Phase 2: Get VERCEL_TOKEN (BLOCKING — needs human) 🔴
- Vercel device auth started. Visit: **https://vercel.com/oauth/device?user_code=NKWX-TGHL**
- Prior codes all expired (BPJF-CBGP, CQDL-FKQB, TKBK-FSFX)

### Phase 3: Query Vercel API (requires Phase 2)
```bash
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/openarcade-storefront"
```

### Phase 4: Set GitHub Actions Secrets (requires Phase 3)
Use GitHub API with libsodium encryption:
- `VERCEL_TOKEN` = the token from Phase 2
- `VERCEL_ORG_ID` = from Phase 3 API response
- `VERCEL_PROJECT_ID` = from Phase 3 API response
- `COOLIFY_DEPLOY_URL` = TBD (needs Coolify setup)

### Phase 5: Trigger Vercel Deployment (requires Phase 4)
```bash
vercel deploy --prod --token=$VERCEL_TOKEN --yes
```

### Phase 6: Verify
- Confirm `openarcade-storefront.vercel.app` still works
- Check `formpilot.vercel.app` — may need separate repo/codebase
- Verify GitHub Actions deploy succeeds

### Phase 7: Coolify Dual Deploy
- Set up `COOLIFY_DEPLOY_URL` secret
- Push Docker image or configure webhook

---

## GATE7 CHECKLIST

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | Verified by JOB-d2cd8ca9 |
| Tests 95%+ | ⏳ N/A | No test files |
| Lint zero errors | ✅ PASS | Prior agent confirmed |
| Security scan clean | ⏳ Not run | |
| Secret scan clean | ⏳ Not run | |
| App boots | ✅ PASS | openarcade-storefront.vercel.app HTTP 200 |
| Auth works | ⏳ N/A | No auth in this app |
| No TODO in src/ | ✅ PASS | |

---

## Blockers

**BLOCKER #1 — ACTION REQUIRED (human):** Need VERCEL_TOKEN.
Visit: **https://vercel.com/oauth/device?user_code=NKWX-TGHL**
Authorize the Vercel CLI to get a token, then proceed with Phase 3+.

**BLOCKER #2 — CLARIFICATION NEEDED:** The `formpilot.vercel.app` app is a different codebase (Clerk + Next.js form builder). This repo's code (`openarcade-storefront`) deploys to `openarcade-storefront.vercel.app` which works fine. If "formpilot" mission refers to a different project, need separate repo access.

---

## Handoffs
None yet.

## SPAWN_JOBS
None.
