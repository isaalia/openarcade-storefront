# OpenArcade Storefront

**Indie games, your way.** A digital storefront for independent game developers.

Built with [Next.js 16](https://nextjs.org), [Tailwind CSS v4](https://tailwindcss.com), and [TypeScript](https://www.typescriptlang.org/).

## Features

- Browse and discover indie games
- Game library and wallet management
- Dark theme with amber/teal accent colors
- Responsive design (mobile-first)
- Server-side rendered for performance

## Pages

- `/` — Home with hero section and game discovery
- `/explore` — Browse and discover games
- `/store` — Game storefront
- `/library` — User game library
- `/wallet` — Balance and transactions
- `/profile` — Account settings
- `/search` — Search games

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Styling | Tailwind CSS v4 |
| Fonts | Syne (display), DM Sans (body) |
| Language | TypeScript |

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build

```bash
npm run build
npm start
```

## Deployment

### Vercel (primary)

1. Push to GitHub repo
2. Import project in Vercel dashboard
3. Deploy — zero config required

### Coolify / Hetzner (secondary — dual deployment)

1. Push to GitHub repo
2. In Coolify, create a new project from the GitHub repo
3. Docker build: `docker build -t openarcade-storefront .`
4. Run: `docker run -p 3000:3000 openarcade-storefront`

### GitHub Actions

Two workflows are provided:

- `.github/workflows/deploy-vercel.yml` — Deploys to Vercel on push to `main`
  - Requires secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
- `.github/workflows/deploy-coolify.yml` — Triggers Coolify deployment on push to `main`
  - Requires secret: `COOLIFY_DEPLOY_URL`

## License

BSL — See [LICENSE](./LICENSE) file.
