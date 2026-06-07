# File: TESTING_AND_LAUNCH_PHASES.md

# Testing and Launch Execution

## Test Matrix
| Layer | Tool | Required Coverage |
|---|---|---|
| Flutter unit/widget | flutter_test | UI states, validators, status badges |
| Flutter integration | integration_test | login, scan, expiry, report |
| Backend unit | Vitest/Jest | domain services |
| Backend integration | Testcontainers | repository + DB |
| API E2E | Supertest | endpoint contracts |
| Load | k6 | scan/report/auth endpoints |
| Security | OWASP ZAP | staging baseline |

## Launch Stages
1. Internal demo tenant.
2. Closed pilot with one store.
3. Three-store pilot.
4. Paid beta with support.
5. Public launch.
---

## 2026-05-15 Upgrade Patch: Added Tests for Advanced MVP

## Added Test Matrix Rows
| Layer | Tool | Required Coverage |
|---|---|---|
| Inventory service unit | Vitest/Jest | stock in, stock out, low-stock rule calculation, negative-stock prevention |
| GRN integration | Testcontainers | draft GRN -> add items -> post -> inventory batches + movements created atomically |
| Subscription E2E | Supertest | trial active, trial expired, plan active, entitlement denied |
| Owner dashboard E2E | Supertest | owner can access KPIs, tenant admin cannot access owner APIs |
| Website analytics | Playwright/API tests | pricing click, contact lead, app download CTA event ingestion |
| Mobile inventory widgets | flutter_test | inventory counts, low-stock cards, GRN forms, subscription status banners |
| Load | k6 | scan, inventory counts, stock movement, owner dashboard summary endpoints |

## Added Launch Gate
Before paid beta, validate:
1. One pilot store can complete scan -> expiry -> EAN audit -> GRN -> inventory count -> report.
2. Trial tenant converts to paid-plan test state.
3. Owner dashboard shows visitor, lead, signup, active user, subscription, and usage metrics.

