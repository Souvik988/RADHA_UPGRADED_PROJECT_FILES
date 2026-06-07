# File: BACKEND_ARCHITECTURE.md

# RADHA Backend Architecture

## Pattern
NestJS modular monolith with clean module boundaries.

## Runtime Entry Points
- API process: REST endpoints.
- Worker process: imports, OCR, reports, AI summaries, notifications.
- Scheduler process: reminders, metric rollups, cleanup jobs.

## Controller/Service/Repository Rules
- Controllers are transport only.
- Services own business logic and transactions.
- Repositories own database queries.
- Integrations hide external providers.
- All writes that change business state add audit logs.

# File: BACKEND_EXECUTION_PHASES.md

# Backend Execution Phases

## Phase BE-01: NestJS Backend Initialization

### Goal
Create server app with API, worker, and scheduler entrypoints.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/nestjs-backend-initialization/` | Create required folder scaffold | Yes |
| `server/src/modules/nestjs-backend-initialization/nestjs-backend-initialization.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/nestjs-backend-initialization/nestjs-backend-initialization.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/nestjs-backend-initialization/nestjs-backend-initialization.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for NestJS Backend Initialization.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
NestJS Backend Initialization endpoints are implemented, tested, documented, and wired.
## Phase BE-02: Configuration and Environment Validation

### Goal
Add typed config, env validation, secrets naming, and boot-time failure on invalid configuration.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/configuration-and-environment-validation/` | Create required folder scaffold | Yes |
| `server/src/modules/configuration-and-environment-validation/configuration-and-environment-validation.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/configuration-and-environment-validation/configuration-and-environment-validation.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/configuration-and-environment-validation/configuration-and-environment-validation.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Configuration and Environment Validation.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Configuration and Environment Validation endpoints are implemented, tested, documented, and wired.
## Phase BE-03: Global Middleware, Error Envelope, Logging, and Request Context

### Goal
Add request IDs, safe logs, error filters, response envelope, CORS, Helmet, validation pipes.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/global-middleware-error-envelope-logging-and-request-context/` | Create required folder scaffold | Yes |
| `server/src/modules/global-middleware-error-envelope-logging-and-request-context/global-middleware-error-envelope-logging-and-request-context.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/global-middleware-error-envelope-logging-and-request-context/global-middleware-error-envelope-logging-and-request-context.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/global-middleware-error-envelope-logging-and-request-context/global-middleware-error-envelope-logging-and-request-context.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Global Middleware, Error Envelope, Logging, and Request Context.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Global Middleware, Error Envelope, Logging, and Request Context endpoints are implemented, tested, documented, and wired.
## Phase BE-04: Database Connection and Repository Foundation

### Goal
Add Drizzle/Knex data layer, migrations loader, base repository utilities, transactions.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/database-connection-and-repository-foundation/` | Create required folder scaffold | Yes |
| `server/src/modules/database-connection-and-repository-foundation/database-connection-and-repository-foundation.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/database-connection-and-repository-foundation/database-connection-and-repository-foundation.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/database-connection-and-repository-foundation/database-connection-and-repository-foundation.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Database Connection and Repository Foundation.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Database Connection and Repository Foundation endpoints are implemented, tested, documented, and wired.
## Phase BE-05: Authentication, OTP, Sessions, and Admin Login

### Goal
Implement mobile OTP, admin login, refresh tokens, session revocation, OTP abuse protection.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/authentication-otp-sessions-and-admin-login/` | Create required folder scaffold | Yes |
| `server/src/modules/authentication-otp-sessions-and-admin-login/authentication-otp-sessions-and-admin-login.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/authentication-otp-sessions-and-admin-login/authentication-otp-sessions-and-admin-login.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/authentication-otp-sessions-and-admin-login/authentication-otp-sessions-and-admin-login.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Authentication, OTP, Sessions, and Admin Login.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Authentication, OTP, Sessions, and Admin Login endpoints are implemented, tested, documented, and wired.
## Phase BE-06: Authorization, Roles, Users, Tenants, and Stores

### Goal
Implement role guards, tenant/store scoping, user management, store management.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/authorization-roles-users-tenants-and-stores/` | Create required folder scaffold | Yes |
| `server/src/modules/authorization-roles-users-tenants-and-stores/authorization-roles-users-tenants-and-stores.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/authorization-roles-users-tenants-and-stores/authorization-roles-users-tenants-and-stores.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/authorization-roles-users-tenants-and-stores/authorization-roles-users-tenants-and-stores.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Authorization, Roles, Users, Tenants, and Stores.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Authorization, Roles, Users, Tenants, and Stores endpoints are implemented, tested, documented, and wired.
## Phase BE-07: Product Catalog and Barcode Lookup Module

### Goal
Implement product lookup by EAN, Open Food Facts fallback, manual product creation, product update.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/product-catalog-and-barcode-lookup-module/` | Create required folder scaffold | Yes |
| `server/src/modules/product-catalog-and-barcode-lookup-module/product-catalog-and-barcode-lookup-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/product-catalog-and-barcode-lookup-module/product-catalog-and-barcode-lookup-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/product-catalog-and-barcode-lookup-module/product-catalog-and-barcode-lookup-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Product Catalog and Barcode Lookup Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Product Catalog and Barcode Lookup Module endpoints are implemented, tested, documented, and wired.
## Phase BE-08: Health Scoring and Product Analysis Module

### Goal
Implement rule-based health indicators, child preference, sugar/oil/processed flags, recompute API.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/health-scoring-and-product-analysis-module/` | Create required folder scaffold | Yes |
| `server/src/modules/health-scoring-and-product-analysis-module/health-scoring-and-product-analysis-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/health-scoring-and-product-analysis-module/health-scoring-and-product-analysis-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/health-scoring-and-product-analysis-module/health-scoring-and-product-analysis-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Health Scoring and Product Analysis Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Health Scoring and Product Analysis Module endpoints are implemented, tested, documented, and wired.
## Phase BE-09: EAN List Import and Validation Module

### Goal
Implement Excel/CSV upload parsing, validation, import errors, approved EAN lookup, list versioning.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/ean-list-import-and-validation-module/` | Create required folder scaffold | Yes |
| `server/src/modules/ean-list-import-and-validation-module/ean-list-import-and-validation-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/ean-list-import-and-validation-module/ean-list-import-and-validation-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/ean-list-import-and-validation-module/ean-list-import-and-validation-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for EAN List Import and Validation Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
EAN List Import and Validation Module endpoints are implemented, tested, documented, and wired.
## Phase BE-10: Scan Sessions, Bulk Scan, and Audit Module

### Goal
Implement scan sessions, scan item writes, EAN pass/fail, duplicate detection, audit metadata.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/scan-sessions-bulk-scan-and-audit-module/` | Create required folder scaffold | Yes |
| `server/src/modules/scan-sessions-bulk-scan-and-audit-module/scan-sessions-bulk-scan-and-audit-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/scan-sessions-bulk-scan-and-audit-module/scan-sessions-bulk-scan-and-audit-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/scan-sessions-bulk-scan-and-audit-module/scan-sessions-bulk-scan-and-audit-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Scan Sessions, Bulk Scan, and Audit Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Scan Sessions, Bulk Scan, and Audit Module endpoints are implemented, tested, documented, and wired.
## Phase BE-11: Expiry Tracking Module

### Goal
Implement MFG/EXP dates, status calculation, category thresholds, expired/near-expiry queries.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/expiry-tracking-module/` | Create required folder scaffold | Yes |
| `server/src/modules/expiry-tracking-module/expiry-tracking-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/expiry-tracking-module/expiry-tracking-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/expiry-tracking-module/expiry-tracking-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Expiry Tracking Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Expiry Tracking Module endpoints are implemented, tested, documented, and wired.
## Phase BE-12: Task Assignment Module

### Goal
Implement task CRUD, assignment, due dates, status transitions, evidence requirements, completion rules.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/task-assignment-module/` | Create required folder scaffold | Yes |
| `server/src/modules/task-assignment-module/task-assignment-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/task-assignment-module/task-assignment-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/task-assignment-module/task-assignment-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Task Assignment Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Task Assignment Module endpoints are implemented, tested, documented, and wired.
## Phase BE-13: Reports and Export Module

### Goal
Implement report generation, Excel/PDF exports, report file storage, summary API.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/reports-and-export-module/` | Create required folder scaffold | Yes |
| `server/src/modules/reports-and-export-module/reports-and-export-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/reports-and-export-module/reports-and-export-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/reports-and-export-module/reports-and-export-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Reports and Export Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Reports and Export Module endpoints are implemented, tested, documented, and wired.
## Phase BE-14: Media, AWS S3, OCR, and Image Processing Module

### Goal
Implement presigned uploads, media approval, OCR expiry assist, label image queue.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/media-aws-s3-ocr-and-image-processing-module/` | Create required folder scaffold | Yes |
| `server/src/modules/media-aws-s3-ocr-and-image-processing-module/media-aws-s3-ocr-and-image-processing-module.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/media-aws-s3-ocr-and-image-processing-module/media-aws-s3-ocr-and-image-processing-module.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/media-aws-s3-ocr-and-image-processing-module/media-aws-s3-ocr-and-image-processing-module.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Media, AWS S3, OCR, and Image Processing Module.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Media, AWS S3, OCR, and Image Processing Module endpoints are implemented, tested, documented, and wired.
## Phase BE-15: AI Wrapper, Report Summaries, Product Enrichment, and Anomaly Detection

### Goal
Create free-first AI abstraction, Open Food Facts enrichment, OCR structuring, optional LLM summaries.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection/` | Create required folder scaffold | Yes |
| `server/src/modules/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection/ai-wrapper-report-summaries-product-enrichment-and-anomaly-detection.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for AI Wrapper, Report Summaries, Product Enrichment, and Anomaly Detection.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
AI Wrapper, Report Summaries, Product Enrichment, and Anomaly Detection endpoints are implemented, tested, documented, and wired.
## Phase BE-16: Notifications, Testing, Hardening, and Performance Optimization

### Goal
Implement SMS wrapper, email notifications, push hooks, tests, rate limits, security hardening, perf checks.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/modules/notifications-testing-hardening-and-performance-optimization/` | Create required folder scaffold | Yes |
| `server/src/modules/notifications-testing-hardening-and-performance-optimization/notifications-testing-hardening-and-performance-optimization.module.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/notifications-testing-hardening-and-performance-optimization/notifications-testing-hardening-and-performance-optimization.service.ts` | Required implementation/documentation artifact | No |
| `server/src/modules/notifications-testing-hardening-and-performance-optimization/notifications-testing-hardening-and-performance-optimization.controller.ts` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |
| `CONNECTION_MAP.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm install
pnpm lint
pnpm test
pnpm build
```

### Dependencies
Depends on PF-05/PF-06 and required DB migrations.

### Database Tables Affected
See DATABASE_ARCHITECTURE.md table-to-phase map.

### API Contracts Affected
Affected endpoints are listed in API_CONTRACTS.md.

### Frontend Screens/Components Affected
Consumed by Flutter/Admin typed service layer.

### Backend Routes/Controllers/Services Affected
NestJS module/controller/service/repository for Notifications, Testing, Hardening, and Performance Optimization.

### Tests to Write
- Unit tests for services/domain logic.
- Repository integration tests.
- API E2E tests for happy path and failures.

### Validation Checklist
- DTO validation rejects invalid input.
- Controllers contain no business logic.
- Logs redact PII.
- Rate limits exist for risky routes.

### Risks and Bugs to Watch
- Tenant/store scoping missing.
- Business logic in controllers.
- Unbounded queries.

### Completion Criteria
Notifications, Testing, Hardening, and Performance Optimization endpoints are implemented, tested, documented, and wired.
---

## 2026-05-15 Upgrade Patch: Domain Modules for Inventory, GRN, Subscriptions, and Owner Analytics

### Corrected Backend Module Structure
Use clean domain modules instead of long generated phase-name folders.

```text
server/src/modules/auth/
server/src/modules/users/
server/src/modules/tenants/
server/src/modules/stores/
server/src/modules/products/
server/src/modules/ean-lists/
server/src/modules/scans/
server/src/modules/expiry/
server/src/modules/tasks/
server/src/modules/reports/
server/src/modules/suppliers/
server/src/modules/grn/
server/src/modules/inventory/
server/src/modules/subscriptions/
server/src/modules/payments/
server/src/modules/analytics/
server/src/modules/owner-dashboard/
server/src/modules/ai/
server/src/modules/media/
server/src/modules/notifications/
```

### Added Business Rules
#### GRN Rules
- GRN starts as `draft`.
- Supplier and invoice number are required before posting.
- GRN posting must be transactional.
- Posted GRN creates inventory batches and stock movements.
- Posted GRN cannot be edited directly; use correction/adjustment flow.

#### Inventory Rules
- Every stock change must create a `stock_movement`.
- Current stock is updated only through inventory service transactions.
- Low-stock alerts are opened/resolved by the inventory service.
- Stock out requires reason and actor.
- Expiry-tracked products should use batch-level quantities.

#### Subscription Rules
- Trial, active, grace, expired, cancelled states must be centralized.
- Entitlements are enforced in backend guards, not only UI.
- Plan limits should support ₹49, ₹99, and ₹199 plan definitions.

#### Owner Dashboard Rules
- Owner dashboard APIs require owner-only authorization.
- Tenant users cannot access website analytics or global app analytics.
- App usage events should avoid storing sensitive raw data.
- Metrics should be rolled up for fast dashboard loading.

