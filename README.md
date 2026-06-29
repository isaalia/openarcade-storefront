# OpenArcade

**Indie games, your way.** A digital game distribution platform for independent developers.

Built with [Next.js 16](https://nextjs.org), [Tailwind CSS v4](https://tailwindcss.com), and [TypeScript](https://www.typescriptlang.org/).

## Projects

| Project | URL | Repo | Deployed |
|---------|-----|------|----------|
| **Storefront** — Browse and discover indie games | [openarcade-storefront.vercel.app](https://openarcade-storefront.vercel.app) | [isaalia/openarcade-storefront](https://github.com/isaalia/openarcade-storefront) | ✅ Vercel + Coolify |
| **Developer Portal** — Publish and manage games | [openarcade-developer-portal.vercel.app](https://openarcade-developer-portal.vercel.app) | [isaalia/openarcade-developer-portal](https://github.com/isaalia/openarcade-developer-portal) | ⚡ Vercel + Coolify |

## Storefront Features

- Browse and discover indie games
- Game library and wallet management
- Dark theme with amber/teal accent colors
- Responsive design (mobile-first)
- Server-side rendered for performance

## Storefront Pages

- `/` — Home with hero section and game discovery
- `/explore` — Browse and discover games
- `/store` — Game storefront
- `/library` — User game library
- `/wallet` — Balance and transactions
- `/profile` — Account settings
- `/search` — Search games

## Developer Portal Pages

- `/` — Sign-in / Register page for game publishers

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Styling | Tailwind CSS v4 |
| Fonts | Syne (display), DM Sans (body) |
| Language | TypeScript |
| Deployment | Vercel + Coolify/Hetzner (dual) |

## Getting Started (Storefront)

```bash
cd storefront  # or repo root
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Getting Started (Developer Portal)

```bash
cd portal
npm install
npm run dev
```

Open [http://localhost:3001](http://localhost:3001).

## Build

```bash
# Storefront (from repo root)
npm run build

# Developer Portal (from portal/)
cd portal && npm run build
```

## Dual Deployment

Each app is deployed to **two** targets for resilience:

1. **Vercel** (primary) — Edge-deployed, zero-config Next.js
2. **Coolify / Hetzner** (secondary) — Docker-based self-hosted

### Setting Up CI/CD

1. Generate a Vercel token:
   ```bash
   ./scripts/poll-vercel-auth.sh
   ```
   (Requires human to authorize via browser)

2. Set GitHub secrets:
   ```bash
   export VERCEL_TOKEN="<from step 1>"
   export VERCEL_ORG_ID="<your-org-id>"
   export VERCEL_PROJECT_ID="<your-project-id>"
   ./scripts/setup-gh-secrets.sh
   ```

3. Push to `main` → GitHub Actions deploys to both Vercel and Coolify.

### Manual Deploy

```bash
# Vercel
vercel deploy --prod --token=$VERCEL_TOKEN --yes

# Coolify
docker build -t openarcade-storefront .
# Configure in Coolify dashboard
```

## CI/CD Workflows

Each repo has three workflows:

| Workflow | File | Trigger | Requires Secrets |
|----------|------|---------|------------------|
| Deploy to Vercel | `.github/workflows/deploy-vercel.yml` | Push to main | `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` |
| Deploy to Coolify | `.github/workflows/deploy-coolify.yml` | Push to main | `COOLIFY_DEPLOY_URL` |
| CI | `.github/workflows/ci.yml` | PR + push to main | None |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/poll-vercel-auth.sh` | Generate device auth code and poll for VERCEL_TOKEN |
| `scripts/setup-gh-secrets.sh` | Set GitHub Actions secrets for both repos |
| `scripts/deploy.sh` | Master deploy script (vercel/coolify/all/setup-secrets) |

## License

BSL — See [LICENSE](./LICENSE) file.
