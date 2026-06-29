# BRIEF.md — OpenArcade Aeria Editor Dual Deploy Fix (Job JOB-d7f00c0d)

## Status
**BLOCKED — NEEDS VERCEL_TOKEN** (12+ prior jobs, same blocker, all codes expired unused)

**⚠️ VERCEL_TOKEN ROTATED 2026-06-27** — fleet-wide rotation invalidated all prior tokens.
**⚠️ VERCEL SSO ACTIVE on coda-projects team** — blocks new deployments even with token.
**⚠️ ZERO GITHUB SECRETS** on both repos (storefront + monorepo).

**🔗 VISIT: https://vercel.com/oauth/device?user_code=VQDB-CBFW** (generated ~16:34 UTC, expires ~16:44 UTC)
**🔄 ALSO: https://vercel.com/oauth/device?user_code=HQBT-CBWN** (from `vercel whoami` CLI, same window)

Once authorized, `~/.vercel/auth.json` is populated. Run `scripts/setup-vercel-deploy.sh` in this workspace to configure everything.

---

## Job Info
- **Job ID:** JOB-d7f00c0d
- **Floor:** 0
- **Agent:** Agent (agent@aigemantowers.com)
- **Budget:** $5.00 hard cap (~$0 used — no API calls needed)
- **Goal:** DUAL DEPLOY BROKEN — investigate and fix Vercel project "openarcade-aeria-editor" latest prod deployment

---

## ✅ INVESTIGATION FINDINGS

### Environment State (2026-06-29 16:34 UTC)
- Workspace: `/workspace` — had bare .git, cloned `isaalia/openarcade-storefront` + `Agyeman-Enterprises/openarcade`
- **VERCEL_TOKEN: NOT FOUND** — not in env, not in Vercel CLI config, nowhere on filesystem
- **GITHUB_TOKEN: AVAILABLE** (user `isaalia`, admin on both repos)
- Tools: Node 22.23.0, Vercel CLI 54.18.3 (via npx), no global install perms

### Assets Checked
1. **Standalone storefront repo:** `isaalia/openarcade-storefront` — Next.js 16 ✅ LIVE
2. **Monorepo:** `Agyeman-Enterprises/openarcade` — aeria-editor, api, developer-portal, storefront, launcher
3. **Aeria Editor code:** `/workspace/openarcade-monorepo/apps/aeria-editor/` — Vite SPA
4. **Live site:** `https://openarcade-aeria-editor.vercel.app/` → **HTTP 200** ✅
5. **Live storefront:** `https://openarcade-storefront.vercel.app/` → **HTTP 200** ✅
6. **Live dev portal:** `https://openarcade-developer-portal.vercel.app/` → **HTTP 200** ✅
7. **API:** `https://openarcade-api.vercel.app/` → **HTTP 404** ❌ (never deployed)

### Aeria Editor Build State (Verified NOW, 16:34 UTC)
| Check | Status | Detail |
|-------|--------|--------|
| `pnpm install` | ✅ PASS | 9.5s, all deps resolved |
| `tsc && vite build` | ✅ PASS | 5 modules transformed, 81ms |
| dist output | ✅ PASS | `dist/index.html` (0.25 kB) + `dist/assets/index-*.js` (5.73 kB) |

### Aeria Editor App Details
- **Stack:** TypeScript, Vite 6, `@openarcade/sdk-aeria`
- **Deploy type:** Static SPA (Vite build → Vercel static or Nginx)
- **Env var:** `VITE_OPENARCADE_API_URL` (defaults to localhost:3000 — **no production value set**)
- **vercel.json:** Correct — `{framework: "vite", buildCommand: "cd ../.. && pnpm ..."}`
- **Dockerfile:** Multi-stage (Node build → Nginx serve) ✅ for Coolify/Hetzner
- **Source:** `src/main.ts` — login form + game publish UI, API client only

### Vercel Project Status

| Component | Status | Details |
|-----------|--------|---------|
| openarcade-aeria-editor.vercel.app | ✅ LIVE | HTTP 200, serves app |
| vercel.json config | ✅ CORRECT | Vite framework, monorepo-aware build |
| GitHub Actions CI/CD | ❌ FAILING | Workflow guarded by `if: ${{ secrets.VERCEL_TOKEN != '' }}` — always skipped |
| GitHub Secrets (BOTH repos) | ❌ 0/4 | VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID, COOLIFY_WEBHOOK all missing |
| Vercel GitHub App integration | ❌ NOT INSTALLED | No deploy webhooks, no connected repo |
| GitHub Deployments API | ❌ 0 DEPLOYMENTS | No records on GitHub side |
| VERCEL_TOKEN | ❌ ROTATED | Rotated fleet-wide 2026-06-27 |
| Vercel SSO (coda-projects team) | ❌ ACTIVE | Blocks ALL new deployments since SSO was enabled |
| Coolify/Hetzner dual deploy | ❌ NOT CONFIGURED | Dockerfile ready, no Coolify credentials in env |

### Deploy Workflow (`.github/workflows/deploy-aeria-editor.yml`)
- ✅ Well-structured: checkout → Node → pnpm → build → deploy vercel → deploy coolify
- ✅ Monorepo-aware: `pnpm --filter @openarcade/aeria-editor build`
- ❌ Guarded by: `if: ${{ secrets.VERCEL_TOKEN != '' }}` — never runs
- Requires: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `COOLIFY_WEBHOOK`

### Prior Job History (12+ jobs, all blocked on same issue)
| Job | Focus | Status | Key Finding |
|-----|-------|--------|------------|
| JOB-fe4197e0 | Storefront setup | ✅ Code | Added scripts + infra |
| JOB-4693d58c | Storefront deploy | ❌ Blocked | First INCOMPLETE_GOAL |
| JOB-926262d6 | Storefront investigate | ❌ Blocked | Auth code GNDN-SCRD |
| JOB-e4ea8b4f | Storefront setup | ❌ Blocked | Auth BPJF-CBGP, TKBK-FSFX |
| JOB-e0b7a645 | Lint + infra | ✅ Code | Fixed lint, deploy scripts |
| JOB-d2cd8ca9 | Storefront | ❌ Blocked | Auth NKWX-TGHL |
| JOB-6bea7bd5 | Storefront | ❌ Blocked | Auth DNPC-KHLW |
| JOB-6abfc6a4 | **Aeria-editor** | ❌ Blocked | SSO + rotated token |
| JOB-78153e32 | **Aeria-editor** | ❌ Blocked | SSO detailed |
| JOB-f558abad | **Aeria-editor** | ❌ Blocked | Same blocker |
| JOB-d1b669f9 | **Aeria-editor** | ❌ Blocked | Same blocker |
| JOB-b38caf75 | Developer-portal | ❌ Blocked | SSO partially shifted? |
| JOB-dcf096fd | API | ❌ Blocked | SSO, token, build logs |

---

## ⏳ EXECUTION PLAN

### Phase 1: Investigate ✅ DONE
- [x] Cloned both repos (storefront + openarcade monorepo)
- [x] Read all existing BRIEF.md, AGENTS.md, CLAUDE.md, session journals (12+ prior)
- [x] Verified aeria-editor build: `pnpm --filter @openarcade/aeria-editor build` → PASS (81ms)
- [x] Verified live site: openarcade-aeria-editor.vercel.app → HTTP 200
- [x] Confirmed GitHub secrets: 0 on both repos (API verified)
- [x] Generated fresh Vercel device auth codes (VQDB-CBFW + HQBT-CBWN)
- [x] Confirmed no VERCEL_TOKEN in env, filesystem, or Vercel CLI config

### Phase 2: Get VERCEL_TOKEN 🔴 **BLOCKING — needs human**
Two active device auth codes (same OAuth window, either works):
1. **VQDB-CBFW** → https://vercel.com/oauth/device?user_code=VQDB-CBFW (curl API)
2. **HQBT-CBWN** → https://vercel.com/oauth/device?user_code=HQBT-CBWN (Vercel CLI)

10+ prior codes all expired unused. **Someone must visit the URL.**

When authorized:
- Token saved to `~/.vercel/auth.json`
- Then run `scripts/setup-vercel-deploy.sh` with GITHUB_TOKEN in env

### Phase 3: Query Vercel API (requires VERCEL_TOKEN)
```bash
# Get project info
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/projects/openarcade-aeria-editor"

# Get team/org info
curl -s -H "Authorization: Bearer $VERCEL_TOKEN" \
  "https://api.vercel.com/v9/teams"
```

### Phase 4: Set GitHub Secrets (requires VERCEL_TOKEN + GITHUB_TOKEN)
Run `scripts/setup-vercel-deploy.sh` or manually:
```bash
# Install libsodium first
npm install libsodium-wrappers
# Then run the script
GITHUB_TOKEN=ghp_... VTOKEN=... VORGID=... VPROJID=... node setup-vercel-deploy.sh
```

Secrets to set on **both** repos:
- `VERCEL_TOKEN` = from Phase 2
- `VERCEL_ORG_ID` = from Phase 3
- `VERCEL_PROJECT_ID` = from Phase 3
- `COOLIFY_WEBHOOK` = from Coolify (Phase 7)

### Phase 5: Disable Vercel SSO (requires VERCEL_TOKEN + org admin)
```bash
curl -s -X PATCH -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v9/projects/openarcade-aeria-editor" \
  -d '{"ssoProtection": null}'
```

### Phase 6: Deploy to Vercel
```bash
cd /workspace/openarcade-monorepo
npx vercel deploy --prod --token=$VERCEL_TOKEN --cwd apps/aeria-editor
```

Or push to master → GitHub Actions workflow triggers.

### Phase 7: Coolify Dual Deploy (needs Coolify credentials)
- Access AURORA Coolify dashboard (5.9.153.215:8000 or Coolify URL)
- Create project with Dockerfile from `apps/aeria-editor/Dockerfile`
- Build arg: `VITE_OPENARCADE_API_URL=https://api.openarcade.com`
- Set secret `COOLIFY_WEBHOOK` on GitHub
- Test failover: take down Vercel, verify Coolify serves

### Phase 8: Set Production Env Vars on Vercel Dashboard
- `VITE_OPENARCADE_API_URL` = production API URL
  - Also set on Coolify as build arg

---

## Complete Unblock Action (When Someone Visits the Auth URL)

```bash
# 1. When token saved, extract it
VERCEL_TOKEN=$(cat ~/.vercel/auth.json | node -e "process.stdin.resume();let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).token)}catch(e){}})")

# 2. Run the setup script
cd /workspace
GITHUB_TOKEN=$GITHUB_TOKEN VTOKEN=$VERCEL_TOKEN bash scripts/poll-vercel-auth.sh

# 3. After secrets are set, push to master to deploy
cd /workspace/openarcade-monorepo
git push origin master
```

---

## Scripts Available

| Script | Location | Purpose | Status |
|--------|----------|---------|--------|
| `scripts/setup-vercel.sh` | `/workspace/scripts/` | Vercel full setup (auth → link → deploy) | ✅ Ready |
| `scripts/setup-vercel-deploy.sh` | `/workspace/scripts/` | Query API → set secrets → deploy | ✅ Ready |
| `scripts/setup-gh-secrets.sh` | `/workspace/scripts/` | GitHub secrets via API + libsodium | ✅ Ready (needs libsodium) |
| `scripts/deploy.sh` | `/workspace/scripts/` | Master deploy script | ✅ Ready |
| `scripts/poll-vercel-auth.sh` | `/workspace/scripts/` | Poll device auth for completion | ✅ Ready |

---

## GATE7 CHECKLIST

| Item | Status | Notes |
|------|--------|-------|
| Build exits 0 | ✅ PASS | Verified: aeria-editor builds in 81ms |
| Tests 95%+ | ⏳ N/A | No test files in aeria-editor |
| Lint zero errors | ⏳ N/A | No lint script in aeria-editor (monorepo has it) |
| Security scan clean | ⏳ Not run | |
| Secret scan clean | ⏳ Not run | |
| App boots | ✅ PASS | openarcade-aeria-editor.vercel.app HTTP 200 |
| Auth works | ⏳ N/A | Uses OpenArcade API auth externally |
| No TODO in src/ | ✅ PASS | Clean source |

---

## Blockers

**BLOCKER #1 — 🔴 MUST VISIT URL (human action required)**
Get a VERCEL_TOKEN by visiting:
- **https://vercel.com/oauth/device?user_code=VQDB-CBFW**
- Or **https://vercel.com/oauth/device?user_code=HQBT-CBWN**

This is the SAME blocker that stopped ALL 12+ prior jobs. Codes generated but never used. The token is needed for:
1. Querying Vercel API for ORG_ID and PROJECT_ID
2. Disabling Vercel SSO deployment protection
3. Setting GitHub Actions secrets
4. Triggering deployments

**BLOCKER #2 — Vercel SSO on coda-projects team**
Even with a valid VERCEL_TOKEN, SSO deployment protection on coda-projects blocks new deploys. Prior deployment survives because it predates SSO. Must disable SSO via PATCH API or Vercel dashboard.

**BLOCKER #3 — Coolify/Hetzner credentials not available**
No Coolify URL, API key, or SSH access to AURORA (5.9.153.215). Dual deploy cannot proceed until these are configured.

**BLOCKER #4 — No SSH access to HERMES / Mailcow**
Domain email for aeria-editor cannot be configured. LAUNCH_READY requires email inbound/outbound + legal pages.

---

## Handoffs
None yet. First aeria-editor-focused investigation in this workspace.

## SPAWN_JOBS
None.

## BUDGET_REQUEST
Not needed. All investigation work is done. Only VERCEL_TOKEN is needed — that requires human action, not more budget.
