# CLAUDE.md — RADHA Platform

> Canonical agent guide for the RADHA monorepo. Converted from the project's `.kiro/`
> steering + hooks + specs on **2026-06-03**. This is the single source of truth for how
> Claude Code should work in this repo. (A short router copy lives at the parent
> working-dir root; this file is the full version.)

---

## 1. What RADHA Is

**RADHA = Retail Assistant for Data, Health & Audits** — a mobile-first retail audit
platform for Indian retail teams. It is **not** a GST billing, POS, accounting, or full
ERP product.

Core capabilities: barcode/EAN scanning + product lookup (Open Food Facts fallback),
rule-based health indicators, expiry tracking (MFG/EXP, OCR assist, green/yellow/red),
approved-EAN verification via Excel/CSV, bulk audit scan sessions, manager→staff task
assignment, Excel/PDF reports + dashboards, lightweight inventory + GRN, subscriptions
(3-month trial; ₹49 / ₹99 / ₹199), and a free-first layered AI/OCR system (Google ML Kit
on-device → rule-based → optional LLM → AWS Rekognition only as a paid escalation).

**Surfaces:** RADHA Mobile App (Flutter) · Marketing Website (Next.js) · Owner Dashboard
(private Next.js, RADHA business owner only) · Backend API + Worker + Scheduler (NestJS).

**Out of scope (V1):** GST invoicing, POS cart, payment collection, sales ledger, full
accounting. Designed for ~10,000 users (RDS indexing, cursor pagination, background
workers, S3 direct upload, async reports, tenant/store scoping).

---

## 2. Where Things Live (read this first)

- **The real project root is this folder** (`RADHA_UPGRADED_PROJECT_FILES/`). Run all
  `pnpm` / build commands here. The parent folder (`…/RADHA_UPGRADED_PROJECT_FILES new/`)
  is just a wrapper that Claude Code opens as the CWD.
- The root `*.md` files are the **source of truth** — read the relevant ones before
  changing related code (see the doc index in §8).
- `.kiro/` holds steering, specs, agent hooks, and a large curated skill set (see §9).

---

## 3. Tech Stack

**Monorepo:** pnpm 8.15.0 workspaces (`npm`/`yarn` not used), Node >=18.17.0, TypeScript
5.3 (server + packages), Dart/Flutter for mobile. Workspaces: `server` and `packages/*`;
`apps/*` (mobile + web) live alongside.

**Backend (`server/`):** NestJS 10 modular monolith. Three entry points:
`main.api.ts` (REST), `main.worker.ts` (queues/imports/OCR/reports),
`main.scheduler.ts` (cron/reminders/rollups). Drizzle ORM + `postgres` driver on
PostgreSQL (RDS in prod), migrations via `drizzle-kit`. Validation: `class-validator` +
`class-transformer` (DTOs), `zod` (env/contracts). Auth: `@nestjs/jwt`, `bcrypt`, OTP via
MSG91. Logging: `nestjs-pino` + `pino-http` + `nestjs-cls` (PII redacted). Security:
`helmet`, `compression`, CORS, global validation pipes, request IDs, error envelope.
Storage: AWS S3 (`@aws-sdk/client-s3`, presigned URLs) + CloudFront. Queues: BullMQ +
Redis. Observability: Sentry + Terminus. Tests: Jest + supertest + ts-jest.

**Mobile (`apps/mobile/`):** Flutter 3.22+ / Dart 3.4. Riverpod 2.5 (+ generator),
GoRouter 14, Drift 2.18 (local DB), Dio 5 (+ interceptors: auth, retry, idempotency,
correlation IDs, offline queue), freezed + json_serializable, flex_color_scheme 7.3 +
Material 3, flutter_animate 4.5 + lottie 3, google_mlkit_barcode_scanning +
google_mlkit_text_recognition, firebase_messaging + flutter_local_notifications,
flutter_secure_storage, sentry_flutter, widgetbook, intl/ARB (6 locales: en, hi, ta, te,
bn, mr). Tests: `flutter_test` + `golden_toolkit` + `integration_test`.

**Web (`apps/marketing-web`, `apps/owner-dashboard`):** Next.js (App Router) — planned.

**Shared:** `@radha/shared-types` (`packages/shared-types/`) — isomorphic cross-package
types/contracts; no Node-only runtime code in it.

**Code style:** Prettier (single quotes, trailing commas all, printWidth 100, tabWidth 2,
semicolons, arrow parens always, LF). ESLint flat configs; server uses `--max-warnings 0`.
Server path alias `@/*` → `src/*`.

---

## 4. Engineering Guardrails (MUST follow)

These are the standing rules. They are the converted intent of the `.kiro` agent hooks —
treat them as always-on review criteria for every change you make.

**Backend layering (Controller → Service → Repository; calls only flow downward):**
- **Controllers are transport-only.** No business logic, no DB/SDK calls. Every route has
  a `class-validator` DTO (never raw `any`). JWT/role guards applied. Risky routes
  (auth, uploads, OTP) are rate-limited. Request/response shapes match
  `@radha/shared-types` and `API_CONTRACTS.md`.
- **Services own business logic + transactions.** Every state-changing write also writes
  an **audit log**. Multi-step operations run in a transaction. No direct Drizzle in
  services — all DB access goes through a repository. No third-party SDKs in services —
  all external calls go through `integrations/*`. Tenant context comes from `cls`/context,
  **never** from request bodies.
- **Repositories own queries.** Every query is **tenant/store scoped** (WHERE has
  `tenant_id`, and `store_id` where applicable). No unbounded SELECTs — use limit/cursor
  pagination. No N+1 loops. No `SELECT *`. Indexes lead with `tenant_id`.

**Integrations (`server/src/integrations/`):** every external provider (S3, MSG91, OFF,
Rekognition, OpenAI) sits behind a typed interface with retry/timeout + exponential
backoff, error mapping to domain errors, zod-validated env config, secret redaction in
logs, and a fake/mock for tests. No direct SDK usage may bypass the wrapper.

**Database / migrations:**
- New table → add a Drizzle schema in `server/src/db/schema/` (plural-noun filename), then
  a numbered SQL migration `NNN_short_description.sql` in `server/src/db/migrations/`.
- **Existing migrations are immutable history** — only add new monotonically-numbered
  files; never edit an applied migration.
- Keep the schema↔migration↔docs triangle in sync: tables need `tenant_id` (or a
  documented exception), `createdAt`/`updatedAt`/`deletedAt`, indexes leading with
  `tenant_id`, and an entry in `DATABASE_ARCHITECTURE.md`.

**Queues (BullMQ):** every consumer is idempotent (safe to replay), routes terminal
failures to a dead-letter queue, has explicit retry/backoff/timeout, and restores tenant
context from the job payload. Long jobs heartbeat/chunk.

**Secrets & PII:** no hardcoded secrets (scan for `AKIA`, `ASIA`, `AIza`, `MSG91`,
`sk_live_`, bearer/JWT, private keys). Never log PII (phone, email, OTP, tokens,
addresses). All env flows through the typed config + zod schema; the Pino redact list
covers every PII path.

**DTO ↔ shared-types parity:** DTO shapes used across BE/FE belong in
`@radha/shared-types`; keep DTOs and shared types in agreement with `API_CONTRACTS.md`.

**Mobile:** no generic Material defaults — every screen has tuned entry/exit curves,
durations, stagger, and haptics (use the motion + haptics vocabularies in
`FRONTEND_PHASES/00_MASTER_FRONTEND_ROADMAP.md`). Every screen has designed
empty/error/loading states. Use Riverpod (not Provider/Bloc) and Drift for local DB.
Honor the performance budget (60fps, <1.5s cold start, <35MB APK).

---

## 5. Common Commands

Run from this project root (`RADHA_UPGRADED_PROJECT_FILES/`):

```bash
pnpm install              # install all workspaces
pnpm build                # build packages then @radha/server
pnpm lint                 # lint every workspace
pnpm test                 # test every workspace
pnpm format               # prettier across workspaces
pnpm server:dev           # API watch mode (run in YOUR terminal, not an agent tool)
pnpm server:worker
pnpm server:scheduler
```

Server (`cd server`): `pnpm start:dev | start:prod | start:worker | start:scheduler |
build | lint | lint:fix | test | test:cov | test:e2e | db:generate | db:migrate |
db:studio`.

Mobile (`cd apps/mobile`): `flutter pub get`, `dart run build_runner build
--delete-conflicting-outputs`, `flutter test`, `flutter run`.

**Validation gate before declaring a backend phase complete:**
```bash
cd server
pnpm install && pnpm lint && pnpm test && pnpm build
```

**Local infra:** Postgres at container `radha-postgres` (port 5433, db `radha_dev`, user
`radha`); Redis at `radha-redis` (port 6380). `docker-compose.yml` is at the root.

---

## 6. Platform Notes (Windows)

- This workspace is Windows. The agent shell is **PowerShell** (use `;` to chain, `$env:`
  for env vars, `$null` not `/dev/null`). A Bash tool is also available for POSIX scripts.
- **Do not** start dev servers, watchers, or `--watch` test runs from agent tools — they
  block. Ask the user to run those in their own terminal.

---

## 7. Naming Conventions

- TS files `kebab-case.ts`; classes/types `PascalCase`; vars/functions `camelCase`.
- NestJS module files: `<feature>.{module,controller,service,repository}.ts`; DTOs in
  `dto/`; unit tests `*.spec.ts` next to the file; e2e in `server/test/`.
- Migrations `NNN_short_description.sql` (monotonic); Drizzle schema files plural-noun.
- Dart files `snake_case.dart`; mobile features under
  `apps/mobile/lib/features/<feature>/{data,domain,presentation}`.
- Next.js routes lowercase folders, `page.tsx`, route groups in `(parens)`.

---

## 8. Documentation Index (source of truth at project root)

Read the relevant doc before changing related code, and update the listed docs alongside
code changes.

- **Product/architecture:** `RADHA_CLIENT_OVERVIEW.md`, `MASTER_ARCHITECTURE.md`,
  `BACKEND_ARCHITECTURE.md`, `FRONTEND_ARCHITECTURE.md`, `DATABASE_ARCHITECTURE.md`,
  `AI_MODULES_ARCHITECTURE.md`.
- **Contracts/wiring:** `API_CONTRACTS.md`, `CONNECTION_MAP.md`,
  `PROJECT_FILE_STRUCTURE.md`, `COMPONENTS.md`, `PAGES.md`.
- **Execution order:** `BUILD_ORDER_INDEX.md`, `EXECUTION_ROADMAP.md`,
  `PHASE_DEPENDENCY_MAP.md`, `EXECUTION_READY_STATUS.md`.
- **Backend phases:** `BACKEND_EXECUTION_PHASES.md` + `BACKEND_PHASES/BE-NN_PHASE.md`
  (+ `_HANDOFF` / `_VERIFICATION`). Roadmap: `BACKEND_PHASES/00_MASTER_BACKEND_ROADMAP.md`.
- **Frontend phases:** `FRONTEND_EXECUTION_PHASES.md`, `FRONTEND_BUILD_ORDER.md`,
  `FRONTEND_DESIGN_SYSTEM.md`, `FRONTEND_QA_SYSTEM.md`, `FRONTEND_VERIFICATION_SYSTEM.md`,
  and `FRONTEND_PHASES/FE-NN_PHASE.md` (+ `00_MASTER_FRONTEND_ROADMAP.md`).
- **Other layers:** `DATABASE_EXECUTION_PHASES.md`, `INFRASTRUCTURE_EXECUTION_PHASES.md`,
  `TESTING_AND_LAUNCH_PHASES.md`, `OBSERVABILITY_PLAN.md`, `CI_CD_PIPELINE.md`,
  `LOCALIZATION_STRATEGY.md`, `ASSET_PIPELINE.md`, `PRODUCTION_CHECKLIST.md`,
  `TECHNICAL_DEBT_REGISTER.md`, `ADR_LOG.md`, `GOLDEN_TEST_REGISTRY.md`,
  `SESSION_HANDOFF_TO_NEXT_CONTEXT.md`.
- **Specs (Kiro):** `.kiro/specs/radha-platform/requirements.md`,
  `.kiro/specs/radha-platform-design/{requirements,design}.md`,
  `.kiro/specs/radha-flutter-mobile/`.

> Note: phase **status tables** inside the roadmap docs are stale (last hand-updated
> 2026-05-17). The actual code is ahead of them — trust the filesystem + a fresh build
> over the status tables.

---

## 9. Skills & MCP Tooling (use proactively)

**Global Claude Code skills** (installed 2026-06-03, available after a Claude Code
restart): `impeccable` (pbakaus/impeccable — design quality/critique/polish),
`design-taste-frontend` (Leonxlnx/taste-skill), `emil-design-eng` (emilkowalski/skill —
motion/interaction craft).

**Project skill library** lives in `.kiro/skills/` (33 skills: `sleek-design-mobile-apps`,
`vercel-composition-patterns`, `web-design-guidelines`, `high-end-visual-design`,
`minimalist-ui`, `industrial-brutalist-ui`, `imagegen-frontend-{mobile,web}`,
`image-to-code`, `gpt-taste`, `stitch-design-taste`, `brandkit`, `ckm-*`, etc.). Claude
Code doesn't auto-load `.kiro/skills`, so **consult them by reading the relevant
`SKILL.md` on demand** during design/frontend work.

**Skill usage policy:** for ANY UI/frontend/animation/design task, proactively consult the
design skills above (global + `.kiro/skills`) and apply their guidance — this project is
explicitly optimized for premium feel, retention, and best-in-class visuals.

**MCP servers** (configured globally in `~/.claude.json` and per-project in `.mcp.json`;
require a Claude Code restart to connect):
- **`kiro-gpt-bridge`** — image generation (`generate_image`, `generate_logo`,
  `generate_hero`, `generate_icon_set`, `generate_ui_mockup`). Routes through a local
  ChatGPT Pro session, **not** an API key. Server built at
  `C:\Users\sayan\Desktop\kirogpt`. **To actually generate**, the relay + browser-agent
  must be running and logged into ChatGPT Pro (see `.tmp-start-relay.bat` and the
  `image-gpt` repo). Convention: when a UI source file references an image asset that
  doesn't exist under `assets/`, generate it via this server.
- **`playwright`** — web smoke tests / screenshots.
- **`mobile-mcp`** — drives the Flutter app on device/emulator.

---

## 10. Current Status (snapshot 2026-06-03)

- **Backend (NestJS): feature-complete.** BE-01..BE-57 planned and built;
  `server/src/modules/` has ~43 module folders, ~31 SQL migrations. Prior handoff:
  ~750 TS files, ~95 tables, ~410 endpoints, ~607/612 tests green, boots with Docker.
- **Mobile (Flutter): substantially built, mid-flight.** `apps/mobile/` is a full Flutter
  app with ~25 feature folders, `core/design/l10n`, 6 generated locales; Android build
  scripts + smoke screenshots exist. Polish/QA/release phases (FE-33..FE-40) and per-phase
  verification are not confirmed complete.
- **Not started:** Marketing website (`apps/marketing-web`), Owner Dashboard
  (`apps/owner-dashboard`), AWS production deploy (RDS/ElastiCache/S3/CloudFront, BE-49
  infra), RDS automated backups + restore tests.
- **Backend tests: GREEN as of 2026-06-09** — full `pnpm test` is **2059/2059 passing (213 suites)**.
  The previously-listed nits were resolved/verified: `onboarding.controller.spec.ts` now
  `.overrideGuard(JwtAuthGuard)`; `db.service.spec.ts` updated for the eager-constructor pool;
  `bullmq-queue.provider.spec.ts` spies on the re-imported `Logger` graph. The `webhook-retry.job`
  cron "timezone" and the two module-local `PRODUCTS_LOOKUP_PORT` symbols were confirmed **non-issues**
  (left untouched). See `TECHNICAL_DEBT_REGISTER.md` for any remaining schema-barrel notes.

---

## 11. Working Agreements (from prior sessions)

- The user communicates fast (often voice-to-text) — expect typos/merged words; infer
  intent. They want **decisions made, not menus**; default to the recommended path and
  explain why it matters. They want **best-in-class** output, not the safe/cheap option.
- When a build/test fails, fix it and report back rather than surfacing options.
- The user frequently asks for parallel sub-agents and uses the architecture funnel as a
  checkpoint between work units.
