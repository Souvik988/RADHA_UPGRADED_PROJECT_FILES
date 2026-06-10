# RADHA — Status Report + Production-Readiness Plan

**As of 2026-06-09.** Self-contained brief to take the app from "feature-complete + green" to
**fully production-ready, Zepto-smooth, zero-bug.** Trust the filesystem + `flutter analyze`/
`flutter test` + `pnpm test` over any older status doc.

> Env: Flutter `C:\src\flutter\bin\flutter.bat` (3.44, Dart 3.12) · Dart `C:\src\flutter\bin\dart.bat`
> · Windows/PowerShell · Docker up: `radha-postgres` (5433), `radha-redis` (6380), db `radha_dev`/`radha`.
> Mobile root: `apps/mobile`. Server root: `server`. `Remove-Item`/`rm`/`python` flaky in tools → use
> PowerShell `[System.IO.File]::Delete()`.

---

## 1. WHERE THE APP IS RIGHT NOW (snapshot)

A mobile-first retail+consumer health app (Flutter) on a feature-complete NestJS backend. The flagship
**browse-without-scan** flow (Home → category grid → rich freemium product detail), plus scan/OCR,
expiry, tasks, inventory, GRN, reports, subscriptions, allergens, recalls, weekly digest — all built.
Everything compiles and the test suites are **fully green**. What's left is data population, AWS
deployment, device QA, and launch hardening — **not** ground-up building.

**Verified green (run these to confirm):**
- Mobile: `cd apps/mobile && flutter analyze lib` → clean · `flutter test` → **186/186**
- Backend: `cd server && pnpm test` → **2059/2059 (213 suites)** · `pnpm build` → clean · `pnpm exec eslint src` → clean
- Release APK builds: arm64 **~46 MB** / armv7 ~39 MB (was 130 MB before the asset diet)

---

## 2. WHAT'S DONE (and verified)

### Mobile (Flutter)
- **Browse catalog (flagship):** `lib/features/catalog/` — offline-first launch catalog (29 curated
  branded products bundled as WebP), premium grid (health pill, veg dot, sort, infinite scroll),
  consumer-home **Featured/Healthy-Picks rail** + **product search**, and a **rich freemium product
  detail** (real health gauge w/ Mor, real nutrition like/concern + Per-100g/50g sheet, Plus-gated
  ingredient deep-dive + For-You allergen flags, honest "scan to unlock"). Wired to the real
  `/catalog` API + `/products/lookup`.
- **Premium assets integrated** (your 27 generated): splash hero, scan-success celebration, app-wide
  error illustrations, illustrated health badges on detail, search/empty states, 3 home banners,
  paywall hero, onboarding hero — all behind `lib/design/widgets/brand_illustration.dart` (~0.94 MB total).
- **Launcher icon + native splash** fixed to brand orange (regenerated).
- **APK diet** done (130 → ~46 MB); native floor is ML Kit OCR + barcode + engine (legit).
- Existing surfaces (scan/OCR layered fallback, expiry+OCR, tasks, inventory, GRN, reports→Excel/PDF,
  subscriptions+Razorpay, allergen profile, recalls, weekly digest) — built + paginated + state-complete.

### Backend (NestJS) — feature-complete, **all tests green**
- Consumer catalog API (`/catalog/categories`, `/catalog/products`), product lookup (`/products/lookup/:ean`).
- Curated OFF importer (`importCurated` — resolves REAL EANs by OFF text-search, never guesses) +
  bulk OFF importer. CLIs fixed to run under `ts-node` (tsx can't emit Nest DI metadata).
- 2Factor SMS/OTP, Razorpay payments (test keys), Gemini AI label analysis, S3/CloudFront integration.
- Fixed this session: 3 stale/broken specs (onboarding guard, db eager-pool, bullmq logger graph).

### Deployment package (BUILT, HELD per your call)
- `Dockerfile`, `.dockerignore`, `docker-compose.prod.yml` (api/worker/scheduler → managed RDS/ElastiCache;
  compose config validated), `deploy/nginx/radha-api.conf` (TLS), `server/.env.production.example`,
  `server/tsconfig.runtime.json` (`@/` alias at runtime), **`DEPLOY_AWS.md`** (full runbook).
  EC2: `ssh -i Radha.pem ubuntu@ec2-18-60-109-5.ap-south-2…`. **Image not Docker-built/validated yet.**

---

## 3. WHAT'S REMAINING (the honest gap list)

| # | Area | Status | Notes |
|---|---|---|---|
| R1 | **Catalog data** | partial | OFF seed ran here but only 2/29 (sandbox throttled OFF). Run on a networked box for the full set. Browse/detail are real-data-ready. |
| R2 | **AWS deploy** | not executed | Package ready; needs RDS+ElastiCache+S3+CloudFront provisioned + first Docker build validated on EC2 (watch the `@/` alias — see DEPLOY_AWS §11). |
| R3 | **Prod secrets/signing** | not done | Real JWT(≥64), AWS keys, Razorpay LIVE + webhook secret, 2Factor real key, `DB_SSL=true`; **release signing config** (app currently uses DEBUG keys). |
| R4 | **On-device QA** | not done | OTP login, Razorpay live sheet, scan→result, browse→detail — need server running + a real device. |
| R5 | **Perf pass ("Zepto-smooth")** | not profiled | 60fps + <1.5s cold start budgets exist in code (skeletons, cached images, haptics, RepaintBoundary) but not profiled on-device; add image prefetch on home/browse. |
| R6 | **l10n** | English-only (new) | 6 ARB locales exist; new catalog/asset strings not translated. |
| R7 | **Asset mop-up** | ~3 of 27 | offline-state illo, 2 badges (additive/allergen), onboarding later pages. All bundled — 1-line swaps. |
| R8 | **Legal + store prep** | not done | Privacy Policy + Terms (store requirement), store listings, screenshots, app icons per store. |
| R9 | **Web surfaces** | not started | Marketing site (`apps/marketing-web`) + Owner Dashboard (`apps/owner-dashboard`). Big, separate from the app. |
| R10 | **Infra hardening** | not done | RDS automated backups + restore drill, Sentry DSN live, alerting, rate-limit verify. |

---

## 4. PRODUCTION-READINESS PLAN (do in this order)

### 🔴 P0 — make it a real, usable production app (blockers)
1. **Provision AWS** (RDS Postgres + ElastiCache Redis + S3 `radha-prod-media` + CloudFront + Elastic IP +
   domain `api.<you>`). Security groups: DB/Redis open only to the EC2 SG; EC2 opens 22/80/443 (not 3000). → `DEPLOY_AWS.md §2`.
2. **Fill `server/.env.production`** from `.env.production.example` with real endpoints + secrets (gen JWT
   with `openssl rand -hex 48`; copy Gemini/allergen keys from `.env.development`).
3. **Build + run on EC2:** `docker compose -f docker-compose.prod.yml --env-file server/.env.production up -d --build`.
   ⚠️ **Validate the first build** — if a container crashes on `Cannot find module '@/...'`, apply the
   `tsc-alias` fix in `DEPLOY_AWS.md §11`.
4. **Migrate + seed** (in-container): `pnpm db:migrate` → `pnpm db:import:curated` (resolves real EANs +
   nutrition; needs OFF internet) → locally `dart run apps/mobile/tool/apply_resolved_eans.dart`.
5. **nginx + Let's Encrypt TLS** for the domain (`DEPLOY_AWS.md §7`).
6. **Point the app at prod:** set API base URL (`apps/mobile/lib/core/network/dio_provider.dart` or
   `--dart-define=API_BASE_URL=`) to `https://api.<you>/`.
7. **Release signing:** create an upload keystore, wire `signingConfigs.release` in
   `android/app/build.gradle.kts` (currently DEBUG keys), build a signed AAB.
8. **On-device smoke (R4):** OTP login → home → browse a category → open a seeded product (real nutrition)
   → scan a barcode → Razorpay test→live sheet.

### 🟠 P1 — Zepto-smooth + bug-free polish
9. **Device perf profile** (`flutter run --profile`, DevTools): confirm 60fps on browse/detail scroll,
   cold start <1.5s; fix any jank. Add **image prefetch** (`precacheImage`) for the first home/browse rows.
10. **S3/CloudFront images:** `pnpm db:host:images` (after seed) → product images on CDN; bundled assets
    stay the offline fallback.
11. **Finish asset mop-up (R7)** + **l10n** the new strings across the 6 ARB locales (don't hand-fake
    translations — use a proper translation pass).
12. **Final state/error QA sweep:** every screen's loading/empty/error/offline state on a flaky network
    (the wiring exists; verify on device). Wire the **offline** illustration to the connectivity banner.
13. **Sentry** DSN live + verify errors report; verify rate limits on auth/OTP/upload routes.

### 🟡 P2 — launch readiness
14. **Legal:** publish Privacy Policy + Terms; link in Settings (already has the rows).
15. **Razorpay LIVE** keys + webhook (`https://api.<you>/api/v1/payments/webhook`) + webhook secret.
16. **RDS backups** (automated, 7–30d) + a **restore drill**; CloudWatch alarms on the EC2 + RDS.
17. **App store:** Play Console listing, screenshots (use the generated mockups in `assets/mockups/`),
    privacy declarations, signed AAB upload. iOS later (needs a Mac for signing/build).

### 🟢 P3 — separate surfaces (post-app-launch)
18. **Owner Dashboard** (`apps/owner-dashboard`, Next.js) — backend APIs (client-dashboard/reports/OHS)
    already exist; this is the highest-value web build.
19. **Marketing website** (`apps/marketing-web`, Next.js).

---

## 5. KEY FILES (for the next agent)
- Catalog: `apps/mobile/lib/features/catalog/{product_browse_screen,product_detail_screen,catalog_search_screen,
  featured_rail,catalog_health}.dart` + `data/launch_catalog.dart` (+ `data/resolved_eans.g.dart` overlay) +
  `providers/product_browse_providers.dart`.
- API client: `apps/mobile/lib/core/network/api_client.dart` (+ `dto/catalog_dto.dart`, `dto/product_lookup_dto.dart`).
- Assets: `apps/mobile/lib/design/app_assets.dart` (v3 constants) + `lib/design/widgets/brand_illustration.dart`;
  bundled under `apps/mobile/assets/v2/`.
- Backend catalog: `server/src/modules/products/{controllers,services,repositories}/consumer-catalog.*` +
  `services/product-lookup.service.ts`; seed `server/src/modules/catalog-import/` + `src/db/import-curated-catalog.ts`.
- Deploy: `Dockerfile`, `docker-compose.prod.yml`, `deploy/nginx/`, `server/.env.production.example`, **`DEPLOY_AWS.md`**.
- Other docs: `HANDOFF_BROWSE_CATALOG_2026-06-09.md`, `PRODUCTION_CHECKLIST.md` (generic), `CLAUDE.md` (agent guide).

## 6. VERIFY / GATES (run after any change)
```bash
cd apps/mobile && C:\src\flutter\bin\flutter.bat analyze lib && C:\src\flutter\bin\flutter.bat test
cd server && pnpm build && pnpm test && pnpm exec eslint src --max-warnings 0
```

## 7. GOTCHAS (will bite the next agent)
- **No git repo** here — destructive edits aren't recoverable; back up before bulk overwrites.
- **The IDE edits files in parallel** — re-read before editing; treat analyze/test as truth.
- **`dart format`** can split a braceless `if(...) return;` → trips `curly_braces` lint; add braces.
- **New backend files** often land CRLF/condensed → `pnpm exec eslint <path> --fix` (project is LF+Prettier).
- **Nest-context CLIs must use `ts-node -r tsconfig-paths/register`, NOT tsx** (tsx/esbuild drops decorator metadata).
- **No fabricated nutrition / no guessed EANs** — health-app integrity. Real-from-OFF or honest "scan to unlock".
- **RADHA brand mark = the 3 orange bars logomark, not a Latin "R"** (wordmark is राधा).
- **Scope guard:** RADHA is **not** POS/GST/billing in V1.

---
**Bottom line:** the app + backend are built, green, and premium. The path to launch is **P0 (deploy + seed +
sign + device-smoke) → P1 (perf + polish) → P2 (legal + store)**. P0 is the only thing between "great demo"
and "real users." Everything needed for P0 is in `DEPLOY_AWS.md`.
