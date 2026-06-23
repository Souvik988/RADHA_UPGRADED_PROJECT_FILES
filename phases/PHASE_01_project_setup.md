# PHASE 01 — Project setup

## Goal
Scaffold the RADHA Admin Dashboard as a Next.js (App Router) + TypeScript app with Tailwind
mapped to RADHA design tokens, shadcn/ui themed, brand fonts, base config, security headers
(CSP/HSTS), env handling, and the folder structure from Doc 2 §8.1 — leaving an app that builds
and runs with a placeholder home page.

## Depends on
None (first phase).

## Doc references
- Doc 2 §2 (brand tokens), §2.3 (typography), §8 (recommended stack), §8.1 (route tree).
- Doc 3 §B.4 (no secrets in bundle), §B.6 (CSP + security headers), §B.10 (supply chain / pinned deps).
- Doc 1 §2.4 (API conventions, base path `/api/v1`).

## Scope (in)
Create the project at repo root in `radha_dashboard/`:
- `package.json` — pinned deps: `next`, `react`, `react-dom`, `typescript`, `tailwindcss`,
  `postcss`, `autoprefixer`, `@tanstack/react-query`, `react-hook-form`, `zod`,
  `@hookform/resolvers`, `recharts`, `clsx`, `tailwind-merge`, `lucide-react` (placeholder until
  custom glyphs land), `class-variance-authority`. Scripts: `dev`, `build`, `start`, `lint`,
  `typecheck`.
- `tsconfig.json` — strict mode, `@/*` path alias → `./`.
- `next.config.mjs` — `async headers()` with CSP/HSTS/nosniff/frame-deny/referrer-policy
  (Doc 3 §B.6); `reactStrictMode: true`; image `remotePatterns` for S3/CloudFront.
- `postcss.config.mjs`, `tailwind.config.ts` — token-driven theme extension reading CSS vars.
- `app/globals.css` — import `lib/design/tokens.css`; base canvas, font wiring, paper-grain layer.
- `lib/design/tokens.css` — all Doc 2 §2 tokens as CSS custom properties (light + dark blocks).
- `app/layout.tsx` — root layout: html lang, fonts (Plus Jakarta Sans + JetBrains Mono via
  `next/font/google`), `<body>` with canvas bg, metadata.
- `app/page.tsx` — minimal placeholder ("RADHA Admin Dashboard — Phase 01 ✓") proving tokens load.
- `lib/utils.ts` — `cn()` (clsx + tailwind-merge).
- `.env.example` — `NEXT_PUBLIC_API_BASE_URL=http://localhost:3000/api/v1`, `SESSION_COOKIE_NAME`,
  `NEXT_PUBLIC_SENTRY_DSN` (optional). `.env.local` is git-ignored.
- `.gitignore`, `.eslintrc` / `eslint.config.mjs`, `.prettierrc` (single quotes, trailing commas,
  semicolons, print width 100, tab width 2, arrow parens always, LF — mirror backend style).
- `components.json` — shadcn/ui config themed to RADHA (base color neutral, CSS vars on).
- Folder skeletons (empty `index.ts`/`.gitkeep` as needed): `lib/api/`, `lib/auth/`, `lib/hooks/`,
  `lib/charts/`, `components/ui/`, `features/`.

## Out of scope
No real components, no auth, no API client, no screens. Just the runnable shell + tokens + headers.

## Step-by-step
1. From repo root, scaffold: `npx create-next-app@latest radha_dashboard --ts --app --tailwind
   --eslint --src-dir=false --import-alias "@/*" --no-turbopack` (accept App Router). If
   interactive prompts block automation, create files manually per Scope. **Do not run dev/watch
   servers from the agent** — the user runs `npm run dev` themselves.
2. Pin dependency versions in `package.json` (no `^`/`~` on security-relevant libs); commit the
   lockfile. Add `typecheck`: `tsc --noEmit`.
3. Add brand fonts in `app/layout.tsx`:
   ```tsx
   import { Plus_Jakarta_Sans, JetBrains_Mono } from 'next/font/google';
   const sans = Plus_Jakarta_Sans({ subsets: ['latin'], variable: '--font-sans', weight: ['400','500','600','700','800'] });
   const mono = JetBrains_Mono({ subsets: ['latin'], variable: '--font-mono', weight: ['400','500','600','700'] });
   // <html className={`${sans.variable} ${mono.variable}`}>
   ```
4. Author `lib/design/tokens.css` with every Doc 2 §2 token under `:root` and a `.dark`/
   `[data-theme="dark"]` block (§2.2 values). Numbers/money default to `font-family: var(--font-mono)`
   via a `.mono`/`.tabular` utility.
   ```css
   :root {
     --accent:#EA580C; --accent-deep:#9A3412; --accent-tint:#FED7AA;
     --ink:#1C1917; --ink-soft:#57534E; --surface:#FFFBF5; --surface-raised:#FFFFFF;
     --surface-sunken:#F5F1E8; --hairline:#E7E1D4; --success:#15803D; --warn:#B45309;
     --danger:#B91C1C; --teal:#0F766E;
     --radius-sm:8px; --radius-md:12px; --radius-lg:16px; --radius-xl:24px;
     --shadow-card:0 2px 8px rgba(28,25,23,.06);
   }
   [data-theme="dark"]{ --surface:#1A1714; --surface-raised:#221E1A; --ink:#F5F1E8;
     --hairline:#3A332B; --accent:#F26419; }
   ```
5. Map tokens in `tailwind.config.ts` (`theme.extend.colors.accent = 'var(--accent)'`, etc.),
   radii, boxShadow, fontFamily `sans`/`mono`.
6. Add the paper-grain canvas in `app/globals.css` (≤3% noise via an inline SVG/data-URI bg layer
   applied once at body level — never per card).
7. Configure `next.config.mjs` security headers (see API wiring/Security below).
8. Initialize shadcn/ui: `npx shadcn@latest init` → choose CSS variables, neutral base; then theme
   its `globals` vars to RADHA tokens. Do **not** add components yet (Phase 02).
9. Create empty folder skeletons per Doc 2 §8.1.
10. Verify per Verification section.

## API wiring
None in this phase. Only set the base-url env contract:
- `NEXT_PUBLIC_API_BASE_URL` = `http://localhost:3000/api/v1` (Doc 1 §2.4). This is **public** and
  safe in the bundle; no secrets/keys client-side (Doc 3 §B.4).

## Design spec
- Canvas `--surface #FFFBF5` with faint paper grain; text `--ink`; fonts wired (sans body, mono
  numbers). Placeholder page uses an eyebrow label + `w800` title to prove the type scale.
- Tokens-only: no hard-coded hex in components; everything reads CSS vars (Doc 2 §2, §9).
- No purple/blue gradients, neon, glass, pure black, emoji icons (Doc 2 §9).

## Security checks
- **Headers (Doc 3 §B.6)** in `next.config.mjs`:
  ```js
  const csp = [
    "default-src 'self'",
    "connect-src 'self' http://localhost:3000 https://*.amazonaws.com https://*.cloudfront.net",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https://*.amazonaws.com https://*.cloudfront.net",
    "font-src 'self' data:",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join('; ');
  // headers(): CSP, Strict-Transport-Security (max-age=63072000; includeSubDomains; preload),
  // X-Content-Type-Options: nosniff, X-Frame-Options: DENY,
  // Referrer-Policy: strict-origin-when-cross-origin,
  // Permissions-Policy: camera=(), microphone=(), geolocation=()
  ```
  (Tighten `connect-src` to the prod API origin via env at deploy.)
- No secrets in repo or client env; only `NEXT_PUBLIC_*` is public (§B.4). `.env.local` git-ignored.
- Pinned deps + committed lockfile; plan `npm audit` in CI (§B.10).

## Acceptance criteria
- [ ] `radha_dashboard/` exists with the Doc 2 §8.1 folder skeleton.
- [ ] `npm run build` and `npm run typecheck` succeed with zero errors.
- [ ] Home page renders on the warm cream canvas with Plus Jakarta Sans + a mono number sample.
- [ ] `lib/design/tokens.css` defines all Doc 2 §2 tokens (light + dark) and Tailwind reads them.
- [ ] Response headers include CSP, HSTS, nosniff, frame-deny, referrer-policy (verify in browser/`curl -I`).
- [ ] No secrets committed; `.env.example` present, `.env.local` ignored; lockfile committed.
- [ ] No token violations (no raw hex, no banned styles) in authored files.

## Verification
- `cd radha_dashboard && npm install`
- `npm run typecheck` → no errors.
- `npm run lint` → zero warnings.
- `npm run build` → success.
- User runs `npm run dev` manually; open `/`, confirm canvas color, fonts, and (DevTools →
  Network → document → Response Headers) the security headers.

## Rollback note
The whole phase is additive inside the new `radha_dashboard/` folder. To revert, delete
`radha_dashboard/`. No existing repo files (`radha_app/`, `radha_backend/`, docs) are touched.
