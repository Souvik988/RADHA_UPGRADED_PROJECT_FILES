# File: DATABASE_EXECUTION_PHASES.md

# Database Execution and Optimization Phases

## Phase DB-01: Database Engine Confirmation and Naming Conventions

### Goal
Lock PostgreSQL, schema names, UUID strategy, timestamps, soft delete policy, enum policy.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/001_database_engine_confirmation_and_naming_conventions.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-01 complete when migrations, indexes, and tests pass.
## Phase DB-02: Migration System and Base Extensions

### Goal
Create migration framework, uuid extension, citext extension, audit timestamp trigger, enum bootstrap.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/002_migration_system_and_base_extensions.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-02 complete when migrations, indexes, and tests pass.
## Phase DB-03: Identity, OTP, Sessions, and Audit Tables

### Goal
Create users, sessions, otp_attempts, audit_logs.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/003_identity_otp_sessions_and_audit_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-03 complete when migrations, indexes, and tests pass.
## Phase DB-04: Tenant, Store, Role, and Access Scope Tables

### Goal
Create tenants, stores, user_store_access, role-scoping constraints.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/004_tenant_store_role_and_access_scope_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-04 complete when migrations, indexes, and tests pass.
## Phase DB-05: Product Catalog, Nutrition, and Health Tables

### Goal
Create products, product_nutrition, product_health_assessments, product_sources.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/005_product_catalog_nutrition_and_health_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-05 complete when migrations, indexes, and tests pass.
## Phase DB-06: EAN Import and Approved Display Verification Tables

### Goal
Create ean_lists, ean_list_items, ean_import_errors, import_batches.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/006_ean_import_and_approved_display_verification_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-06 complete when migrations, indexes, and tests pass.
## Phase DB-07: Scan Session, Scan Item, and Expiry Tables

### Goal
Create scan_sessions, scan_items, expiry_records, expiry_thresholds.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/007_scan_session_scan_item_and_expiry_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-07 complete when migrations, indexes, and tests pass.
## Phase DB-08: Task and Workflow Tables

### Goal
Create tasks, task_assignments, task_events, task_evidence.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/008_task_and_workflow_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-08 complete when migrations, indexes, and tests pass.
## Phase DB-09: Reports, Export Files, and Dashboard Aggregation Tables

### Goal
Create reports, report_files, daily_store_metrics.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/009_reports_export_files_and_dashboard_aggregation_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-09 complete when migrations, indexes, and tests pass.
## Phase DB-10: Media and AI Extraction Tables

### Goal
Create media_assets, ai_extractions, ocr_attempts.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/010_media_and_ai_extraction_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-10 complete when migrations, indexes, and tests pass.
## Phase DB-11: Indexes, Constraints, and Composite Access Paths

### Goal
Apply unique, partial, composite, and GIN indexes based on query map.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/011_indexes_constraints_and_composite_access_paths.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-11 complete when migrations, indexes, and tests pass.
## Phase DB-12: Pagination, Filtering, Transactions, and Concurrency Strategy

### Goal
Define cursor pagination, atomic scan writes, import transactions, row locks where needed.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/012_pagination_filtering_transactions_and_concurrency_strategy.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-12 complete when migrations, indexes, and tests pass.
## Phase DB-13: Seed Data and Reference Data

### Goal
Seed roles, initial admin, health thresholds, categories, sample stores, demo products.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/013_seed_data_and_reference_data.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-13 complete when migrations, indexes, and tests pass.
## Phase DB-14: Backup, Restore, Retention, and Archiving

### Goal
Enable RDS backups, test restore, define retention for reports/media/audit logs.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/014_backup_restore_retention_and_archiving.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-14 complete when migrations, indexes, and tests pass.
## Phase DB-15: 10,000-User Readiness and Slow Query Validation

### Goal
Run EXPLAIN plans, load-seed 10K users, validate scan/report query latency, connection pooling.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/015_10_000_user_readiness_and_slow_query_validation.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-15 complete when migrations, indexes, and tests pass.
---

## 2026-05-15 Upgrade Patch: Added Database Execution Phases

## Phase DB-16: Suppliers and GRN Tables
### Goal
Create suppliers, grn_headers, grn_items, and constraints for invoice-level inward stock.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| server/src/db/migrations/016_suppliers_and_grn_tables.sql | Supplier and GRN schema | No |
| server/src/db/schema/grn.ts | Drizzle/ORM schema for GRN | No |
| server/src/db/schema/suppliers.ts | Drizzle/ORM schema for suppliers | No |
### Validation
- Unique supplier+invoice per store where possible.
- GRN status enum: draft, posted, cancelled.
- Expiry fields supported per item.

## Phase DB-17: Inventory Items, Batches, and Stock Movements
### Goal
Create inventory_items, inventory_batches, and stock_movements as the stock source of truth.
### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| server/src/db/migrations/017_inventory_items_batches_and_stock_movements.sql | Inventory schema | No |
| server/src/db/schema/inventory.ts | Inventory ORM schema | No |
### Validation
- Unique store+product current inventory row.
- Movement table is append-only.
- Non-negative stock enforced by service and DB checks where practical.

## Phase DB-18: Low Stock Rules and Alerts
### Goal
Create low_stock_rules and low_stock_alerts.
### Validation
- One active alert per store/product/rule.
- Alerts resolve when stock rises above threshold.

## Phase DB-19: Subscription Plans, Entitlements, and Events
### Goal
Create subscription_plans, plan_entitlements, tenant_subscriptions, and subscription_events.
### Validation
- Trial end date is queryable.
- Active/expired/cancelled states are indexed.
- Entitlements are versionable.

## Phase DB-20: Website Analytics, Leads, App Usage, and Owner Metrics
### Goal
Create website_events, marketing_leads, app_usage_events, and owner_daily_metrics.
### Validation
- Event tables are append-only.
- Owner dashboard reads rollups.
- PII minimization rules documented.

