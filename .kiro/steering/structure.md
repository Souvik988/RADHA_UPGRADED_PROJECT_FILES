# Project Structure

## Repository layout

```text
radha/
  server/                       # NestJS backend (built today)
  packages/
    shared-types/               # @radha/shared-types — DTOs/contracts shared with frontends
  apps/                         # Frontend surfaces (planned, may not exist yet)
    mobile/                     # Flutter app
    marketing-web/              # Next.js public marketing site
    owner-dashboard/            # Next.js private owner-only SaaS dashboard
  infra/
    postgres/init/              # SQL run by Postgres container on first boot
  .kiro/                        # Kiro specs, hooks, steering
  docker-compose.yml            # Local Postgres + Redis
  pnpm-workspace.yaml
  package.json
  *.md                          # Architecture + phase planning documents (see below)
```

> Frontend `apps/` directories are referenced by the architecture docs but may not all be scaffolded yet. Do not move admin/website code under `apps/mobile`.

## Backend (`server/src/`)

```text
server/src/
  main.api.ts                   # REST API entrypoint
  main.worker.ts                # BullMQ worker entrypoint
  main.scheduler.ts             # Cron/scheduler entrypoint
  app.module.ts
  common/                       # Decorators, guards, pipes, filters, interceptors
  config/                       # Typed config + env validation (zod)
  db/
    schema/                     # Drizzle table schemas (per domain)
    migrations/                 # SQL migrations (NNN_name.sql)
    migrate.ts                  # Migration runner
    reset.ts                    # Dev reset
  integrations/                 # External providers (MSG91, S3, OFF, OpenAI, FCM, etc.)
  jobs/                         # BullMQ producers/consumers shared across modules
  logging/                      # pino setup + cls request context
  observability/                # Sentry, health, metrics
  modules/                      # One folder per domain module
```

### Current backend modules
`auth`, `tenants`, `stores`, `products`, `health`, `health-scoring`, `ean-lists`, `scans`, `expiry`, `tasks`, `reports`, `media`, `notifications`, `ai`, `suppliers`, `grn`, `inventory`, `subscriptions`, `analytics`, `client-dashboard`.

### Module conventions
Each `server/src/modules/<domain>/` follows:
```
<domain>/
  <domain>.module.ts            # NestJS module wiring
  <domain>.controller.ts        # HTTP transport only
  <domain>.service.ts           # Business logic + transactions
  <domain>.repository.ts        # Drizzle queries (no business logic)
  dto/                          # Request/response DTOs (class-validator)
  *.spec.ts                     # Unit tests next to source
```
- Tests live next to the source as `*.spec.ts`.
- E2E tests live in `server/test/`.

## Database conventions
- `snake_case` table and column names.
- `id uuid primary key`, `created_at`, `updated_at`, `deleted_at` (where mutable/soft-delete).
- `tenant_id` on every multi-tenant business table; `store_id` on operational tables.
- Cursor pagination on `(created_at desc, id desc)` or domain-specific sort.
- Composite indexes always lead with `tenant_id` (or `store_id`).
- Migrations are sequentially numbered: `NNN_purpose.sql`. Generate with `pnpm db:generate`, apply with `pnpm db:migrate`.

## Shared types (`packages/shared-types`)
- Single source of truth for API contracts.
- Imported by server as `@radha/shared-types` and (planned) by frontends.
- Built before server: root `pnpm build` does this automatically.
- Jest `moduleNameMapper` resolves it directly from source for fast tests.

## Phase-driven planning docs (repo root)
The product is built in numbered phases. These docs are the source of truth for what each phase delivers and the order things must be built in:

- `MASTER_ARCHITECTURE.md` — overall product, surfaces, modules.
- `BUILD_ORDER_INDEX.md` / `EXECUTION_ROADMAP.md` — what to build when.
- `BACKEND_ARCHITECTURE.md` + `BACKEND_EXECUTION_PHASES.md` (BE-NN).
- `FRONTEND_ARCHITECTURE.md` + `FRONTEND_EXECUTION_PHASES.md` (FE-NN).
- `DATABASE_ARCHITECTURE.md` + `DATABASE_EXECUTION_PHASES.md` (DB-NN).
- `INFRASTRUCTURE_EXECUTION_PHASES.md` (INF-NN), `PROJECT_FOUNDATION_EXECUTION_PHASES.md` (PF-NN), `TESTING_AND_LAUNCH_PHASES.md`.
- `API_CONTRACTS.md`, `CONNECTION_MAP.md`, `AI_MODULES_ARCHITECTURE.md`, `PROJECT_FILE_STRUCTURE.md`.
- `BACKEND_PHASES/` — one detailed handoff/phase doc per backend phase (`BE-NN_PHASE.md`, `BE-NN_HANDOFF.md`, `BE-NN_VERIFICATION.md`).

When implementing a feature, check the corresponding phase doc and update `BACKEND_ARCHITECTURE.md`, `API_CONTRACTS.md`, and `CONNECTION_MAP.md` as required by that phase.

## Build order rule
`packages/*` build first → `server` builds against the compiled shared-types. Don't bypass this with relative imports across workspaces.

## Where things go
- New API endpoint → `server/src/modules/<domain>/<domain>.controller.ts` + DTO in `dto/` + DB query in `<domain>.repository.ts`.
- New table → schema in `server/src/db/schema/<table>.ts` + migration in `server/src/db/migrations/NNN_*.sql` + table row in `DATABASE_ARCHITECTURE.md`.
- New shared contract → `packages/shared-types/src/` then re-export from `index.ts`.
- New external provider → wrap it in `server/src/integrations/<provider>/`. Never call third-party SDKs directly from a service.
- New background job → producer in the owning module, consumer in `server/src/jobs/` registered on the worker entrypoint.
