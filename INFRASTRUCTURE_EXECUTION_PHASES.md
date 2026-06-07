# File: INFRASTRUCTURE_EXECUTION_PHASES.md

# Infrastructure, Testing, Deployment, and Launch Phases

## Phase INF-01: Local Development Environment

### Goal
Dockerize Postgres/Redis/localstack-compatible S3 if used, dev scripts, local env.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/local-development-environment.md` | Required implementation/documentation artifact | Yes |
| `infra/docker-compose.dev.yml` | Required implementation/documentation artifact | No |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Local Development Environment complete when staging/prod readiness checks pass.
## Phase INF-02: AWS Account, IAM, VPC, and Cost Guardrails

### Goal
Create IAM roles, least privilege policies, VPC/subnets/security groups, budgets/alarms.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/aws-account-iam-vpc-and-cost-guardrails.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
AWS Account, IAM, VPC, and Cost Guardrails complete when staging/prod readiness checks pass.
## Phase INF-03: RDS PostgreSQL Provisioning

### Goal
Create RDS, parameter group, backups, connection limits, migration access.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/rds-postgresql-provisioning.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
RDS PostgreSQL Provisioning complete when staging/prod readiness checks pass.
## Phase INF-04: S3 Media Buckets and CloudFront CDN

### Goal
Create buckets, CORS, lifecycle, signed access pattern, CloudFront distribution.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/s3-media-buckets-and-cloudfront-cdn.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
S3 Media Buckets and CloudFront CDN complete when staging/prod readiness checks pass.
## Phase INF-05: Compute Deployment Target

### Goal
Provision ECS Fargate or EC2 Docker host for API/worker/admin; define scale path.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/compute-deployment-target.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Compute Deployment Target complete when staging/prod readiness checks pass.
## Phase INF-06: Secrets and Environment Promotion

### Goal
Set secrets manager/SSM, staging/prod envs, rotation rules.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/secrets-and-environment-promotion.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Secrets and Environment Promotion complete when staging/prod readiness checks pass.
## Phase INF-07: CI/CD Pipeline

### Goal
GitHub Actions for lint/test/build/migrate/deploy with manual prod approval.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/ci-cd-pipeline.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
CI/CD Pipeline complete when staging/prod readiness checks pass.
## Phase INF-08: Staging Deployment

### Goal
Deploy full staging stack, seed demo tenant, verify app/admin/backend flows.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/staging-deployment.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Staging Deployment complete when staging/prod readiness checks pass.
## Phase INF-09: Monitoring, Logging, and Alerting

### Goal
CloudWatch, Sentry, uptime, audit log alerts, cost alerts.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/monitoring-logging-and-alerting.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Monitoring, Logging, and Alerting complete when staging/prod readiness checks pass.
## Phase INF-10: Backup, Restore, and Disaster Recovery Drill

### Goal
Run restore test, media backup check, DB snapshot policy, rollback plan.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/backup-restore-and-disaster-recovery-drill.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Backup, Restore, and Disaster Recovery Drill complete when staging/prod readiness checks pass.
## Phase INF-11: Security, Load, and Abuse Testing

### Goal
OWASP checks, k6 load tests, OTP abuse tests, file upload threat tests.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/security-load-and-abuse-testing.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Security, Load, and Abuse Testing complete when staging/prod readiness checks pass.
## Phase INF-12: Production Launch and Post-Launch Operations

### Goal
Go-live checklist, app store/internal distribution, first 30-day support cadence.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `infra/production-launch-and-post-launch-operations.md` | Required implementation/documentation artifact | Yes |
| `infra/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `PRODUCTION_CHECKLIST.md` | Update with this phase's contract, dependencies, and validation rules. |
| `EXECUTION_ROADMAP.md` | Update with this phase's contract, dependencies, and validation rules. |
| `.env.example` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
aws sts get-caller-identity
pnpm infra:validate
pnpm test
```

### Dependencies
Depends on PF-04 env contract and deployment readiness.

### Database Tables Affected
RDS/PostgreSQL resources where relevant.

### API Contracts Affected
Health endpoints and deployment URLs.

### Frontend Screens/Components Affected
Configured staging/prod API URLs.

### Backend Routes/Controllers/Services Affected
API/worker deployment, env vars, secrets, logs.

### Tests to Write
- Infra smoke test.
- Health check validation.
- Rollback dry-run.

### Validation Checklist
- No public DB/bucket.
- IAM least privilege.
- Cost alarms configured.
- Env vars present.

### Risks and Bugs to Watch
- AWS cost creep.
- Secrets in repo.
- Missing rollback plan.

### Completion Criteria
Production Launch and Post-Launch Operations complete when staging/prod readiness checks pass.
---

## 2026-05-15 Upgrade Patch: Infrastructure Additions for SaaS and Analytics

### Required Additions
- Separate deployment target or route group for owner dashboard.
- Marketing website analytics ingestion endpoint with rate limits.
- Event table retention and rollup jobs.
- Background scheduler for owner_daily_metrics rollups.
- Cost monitoring for AI usage and analytics volume.
- Secrets for subscription provider integration and analytics signing keys.

### Validation
- Owner dashboard is not publicly indexable.
- Owner dashboard routes require owner authentication.
- Analytics endpoints are rate-limited and abuse protected.
- Event ingestion can degrade gracefully without breaking the mobile app.

