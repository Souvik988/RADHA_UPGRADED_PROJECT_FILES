# Project Structure

## Repository layout

```text
RADHA_UPGRADED_PROJECT_FILES/
  radha_backend/                # NestJS backend (API + Worker + Scheduler) — standalone
  radha_app/                    # Flutter mobile app — standalone
  .kiro/                        # Kiro specs, hooks, steering, skills
  .gitignore
  .gitattributes
```

> This is a trimmed, deploy-focused copy. The old monorepo scaffolding
> (`packages/`, `infra/`, `deploy/`, `docker-compose.yml`, root `package.json`,
> `pnpm-workspace.yaml`) and the architecture/phase planning docs have been removed.
> The two app folders are each self-contained and deployed independently.

## Backend (`radha_backend/src/`)

```text
radha_backend/src/
  main.api.ts                   # REST API entrypoint
  main.worker.ts                # BullMQ worker entrypoint
  main.scheduler.ts             # Cron/scheduler entrypoint
  app.module.ts
  shared-types.ts               # Inlined domain DTOs/contracts (was @radha/shared-types)
  common/                       # Decorators, guards, pipes, filters, interceptors
  config/                       # Typed config + env validation (zod)
  db/
    schema/                     # Drizzle table schemas (per domain)
    migrations/                 # SQL migrations (NNN_name.sql)
    migrate.ts                  # Migration runner
    reset.ts                    # Dev reset
  integrations/                 # External providers (2Factor, S3, OFF, OpenAI/Gemini, FCM, Razorpay, etc.)
  jobs/                         # BullMQ producers/consumers shared across modules
  logging/                      # pino setup + cls request context
  observability/                # Sentry, health, metrics
  modules/                      # One folder per domain module
```

### Backend modules
`auth`, `tenants`, `stores`, `products`, `health`, `health-scoring`, `ean-lists`, `scans`,
`expiry`, `expiry-calendar`, `tasks`, `reports`, `media`, `notifications`, `ai`, `suppliers`,
`grn`, `inventory`, `subscriptions`, `analytics`, `client-dashboard`, `affiliate`, `allergen`,
`barcode-learning`, `business-activation`, `catalog-import`, `feature-flags`, `image-fallback`,
`ingredient-explainer`, `onboarding`, `payments`, `public-product`, `rate-limiting`, `recall`,
`referrals`, `saved-products`, `shopping-list`, `sync`, `user-language`, `verified-badge`,
`voice`, `webhooks`, `weekly-digest`, `admin-impersonation`.

### Module conventions
Each `radha_backend/src/modules/<domain>/` follows:
```
<domain>/
  <domain>.module.ts            # NestJS module wiring
  <domain>.controller.ts        # HTTP transport only (or controllers/)
  <domain>.service.ts           # Business logic + transactions (or services/)
  <domain>.repository.ts        # Drizzle queries, no business logic (or repositories/)
  dto/                          # Request/response DTOs (class-validator)
  types/                        # Domain types
```

## Mobile app (`radha_app/lib/`)

```text
radha_app/lib/
  main.dart                     # App entrypoint (ProviderScope + MaterialApp.router)
  core/                         # auth, network (dio/retrofit), offline (drift), router, i18n
  design/                       # tokens, theme, shared widgets
  features/                     # One folder per screen/feature (home, scan, expiry, tasks, ...)
  l10n/                         # ARB locale files + generated localizations
```

## Database conventions
- `snake_case` table and column names.
- `id uuid primary key`, `created_at`, `updated_at`, `deleted_at` (where mutable/soft-delete).
- `tenant_id` on every multi-tenant business table; `store_id` on operational tables.
- Cursor pagination on `(created_at desc, id desc)` or domain-specific sort.
- Composite indexes always lead with `tenant_id` (or `store_id`).
- Migrations are sequentially numbered: `NNN_purpose.sql`. Generate with `pnpm db:generate`, apply with `pnpm db:migrate`.

## Shared types
- Single source of truth for API contracts: `radha_backend/src/shared-types.ts`.
- Framework-free domain primitives (no NestJS/AWS imports). Imported in backend code
  via the `@/shared-types` path alias.

## Where things go
- New API endpoint → `radha_backend/src/modules/<domain>/<domain>.controller.ts` + DTO in `dto/` + DB query in `<domain>.repository.ts`.
- New table → schema in `radha_backend/src/db/schema/<table>.ts` + migration in `radha_backend/src/db/migrations/NNN_*.sql`.
- New shared contract type → add it to `radha_backend/src/shared-types.ts`.
- New external provider → wrap it in `radha_backend/src/integrations/<provider>/`. Never call third-party SDKs directly from a service.
- New background job → producer in the owning module, consumer in `radha_backend/src/jobs/` registered on the worker entrypoint.
- New mobile screen → `radha_app/lib/features/<feature>/` consuming the typed network layer in `radha_app/lib/core/network/`.
