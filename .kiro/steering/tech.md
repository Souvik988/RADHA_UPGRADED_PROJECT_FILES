# Tech Stack

## Monorepo
- **pnpm workspaces** (`pnpm-workspace.yaml`). Workspaces: `server`, `packages/*`.
- Node `>=18.17.0`, pnpm `>=8.10.0`, TypeScript 5.3.

## Backend (`server/`)
- **NestJS 10** modular monolith with three runtime entrypoints:
  - `src/main.api.ts` — REST API process
  - `src/main.worker.ts` — BullMQ workers (imports, OCR, reports, AI, notifications)
  - `src/main.scheduler.ts` — cron jobs (reminders, rollups, cleanup)
- **Drizzle ORM** (`drizzle-orm` + `drizzle-kit`) over **PostgreSQL** (`postgres` driver).
- **BullMQ + ioredis** for background jobs.
- **Validation**: `class-validator` + `class-transformer` for DTOs, `zod` for schema-level validation.
- **Auth**: `@nestjs/jwt`, `bcrypt`, OTP via MSG91 (server-only wrapper).
- **Logging/observability**: `nestjs-pino` + `pino-http`, request context via `nestjs-cls`, Sentry (`@sentry/node`).
- **Security middleware**: `helmet`, `compression`.
- **AWS**: `@aws-sdk/client-s3`, `s3-presigned-post`, `s3-request-presigner`, `client-cloudfront`, `client-rekognition` (paid escalation only).
- **AI/OCR (free-first)**: `@google-cloud/vision` (ML Kit on device, Vision in worker), Open Food Facts HTTP, optional `openai` for summaries. AWS Rekognition only as paid escalation.
- **Files/exports**: `exceljs`, `xlsx`, `pdfkit`, `sharp`, `csv-parse`.
- **Push**: `firebase-admin`.
- **Testing**: Jest + ts-jest (unit/integration) and `supertest` for E2E (`test/jest-e2e.json`).

## Frontend (planned)
- **Mobile**: Flutter, Riverpod for state, Google ML Kit for on-device scan/OCR.
- **Admin / Marketing / Owner Dashboard**: Next.js with TanStack Query.
- UI never calls HTTP directly — always through a typed service layer that consumes `@radha/shared-types`.

## Shared packages
- `packages/shared-types` (`@radha/shared-types`) — typed DTOs/contracts shared by server and frontends.

## Infra (dev)
`docker-compose.yml` brings up:
- Postgres 16 on **host port 5433** (db `radha_dev`, user `radha`)
- Redis 7 on **host port 6380**

These ports are intentional to avoid clashing with local installs. Server `.env.development` matches them.

## Code style
- Prettier (`.prettierrc`): single quotes, trailing commas, semicolons, print width 100, tab width 2, arrow parens always, LF line endings.
- ESLint with `@typescript-eslint` and `eslint-config-prettier` — `--max-warnings 0`.

## Common commands

### Root (monorepo)
```bash
pnpm install                  # install everything
pnpm build                    # build packages then server
pnpm lint                     # lint all workspaces
pnpm test                     # run all workspace tests
pnpm format                   # prettier all workspaces
pnpm server:dev               # nest start --watch (API)
pnpm server:worker            # worker process
pnpm server:scheduler         # scheduler process
```

### Server (`cd server`)
```bash
pnpm start:dev                # API watch mode
pnpm start:worker             # worker
pnpm start:scheduler          # scheduler
pnpm build                    # nest build
pnpm lint                     # eslint, zero warnings
pnpm test                     # jest unit/integration
pnpm test:cov                 # with coverage
pnpm test:e2e                 # supertest E2E
pnpm db:generate              # drizzle-kit generate:pg
pnpm db:migrate               # tsx src/db/migrate.ts
pnpm db:push                  # drizzle-kit push:pg
pnpm db:reset                 # tsx src/db/reset.ts
pnpm db:studio                # drizzle-kit studio
```

### Local services
```bash
docker compose up -d          # start Postgres (5433) + Redis (6380)
docker compose down           # stop (data persists)
docker compose down -v        # full wipe
```

## Backend rules (enforced in design + reviews)
- Controllers are **transport only** — no business logic.
- **Services** own business logic and transactions.
- **Repositories** own all database access.
- **Integrations** hide external providers (MSG91, OpenAI, AWS, Open Food Facts).
- Every state-changing write also writes an **audit log**.
- DTO validation must reject invalid input; logs must redact PII; risky routes must be rate-limited.
- All multi-tenant queries must include `tenant_id` (and `store_id` where applicable).
