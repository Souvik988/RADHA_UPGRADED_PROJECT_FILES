# RADHA — Master Function Matrix

The single map that drives domain-by-domain repair. Cross-references **mobile routes**,
**dashboard pages** and **backend endpoints**, with a status per function.

## Sources (ground truth, static)
- **Mobile:** `apps/mobile/lib/core/router/app_router.dart` (39 routes) + `api_client.dart`
  (82 endpoints). Package `radha_mobile`, branch `codex/radha-production-converged`.
- **Dashboard:** `radha_dashboard/` (Next.js 15.3) — **33 pages**, **84 BFF proxy routes**
  under `app/api/**`, all targeting `NEXT_PUBLIC_API_BASE_URL → /api/v1`. Branch
  `codex/radha-production-convergence` (export).
- **Backend:** `server/src/modules/**` — 52 controllers (~38 route prefixes). Some use
  object-syntax `@Controller({path,version})` so a few prefixes (tasks/expiry/reports) are
  proven via the ApiClient + dashboard proxies rather than the prefix grep.

## Methodology & live-verification status
Originally a **static** audit (code presence + contract match). **As of 2026-06-14 the
backend is running live** (`node dist/main.api` on `:3000` against the Docker
Postgres `:5433` / Redis `:6380` stack) and every backend domain has been **live-verified
over HTTP** — see the *Live API verification* section below. The mobile UI render +
test-mode Razorpay still need a device/emulator, and `@playwright/test` is still absent for
dashboard E2E, so those two axes remain `BLOCKED_EXTERNAL`. Per-**control** classification
(every button/filter/export) is done inside each domain's Phase-6 repair pass.

### Live API verification (2026-06-14)
Scripted sweep: OTP→token for a **consumer** and an **onboarded owner+tenant+store**
(`POST /tenants/onboard` → OTP login), then a representative GET per domain.
**Result: 38/38 endpoints return correct data/auth** (was 37/38; D9 fixed →
`/subscriptions/status` now returns `trial` for a freshly onboarded tenant). The
sweep caught **5 live defects the static audit had marked "WIRED"**, all fixed +
live-verified this session (D5–D9). Backend boot also required building
`@radha/shared-types` and adding the init-time-only `ANALYTICS_HASH_SALT` env.

**Status legend** (mandate set): WORKING · PARTIAL · UI_ONLY · API_DISCONNECTED ·
CONTRACT_MISMATCH · SILENT_FAILURE · DEAD_ACTION · BACKEND_MISSING · MOBILE_MISSING ·
DASHBOARD_MISSING · ROLE_BROKEN · ENTITLEMENT_BROKEN · BLOCKED_EXTERNAL · NOT_REQUIRED.
Here **WIRED** = all required layers present + contract matches statically (live still
`BLOCKED_EXTERNAL`); **WIRED+T** = also covered by automated tests.

## Layer inventory
| Layer | Count | Tests |
|---|---|---|
| Mobile routes | 39 | 45 Flutter test files / 227 tests |
| Mobile ApiClient endpoints | 82 | mocked-HTTP where present |
| Dashboard pages | 33 (incl. (auth)/(misc)) | 26 vitest files / 155 tests |
| Dashboard BFF proxy routes | 84 | — |
| Backend controllers | 52 (~38 prefixes) | 2059 jest (per CLAUDE.md; not re-run here) |

---

## A. Catalog & Product Intelligence
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Categories | `/catalog/:category` ProductBrowse | — (consumer) | `catalog` `GET /catalog/categories` | **WIRED+T** (catalog_source, live/offline/unavailable) |
| Browse + pagination | `/catalog/:category` | — | `GET /catalog/products` (cursor) | **WIRED+T** |
| Search | `/catalog/search` | — | `GET /catalog/products?q=` | **WIRED+T** |
| Product detail / nutrition / health | `/catalog/product/:key` | dashboard product mgmt (see Platform) | `products` `GET /products/lookup/:ean` | **WIRED+T** (lookup states 404/401/500/offline) |
| Ingredient explanation | `/ingredients/:slug` (ent) | — | `ingredients` `GET /ingredients/:slug/explanation` | WIRED (l10n ✓); live BLOCKED |
| Allergens (product) | scan/detail | — | `allergen/profiles` `GET /allergens/product/:id` | WIRED |
| Alternatives | `/alternatives/:ean` (ent) | — | `products` `GET /products/:ean/alternatives` | WIRED (l10n ✓) |
| Saved products | `/saved-products` | — | `saved-products` CRUD + `sync/saved-products` | WIRED+T |
| Dashboard catalog/product mgmt | — | (no dedicated products page found) | `products`, `public/products` | **DASHBOARD_MISSING?** verify in repair pass |

## B. Scanner, OCR & Audits
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Barcode scan / lookup | `/scan`, `/scan/result/:ean` | — | `scan`, `products` lookup | WIRED |
| Label OCR / fallback | `/scan/label` (ent) | — | `ai` label, `ocr/fallback` | WIRED |
| Bulk EAN audit | `/scan/audit` | `(dash)/audit`, `audit/ean-lists/*` proxies | `ean-lists` validate/import | WIRED (both clients) |
| Scan sessions | `/scan` batch | `audit/scan-sessions`, `audit/scan`, `audit/kpis` | `scan-sessions` | WIRED |
| Audit history / analytics | — | `(dash)/audit` + `audit/*` proxies | `scan-sessions`, `ean-lists` | WIRED (dashboard) |

## C. Expiry & Tasks
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Expiry list/create/delete | `/expiry`, `/expiry/new` | `(dash)/expiry` + `expiry/*` (kpis, calendar, thresholds, [id]/acknowledge) | expiry endpoints (`/expiry`, `/expiry/calendar`) + `consumer/expiry-calendar` | WIRED (both); ⚠️ **D3** dashboard `scope-change.test.tsx` type drift |
| Expiry calendar | `/expiry-calendar` | `expiry/calendar` proxy | `GET /expiry/calendar` | WIRED |
| Tasks list/create/detail/transition | `/tasks`, `/tasks/create`, `/tasks/:id` | `(dash)/tasks` + `tasks/*` ([id], transition, templates) | tasks endpoints (`/tasks` CRUD) | WIRED (both) |
| Task assignment / overdue | mobile detail | dashboard tasks | tasks | WIRED |

## D. Inventory & GRN
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Inventory list/item | `/inventory` (ent) | `(dash)/inventory` + `inventory/*` (kpis, low-stock, movements, [id]/min-stock) | `inventory` | WIRED (both) |
| Stock movement / adjust | `/inventory/stock-movement` | `inventory/movements` | `inventory/adjust` | WIRED |
| Low-stock alerts | `/inventory/low-stock-alerts` | `inventory/low-stock` | `inventory` (filter) | WIRED |
| GRN list/create/items/detail | `/grn`, `/grn/create`, `/grn/:id`, `/grn/:id/items` (ent) | `(dash)/grn`, `/grn/[id]` + `grn/*` (items, receive, kpis) | `grn` | WIRED (both) |
| GRN receive/post | mobile post | `grn/[id]/receive` | `grn` post | WIRED |

## E. Consumer Safety
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Allergen profile | `/allergens` (ent) | — | `allergen/profiles` GET/PUT `/allergens/profile/:userId` | WIRED |
| Recall alerts | `/recall-alerts` (ent) | (recall admin TBD) | `recall` `GET /recalls`, `/recalls/product/:id` | WIRED (mobile); dashboard recall admin **verify** |
| Shopping list | `/shopping-list` | — | `shopping-lists` CRUD | WIRED |
| Weekly digest | `/digest`, `/digest/:weekIso` | — | `GET /weekly-digest` | WIRED (l10n ✓) |
| Referrals | `/referrals` | — | `referrals` CRUD + redeem + me | WIRED |

## F. Subscription & Payments  ← repaired this sprint
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Plans | `/subscription` (subscriptionPlansProvider) | `billing/plans` proxy | `subscriptions` `GET /subscriptions/plans` | **WIRED+T** |
| Status / entitlements | entitlementProvider | `billing/subscription` | `GET /subscriptions/status` | **WIRED+T** (server-driven) |
| Usage | (provider) | `billing/usage` | `GET /subscriptions/usage` | WIRED |
| Checkout (UUID + cycle) | subscription_screen + CheckoutEngine | `billing/verify` | `payments` `POST /payments/checkout` (UUID planId) | **WIRED+T** (engine: external-wallet, pending, dup-guard) |
| Verify / webhook | verifyPayment | `billing/verify` | `POST /payments/verify`, `/payments/webhooks/razorpay` | WIRED+T (mock); **live test-mode BLOCKED_EXTERNAL** |
| Dashboard billing/invoices | — | `(dash)/billing`, `billing/invoices` | subscriptions/payments | WIRED (verify billing↔/subscriptions contract in repair) |

## G. Reports & OHS
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Dashboard summary / OHS | `/ohs` (ent advancedReports) | `(dash)` overview + `overview/*` (kpis, trends, health-score, multi-store, alerts, activity) | `dashboard` `GET /dashboard/summary` | WIRED (both) |
| Reports list/generate/export | `/reports` (ent) | `(dash)/reports` + `reports/*` ([id], export, files) | reports endpoints (`/reports` generate/export/download/scheduled CRUD) | WIRED (both) |
| Scheduled reports | mobile reports | `(dash)/reports/schedule` | reports schedule pause/resume/delete | WIRED |
| Analytics / leads (platform) | — | `(dash)/analytics`, `/analytics/compare`, `(dash)/leads` + `analytics/*` | `affiliate`/analytics, leads | WIRED (dashboard); ⚠️ **D2 fixed** (lead 'converted') |

## H. Profile, Settings, Support & Platform Admin
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| Profile | `/profile` | `(dash)/settings` + `settings/profile` | `users/me`, `api/v1/account` | WIRED |
| Language | `/settings/language` | `settings/language` | `PUT /user/language` | WIRED |
| Notification prefs | `/settings` | `(dash)/notifications` + `notifications/*` (preferences, read, read-all, test, broadcast) | `notifications` | WIRED (both) |
| Support / legal | `/support` | — | (links) | WIRED |
| Change password | — | `settings/change-password` | `auth`/account | WIRED (dashboard) |
| Tenant settings | (n/a) | `settings/tenant` | `tenants` `GET /tenants/:id` | **WIRED — D1 FIXED** (was `/tenants/undefined`) |
| Team / staff mgmt | — | `(dash)/settings/team` | `users/me`, `stores` | WIRED (dashboard) |
| Stores | `/select-store` | `(dash)/stores` + `stores` proxy | `stores` | WIRED (both) |
| Suppliers | — | `(dash)/suppliers`, `/suppliers/[id]` + suppliers proxies (performance, import) | `suppliers` | WIRED (dashboard-only — NOT_REQUIRED on mobile) |
| Admin: tenants/audit-logs/flags/webhooks/impersonation | — | `(dash)/admin/*` + `admin/*` proxies | `tenants`, `feature-flags`, `webhooks`, `admin/learn` | WIRED (admin role) |

## Auth, Tenancy & RBAC (cross-cutting — Phase 5)
| Function | Mobile | Dashboard | Backend | Status |
|---|---|---|---|---|
| OTP request/verify | `/auth/otp`, `/auth/otp/verify` | `(auth)/login`,`verify` (+ invite, reset) | `auth` otp/refresh/logout/me | WIRED+T (auth_flow_smoke; dashboard auth tests) |
| Session restore / refresh | bootstrap + Dio interceptor | `lib/auth/refresh-session` + middleware | `auth/refresh` | WIRED+T (both) |
| Tenant/store scoping | session.selectedStore | `session.user.tenantId` (D1) + store selector | TenantScopeGuard, tenant-scoped repos | WIRED; **live cross-tenant isolation BLOCKED_EXTERNAL** (needs backend) |
| Roles (owner/manager/staff/auditor/admin) | role gates + LockedFeature | `lib/permissions.ts` + nav-config | RolesGuard | WIRED+T (permissions.test, entitlement tests) |
| Entitlements | server `/subscriptions/status` | `billing/*` | subscriptions | **WIRED+T** (this sprint) |

---

## Cross-client contract notes (Phase 4)
- ✅ Both clients use **`/api/v1`** against the same backend.
- ✅ Mobile subscription contract corrected to **plural `/subscriptions/*`** + UUID checkout.
- ⚠️ **Verify dashboard `billing/*` proxies map to plural `/subscriptions/*` + `/payments/*`**
  (likely fine — backend is plural; confirm in the Subscription repair pass).
- ⚠️ **`NEXT_PUBLIC_DEMO_MODE`** in the dashboard is a mock-data path → must be gated off (or
  removed) for production so no fabricated metrics ship.
- ⚠️ Dashboard `suppliers`, `feature-flags`, `webhooks`, `tenants`, `analytics/leads`,
  `notifications/broadcast`, `admin/*` have **no mobile equivalent** → `NOT_REQUIRED` on mobile
  (dashboard-/admin-only), confirm backend support per page during repair.

## Known defects (open)
| ID | Layer | Item | Class |
|---|---|---|---|
| D1 | Dashboard | tenant-settings `/tenants/undefined` | **FIXED** (`session.user.tenantId`) |
| D2 | Dashboard | lead `'converted'` dead comparison | **FIXED** |
| D3 | Dashboard | `expiry/scope-change.test.tsx` `scope` type drift | OPEN (test-only; needs feature-intent decision) |
| D4 | Dashboard | `@playwright/test` not installed | OPEN (env: `npm i -D @playwright/test`) |
| L1 | Mobile | subscription/catalog strings English-only | OPEN (l10n across 6 ARB) |
| D5 | Backend | `InventoryModule` defined but never imported in `app.module.ts` → all `/inventory/*` 404 | **FIXED** (live-found; wired into AppModule) |
| D6 | Backend | `ClientDashboardModule` never imported → `/dashboard` (root, kpis, alerts, trends, team…) 404 | **FIXED** (wired into AppModule) |
| D7 | Backend | `consumer` role missing `products:read` → consumer catalog browse + `/products/lookup/:ean` 403 (core consumer flow; mobile tests use a fake ApiClient so never hit the real guard) | **FIXED** (`role-permissions.map.ts`) |
| D8 | Backend | `client-dashboard kpi.service` counted `products.is_active` (nonexistent column, not store-scoped) → `/dashboard` + `/dashboard/kpis` **500** | **FIXED** (rewrote to store-scoped `inventory_items.is_low_stock`) |
| D9 | Backend | Public `POST /tenants/onboard` self-service path does **not** call `startTrial`, so the tenant has no `tenant_subscriptions` row → `GET /subscriptions/status` 404. (Primary mobile path `business-activation` *does* call `startTrial`, so it's unaffected.) | **FIXED** (`TenantOnboardingService.onboard` now starts the trial post-commit via `SubscriptionsService.startTrial`, mirroring `business-activation`; `TenantsModule` imports `SubscriptionsModule`; non-fatal + logged on failure. Regression test wires real `TrialService`/`SubscriptionsService` and asserts onboard→`getStatus` is `trial`. **Pending product confirm:** whether `tenants/onboard` is the live marketing-site signup path or legacy/superseded by `business-activation`.) |

## Repair order (drives Phase 6) & gating
A Catalog ✅ (mobile done+tested) → B Scanner → C Expiry/Tasks → D Inventory/GRN →
E Consumer Safety → **F Subscription/Payments ✅ (mobile done+tested; live test-mode pending)** →
G Reports/OHS → H Profile/Settings/Platform.

**Backend live-verification: DONE (2026-06-14)** — all 8 domains + auth/RBAC return real
data/auth over HTTP (38/38; D5–D9 fixed). RBAC spot-checks pass live: consumer→`/inventory`
403, no-token→`/dashboard/summary` 401, consumer→catalog 200 after D7. **Still
`BLOCKED_EXTERNAL`:** mobile UI render (needs emulator), test-mode Razorpay payment
(needs emulator + keys), dashboard E2E (needs `@playwright/test`).
