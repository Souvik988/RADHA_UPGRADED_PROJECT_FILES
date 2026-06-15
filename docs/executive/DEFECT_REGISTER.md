# RADHA — Defect Register

> One register. Severity P0 (data loss / cross-tenant / payment corruption / secret exposure / cannot
> launch / destructive migration) · P1 (core journey broken / critical crash / incorrect health claim) ·
> P2 (degraded / a11y / l10n / perf / recoverable sync) · P3 (cosmetic). **No P0/P1 may remain at RC
> sign-off.** Fix the defect *class*, not just the instance.

## Closed (fixed + verified this program lineage)
| ID | Domain | Sev | Root cause | Fix | Regression test | Live verified | Commit | Status |
|---|---|---|---|---|---|---|---|---|
| D5 | Backend/Inventory | P1 | `InventoryModule` never imported in app.module → all `/inventory/*` 404 | wired into AppModule | live sweep | yes (38/38) | d1826c4 | CLOSED |
| D6 | Backend/Dashboard | P1 | `ClientDashboardModule` never imported → `/dashboard` KPI routes 404 | wired into AppModule | live sweep | yes | d1826c4 | CLOSED |
| D7 | Backend/RBAC | P1 | `consumer` role lacked `products:read` → catalog/lookup 403 (mobile fake-ApiClient never hit real guard) | granted in role-permissions.map | permissions spec | yes | d1826c4 | CLOSED |
| D8 | Backend/Dashboard | P1 | KPI SQL referenced non-existent `products.is_active`, not store-scoped → 500 | rewrote to store-scoped `inventory_items.is_low_stock` | live sweep | yes | d1826c4 | CLOSED |
| D9 | Backend/Subscriptions | P1 | self-service `tenants/onboard` never called `startTrial` → `/subscriptions/status` 404 | start trial post-commit; TenantsModule imports SubscriptionsModule | tenant-onboarding spec 12/12 | yes (returns trial) | 38c5675 | CLOSED |

> **Class lesson (carry forward):** static "WIRED" ≠ runtime-working. Every D5–D8 defect was invisible
> to static analysis and to mobile tests (which mock the ApiClient). **Live-verify every domain.**

## Open
| ID | Domain | Sev | Description | Status |
|---|---|---|---|---|
| D3 | Dashboard | P2 | `radha_dashboard/features/expiry/scope-change.test.tsx` — `scope` type drift; decide if `scope` is an intended field | OPEN — needs product-intent decision then fix+test |
| D4 | Dashboard | P2 | `@playwright/test` not installed → no dashboard E2E | OPEN — `npm i -D @playwright/test && npx playwright install`, then author journeys |
| D11 | Catalog/data | P2 | **Browse catalog thin + bundled cards not linked to real data.** Server catalog had only 2 real products (OFF rate-limit during seed); the `db:import:curated` step is NOT in the standard bring-up, so a fresh backend has an empty catalog. Mobile bundled launch-catalog cards only link to server data when `resolved_eans.g.dart` carries the EANs. Regenerating it from a richer import (9 EANs) breaks 3 catalog tests that are coupled to specific resolved-EAN fixtures (one throws a test-side StateError — confirmed NOT an app bug; `launchProductByEan` is null-safe). | **CLOSED** 2026-06-15 (adbb01a): (1) server catalog enriched to 11 real products via `db:import:curated`, now a documented required seed step; (2) regenerated `resolved_eans.g.dart` (9 real EANs → bundled cards link to live nutrition on tap); (3) decoupled the 3 product-detail tests from the non-deterministic generated file by passing an explicit `initial` BrowseProduct EAN. Verified: analyze clean + flutter test 243/243. Browse works live (server products clickable; honest "scan to unlock" for unresolved). |
| D10 | Mobile/l10n | P2 | **Localization materially incomplete** — only 19/63 feature files use AppLocalizations; ~19 screens still carry hardcoded English (product/product_detail, onboarding, allergen, scan, scan_result, home, task_create, grn_items, expiry_create, ean_audit, grn_create, task_detail, shopping_list, referrals, label_scan, expiry_calendar, inventory_list, …). Prior reports ("Product Detail localized") referred to `features/catalog/product_detail_screen.dart` only — a *separate* `features/product/product_detail_screen.dart` and most other domains remain English. **Root class:** the ARB-completeness test guards KEY parity across locales but does NOT detect screens whose strings were never extracted to ARB. | OPEN — (1) add a static "visible-literal" guard (§10) with a brand/diagnostic allowlist; (2) sweep the ~19 screens domain-by-domain into ARB ×6 (each its own green commit). Evidence: grep 2026-06-15 (DISCOVER). |

## Watch / to-confirm (not yet a defect — verify, then classify)
- Razorpay test-mode race (success-before-confirm must show *pending*, not failed) — verify on device → if wrong, P1.
- Recall returns 403 for tenant-less consumer — confirmed **by design** (tenant-scoped); NOT a defect.
- `/subscriptions/status` 404 for tenants created via a path other than onboard/business-activation — verify no other onboarding path skips `startTrial`.
- BullMQ `bullmq.init.failed` on boot when Redis queues mis-init — degrades background jobs; confirm worker path on staging → if jobs drop, P1.
