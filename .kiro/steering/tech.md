# Tech Stack

## Repository shape
RADHA now lives as two standalone, independently-deployable folders at the repo root:
- `radha_backend/` — NestJS backend (API + Worker + Scheduler).
- `radha_app/` — Flutter mobile app.

There is **no pnpm workspace / monorepo** anymore. The backend is self-contained:
the previously shared `@radha/shared-types` package has been **inlined** into
`radha_backend/src/shared-types.ts` (imported via the `@/shared-types` path alias).
Node `>=18.17.0`, TypeScript 5.3.

## Backend (`radha_backend/`)
- **NestJS 10** modular monolith with three runtime entrypoints:
  - `src/main.api.ts` — REST API process
  - `src/main.worker.ts` — BullMQ workers (imports, OCR, reports, AI, notifications)
  - `src/main.scheduler.ts` — cron jobs (reminders, rollups, cleanup)
- **Drizzle ORM** (`drizzle-orm` + `drizzle-kit`) over **PostgreSQL** (`postgres` driver).
- **BullMQ + ioredis** for background jobs.
- **Validation**: `class-validator` + `class-transformer` for DTOs, `zod` for schema-level validation.
- **Auth**: `@nestjs/jwt`, `bcrypt`, OTP via 2Factor.in (server-only wrapper; `mock` provider in dev).
- **Logging/observability**: `nestjs-pino` + `pino-http`, request context via `nestjs-cls`, Sentry (`@sentry/node`).
- **Security middleware**: `helmet`, `compression`.
- **AWS**: `@aws-sdk/client-s3`, `s3-presigned-post`, `s3-request-presigner`, `client-cloudfront`, `client-rekognition` (paid escalation only).
- **AI/OCR (free-first)**: `@google-cloud/vision` (ML Kit on device, Vision in worker), Open Food Facts HTTP, Google Gemini / optional `openai` for summaries. AWS Rekognition only as paid escalation.
- **Payments**: Razorpay (TEST mode; deterministic mock when key absent).
- **Files/exports**: `exceljs`, `xlsx`, `pdfkit`, `sharp`, `csv-parse`.
- **Push**: `firebase-admin`.
- Shared DTO/contract types live in `src/shared-types.ts` (framework-free domain primitives).

> Test files (`*.spec.ts`, e2e) and the `packages/`, `infra/`, `deploy/`, and root
> monorepo tooling have been removed from this trimmed deploy copy. If you reintroduce
> tests, Jest + ts-jest is the expected runner.

## Frontend (`radha_app/`)
- **Mobile**: Flutter, Riverpod for state, `go_router`, `dio` + `retrofit`, Drift for offline,
  Google ML Kit for on-device scan/OCR, `razorpay_flutter` for checkout.
- UI never calls HTTP directly — always through the typed `dio`/`retrofit` service layer.
- API base URL is injected at run/build time via `--dart-define=BASE_URL=...`
  (Android emulator reaches the host backend at `http://10.0.2.2:3000/api`).

## Local services (dev)
The backend `.env.development` expects:
- Postgres on **host port 5433** (db `radha_dev`, user `radha`)
- Redis on **host port 6380**

Run these however you prefer (local install or a Postgres/Redis container). The ports
are intentionally non-default to avoid clashing with a local 5432/6379.

## Code style
- Prettier (`.prettierrc`): single quotes, trailing commas, semicolons, print width 100, tab width 2, arrow parens always, LF line endings.
- ESLint with `@typescript-eslint` and `eslint-config-prettier` — `--max-warnings 0`.

## Common commands

### Backend (`cd radha_backend`)
```bash
pnpm install                  # or npm install — install deps
pnpm start:dev                # API watch mode (nest start --watch)
pnpm start:worker             # worker process
pnpm start:scheduler          # scheduler process
pnpm build                    # nest build + tsc-alias
pnpm lint                     # eslint, zero warnings
pnpm db:generate              # drizzle-kit generate:pg
pnpm db:migrate               # tsx src/db/migrate.ts
pnpm db:push                  # drizzle-kit push:pg
pnpm db:reset                 # tsx src/db/reset.ts
pnpm db:studio                # drizzle-kit studio
```

### Mobile app (`cd radha_app`)
```bash
flutter pub get                                   # install deps
dart run build_runner build -d                    # codegen (retrofit/json/drift/freezed)
flutter run --dart-define=BASE_URL=http://10.0.2.2:3000/api   # run on emulator
flutter build apk                                 # release build
```

## Backend rules (enforced in design + reviews)
- Controllers are **transport only** — no business logic.
- **Services** own business logic and transactions.
- **Repositories** own all database access.
- **Integrations** hide external providers (2Factor, OpenAI/Gemini, AWS, Open Food Facts, Razorpay, FCM).
- Every state-changing write also writes an **audit log**.
- DTO validation must reject invalid input; logs must redact PII; risky routes must be rate-limited.
- All multi-tenant queries must include `tenant_id` (and `store_id` where applicable).
