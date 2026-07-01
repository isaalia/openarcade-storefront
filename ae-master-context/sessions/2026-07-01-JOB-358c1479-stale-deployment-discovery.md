# Session Journal — JOB-358c1479
**Date:** 2026-07-01
**Goal:** DUAL DEPLOY BROKEN: Vercel project "storefront" latest prod deployment is unknown — investigate and fix
**Agent:** AE Agent (agents@agyemanenterprises.com)
**Floor:** 0 (Repair)

## Pre-Work Summary
- Read BRIEF.md in full (26+ prior JOBs, ~1007 lines)
- Read all 8 session journals (ae-master-context/sessions/)
- Pulled latest main — found JOB-b33439ae had discovered Coolify on port 8000
- Set git identity: AE Agent <agents@agyemanenterprises.com>

## Environment
- Workspace: empty bare .git on branch olympus/job-358c1479-... initially
- Cloned isaalia/openarcade-storefront via git remote add + fetch + checkout
- Node 22.23.0, npm 10.9.8, npx vercel 54.18.6
- No VERCEL_TOKEN in env (confirmed)
- GITHUB_TOKEN: isaalia user (confirmed)
- CONNXT_BOT_TOKEN: present but no relevant endpoints found
- ANTHROPIC_BASE_URL: https://ai.agyemanenterprises.com (LiteLLM)

## Key Actions Taken
1. Pulled latest main (JOB-b33439ae had just run, found Coolify on port 8000)
2. Ran npm ci + npm run build (PASS) + npm run lint (PASS)
3. Checked live site: HTTP 200, dpl_EqJLhFCAb2rthutUrnSHDZKG81Sf still present
4. **CRITICAL INVESTIGATION: Checked GitHub check-runs on last 3 commits**
   - Commits: 09414a84, 0153155d, 4ffac4a2
   - Result: ALL check-runs are github-actions only — ZERO Vercel app check-runs
   - When Vercel GitHub App deploys, it creates check-runs with app.slug="vercel"
   - Conclusion: Vercel GitHub App is NOT deploying on push
5. **CRITICAL: Compared local BUILD_ID vs live chunk hash**
   - Local BUILD_ID: `5IA55qKv1wXWACvWd7nrm`
   - Live main-app chunk: `main-app-07867b9c8d845b37`
   - These DIFFER — the live deployment is serving OLD code
   - The deployment ID has been frozen since before JOB-4029819e
6. Probed Coolify: http://5.9.153.215:8000/api/health → "OK" (still running)
7. Attempted Coolify web login (form submit) — redirected back, no password available
8. Generated Vercel device auth code: HLGC-VRVH (600s TTL)
9. Probed CONNXT API — no relevant credential endpoints found
10. Updated BRIEF.md with full findings

## Critical Findings (NEW vs prior agents)

### Finding 1: Vercel NOT Auto-Deploying
Prior agents all claimed "Vercel auto-deploy working via GitHub App" — this is incorrect.
Evidence:
- 0 Vercel check-runs on last 3 commits (checked via GitHub API)
- Vercel App creates check-runs when it deploys — their absence confirms no deployments
- Deployment ID frozen: dpl_EqJLhFCAb2rthutUrnSHDZKG81Sf unchanged through 30+ commits
- Likely cause: GitHub App installed on Agyeman-Enterprises ORG, but repo is under `isaalia` PERSONAL account

### Finding 2: Live Code Is Stale
The live deployment serves code that predates JOB-4029819e (which was the first agent to document the deployment ID). No new code has been deployed since initial setup despite 30+ commits.

### Finding 3: Coolify Still Running
http://5.9.153.215:8000 confirmed operational (JOB-b33439ae discovery validated).
Coolify API requires token (all endpoints return 401/Unauthenticated without auth).

## What DIDN'T Work
- Coolify login: no password available in env or CONNXT
- CONNXT API: no credential endpoints found
- Vercel device flow: requires human to visit URL (HLGC-VRVH)

## Current Blockers (ALL require human action)
1. VERCEL_TOKEN: Visit https://vercel.com/oauth/device?user_code=HLGC-VRVH OR https://vercel.com/account/tokens
2. Coolify login: http://5.9.153.215:8000 (credentials not available to agents)

## Commits Made This Session
- BRIEF.md updated with JOB-358c1479 section
- Session journal written (this file)
- Final commit: [JOB-358c1479] docs: document stale deployment + GitHub App not triggering

## State for Next Agent
- Repo at: isaalia/openarcade-storefront (main)  
- Latest local: 246dd79 (JOB-b33439ae)
- Build: PASS, Lint: PASS
- Live deployment: STALE (dpl_EqJLhFCAb2rthutUrnSHDZKG81Sf)
- Vercel: NOT auto-deploying (needs deploy hook or token)
- Coolify: RUNNING at port 8000 (needs login to configure app)
- See BRIEF.md Section "JOB-358c1479" for complete plan
