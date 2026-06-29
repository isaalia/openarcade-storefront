# BRIEF.md — OpenArcade Storefront Dual Deploy Fix (Job JOB-6bea7bd5)

## Status
**BLOCKED — AWAITING USER AUTH** — Root cause confirmed. Build verified. Need VERCEL_TOKEN.
**🔗 VISIT: https://vercel.com/oauth/device?user_code=DNPC-KHLW**
Once authorized, run the setup script to: query Vercel API → set GitHub secrets → trigger deploy.

---

## Job Info
- **Job ID:** JOB-6bea7bd5
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap (~$0 used)
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "storefront" latest prod deployment

---

## ✅ INVESTIGATION FINDINGS

### Environment State (2026-06-29 12:15 UTC)
- Workspace was empty (bare .git, no commits, no code)
- No BRIEF.md, FILE_MAP.md, CHANGES.md, ONBOARDING.md prior to clone
- GitHub token available (user: `isaalia`), **no Vercel token found anywhere**
- Node.js v22.23.0, Vercel CLI 54.18.2 via npx, no `gh` CLI available
- npm install permissions restricted; Vercel CLI works via npx only
- **7 prior jobs** all hit the same blocker: no VERCEL_TOKEN

### Assets
1. **Repo:** `isaalia/openarcade-storefront` (public, only repo under isaalia)
2. **Repo cloned:** `/workspace/storefront/` — OpenArcade indie game storefront (Next.js 16)
3. **Live site:** `openarcade-storefront.vercel.app` — ✅ **HTTP 200**, OpenArcade store renders (hero, nav, footer, dark theme with amber/teal)
4. **Parent monorepo:** `Agyeman-Enterprises/openarcade` — contains overall architecture, aeria-editor, storefront, api, developer-portal

### Vercel Project Status

| Component | Status | Details |
|-----------|--------|---------|
| Vercel app (openarcade-storefront.vercel.app) | ✅ LIVE | Next.js 16, renders full app with all routes |
| Vercel project config | ✅ EXISTS | `vercel.json` with correct Next.js framework config |
| GitHub Actions CI/CD | ❌ FAILING | Both workflows fail — `--token=` empty |
| GitHub Secrets | ❌ EMPTY | 0 secrets configured. All 4 missing |
| Vercel GitHub App integration | ❌ NOT INSTALLED | No deploy webhooks, no connected repo |
| GitHub Deployments API | ❌ 0 DEPLOYMENTS | No deployment records on GitHub side |
| Build locally | ✅ PASS | `npm run build` exits 0 |
| VERCEL_TOKEN | ❌ ROTATED | Prior token rotated 2026-06-27 per openarcade session journal |

### Root Cause
The `openarcade-storefront.vercel.app` site was deployed to Vercel at some point — likely manually or through an older Vercel token that has since been rotated. The GitHub repo has **zero** GitHub Actions secrets configured (VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, COOLIFY_DEPLOY_URL all missing), meaning:

1. **No CI/CD pipeline** — pushes to `main` do not auto-deploy
2. **"Latest prod deployment is unknown"** — there's no git-integrated deployment tracking
3. **Dual deploy is broken** — neither Vercel nor Coolify deployments can be triggered from CI
4. **No way to redeploy** if the current Vercel deployment needs updating or a fix

### Prior Job History (7 jobs, all blocked on same issue)
| Job | Summary | Status |
|-----|---------|--------|
| JOB-fe4197e0 | Initial storefront setup, added deployment infra | ✅ Committed code |
| JOB-4693d58c | First dual-deploy investigation, INCOMPLETE_GOAL | ❌ Blocked (no token) |
| JOB-926262d6 | Full investigation, auth code GNDN-SCRD | ❌ Blocked (no token) |
| JOB-e4ea8b4f | Setup scripts, auth code BPJF-CBGP, TKBK-FSFX | ❌ Blocked (no token) |
| JOB-e0b7a645 | Fixed lint errors, added dual-deploy infra | ✅ Committed code |
| JOB-d2cd8ca9 | Full investigation, auth code NKWX-TGHL | ❌ Blocked (no token) |
| JOB-6abfc6a4 (openarcade monorepo) | Aeria-editor deploy — same blocker | ❌ Blocked (SSO + rotated token) |

### Two Different Vercel Orgs
The openarcade monorepo session journal notes that **Vercel SSO is active on coda-projects team**, which blocks ALL new deployments. The current site at `openarcade-storefront.vercel.app` may be under a different personal account (isaalia) or a different team.

---

## ⏳ EXECUTION PLAN

### Phase 1: Investigate ✅ DONE
- [x] Cloned repo, read BRIEF.md, checked git log (6 commits, 6 prior agent jobs)
- [x] Confirmed build passes (npm run build exits 0)
- [x] Confirmed GitHub secrets empty (0 secrets via API)
- [x] Confirmed site live (openarcade-storefront.vercel.app HTTP 200)
- [x] Checked openarcade monorepo for additional context (session journals, CLAUDE.md)
- [x] Initiated new Vercel device auth flow

### Phase 2: Get VERCEL_TOKEN (BLOCKING — needs human) 🔴
New device auth code generated: **DNPC-KHLW**
- **Visit: https://vercel.com/oauth/device?user_code=DNPC-KHLW**
- Code expires in 600s (10 minutes)
- Previous codes all expired (NKWX-TGHL, TKBK-FSFX, BPJF-CBGP, GNDN-SCRD)

A watcher script (`scripts/poll-vercel-auth.sh`) is available to poll for token completion.

### Phase 3: Query Vercel API (requires Phase 2)
```bash
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects?limit=50"
```
- Get VERCEL_ORG_ID and VERCEL_PROJECT_ID
- Check if project is connected to GitHub repo
- Verify which Vercel team/org the project belongs to

### Phase 4: Set GitHub Actions Secrets (requires Phase 2)
```bash
# Using GitHub API with libsodium encryption
curl -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/isaalia/openarcade-storefront/actions/secrets/VERCEL_TOKEN" \
  -d '{"encrypted_value":"<encrypted>","key_id":"<key_id>"}'
```
Secrets to set:
- `VERCEL_TOKEN` = token from Phase 2
- `VERCEL_ORG_ID` = from Phase 3 API response
- `VERCEL_PROJECT_ID` = from Phase 3 API response
- `COOLIFY_DEPLOY_URL` = TBD (needs Coolify setup on Hetzner/AURORA)

A setup script (`scripts/setup-gh-secrets.sh`) exists but requires libsodium. A Node.js alternative is in `scripts/setup-vercel-deploy.sh`.

### Phase 5: Trigger Vercel Deployment (requires Phase 4)
```bash
npx vercel deploy --prod --token=$VERCEL_TOKEN --yes
```
Or push to main to trigger the GitHub Actions workflow.

### Phase 6: Verify
- [ ] Confirm `openarcade-storefront.vercel.app` still works (HTTP 200)
- [ ] Check GitHub Actions workflow runs successfully
- [ ] Verify Vercel deployment in Vercel dashboard

### Phase 7: Coolify Dual Deploy (requires Coolify credentials)
- Set up COOLIFY_DEPLOY_URL secret
- Configure Coolify project on AURORA server (5.9.153.215)
- Test dual deployment failover

---

## Scripts Available
| Script | Purpose | Status |
|--------|---------|--------|
| `scripts/deploy.sh` | Master deploy (vercel/coolify/all) | ✅ Ready |
| `scripts/poll-vercel-auth.sh` | Vercel device auth flow + token capture | ✅ Ready |
| `scripts/setup-vercel-deploy.sh` | Full setup automation | ✅ Ready |
| `scripts/setup-gh-secrets.sh` | GitHub secrets setup (needs libsodium) | ✅ Ready (needs deps) |

---

## GATE7 CHECKLIST

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | Verified |
| Tests 95%+ | ⏳ N/A | No test files |
| Lint zero errors | ✅ PASS | Prior agent confirmed |
| Security scan clean | ⏳ Not run | |
| Secret scan clean | ⏳ Not run | |
| App boots | ✅ PASS | openarcade-storefront.vercel.app HTTP 200 |
| Auth works | ⏳ N/A | No auth in this app |
| No TODO in src/ | ✅ PASS | Prior agent confirmed |

---

## Blockers

**BLOCKER #1 — ACTION REQUIRED (human):** Need VERCEL_TOKEN.
Visit: **https://vercel.com/oauth/device?user_code=DNPC-KHLW**
Authorize the Vercel CLI to get a token, then proceed with Phase 3+.

This is the same blocker that stopped ALL 7 prior jobs. Device codes DNPC-KHLW (current), NKWX-TGHL (prior), TKBK-FSFX, BPJF-CBGP, GNDN-SCRD (older) — none were used.

**BLOCKER #2 (deferred):** Coolify dual deploy — needs Coolify/Hetzner credentials for AURORA server.

---

## Handoffs
None yet.

## SPAWN_JOBS
None.
