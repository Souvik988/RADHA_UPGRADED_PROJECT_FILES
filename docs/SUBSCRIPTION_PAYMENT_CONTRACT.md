# RADHA — Subscription & Payment Contract (verified from `server/`)

Source of truth = the canonical backend controllers/DTOs on `origin/main`. This document
grounds the mobile repair (sprint Phases 4–7). **Verified by reading the code**, not docs.

## Backend endpoints (real)

### Subscriptions — `@Controller('subscriptions')` → `/api/v1/subscriptions/*`
| Method | Path | Auth | Body | Notes |
|---|---|---|---|---|
| GET | `/plans` | **Public** | — | `service.listPlans(false)` — public plans |
| GET | `/status` | Bearer + tenant (owner/manager/staff/auditor/admin) | — | current subscription status |
| GET | `/usage` | Bearer + tenant (owner/manager/admin) | — | usage stats |
| POST | `/upgrade` | Bearer + tenant (owner/admin) | `{ planCode }` | `UpgradePlanSchema`; uses **planCode**, not UUID |
| POST | `/cancel` | Bearer + tenant (owner/admin) | `{ reason }` | graceful — cancel at period end |
| POST | `/reactivate` | Bearer + tenant (owner/admin) | — | reactivate cancelled sub |

### Payments — `@Controller('payments')` → `/api/v1/payments/*` (Razorpay, BE-28 v2)
| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| POST | `/checkout` | Bearer | `{ planId: UUIDv4, billingCycle: 'monthly'\|'yearly' }` | `CheckoutResult` (below) |
| POST | `/verify` | Bearer | `VerifyPaymentDto` (HMAC fields) | `VerifyPaymentResult` |
| POST | `/refund` | Bearer + admin/owner | `RefundDto` | `RefundResult` |
| POST | `/webhooks/razorpay` | **Public + HMAC** | raw body | idempotent via `payment_webhooks_inbox` (unique `event_id`; `{duplicate:true}` on retry) |

**`CheckoutResult`** (exact): `{ razorpayOrderId, keyId, amountPaise:int, currency:'INR',
prefill:{name,email,contact}, notes }`.

## Critical mobile↔backend mismatches (the defects to fix)

1. **Singular vs plural.** Flutter `api_client.dart` declares `GET/POST /api/v1/subscription`
   (singular). Backend exposes **`/api/v1/subscriptions/{plans,status,usage,upgrade,cancel,
   reactivate}`** (plural). → Client calls will 404. **Fix:** add the 6 plural methods,
   migrate callers, deprecate the singular pair.

2. **planId must be a UUID.** `CheckoutSchema = z.object({ planId: z.string().uuid(), … })`
   and `@IsUUID('4')`. The Flutter screen sends string plan **codes** (`basic`/`standard`/
   `premium`) as `planId` → backend returns 400 *"planId must be a valid UUID"*. **Fix:**
   fetch plans from `GET /subscriptions/plans`, carry the backend **UUID `id`** on each
   plan model, send that UUID to `/payments/checkout`. (Note the asymmetry: `/subscriptions/
   upgrade` takes `planCode`, but `/payments/checkout` takes the UUID `planId` — keep both
   fields on the plan model.)

3. **billingCycle is required & explicit.** `/checkout` requires `'monthly'|'yearly'`. The
   UI must pass the user-selected cycle explicitly (not a default).

4. **Validate `CheckoutResult` before opening Razorpay** (Phase 6): assert `keyId`
   non-empty, `razorpayOrderId` non-empty, `amountPaise > 0`, `currency == 'INR'`.

5. **Verification is server-authoritative.** Never unlock features from the Razorpay client
   callback alone — POST `/payments/verify`, then refresh `/subscriptions/status` + entitlements
   and confirm the active plan before showing success. Webhook + verify are idempotent on
   the backend (`payment_webhooks_inbox`), so duplicate callbacks are safe server-side; the
   client must still guard against duplicate terminal callbacks and premature
   external-wallet completion.

6. **Entitlements from server, not a hardcoded map.** `/subscriptions/status` (+ `/usage`)
   is the source of truth for features/limits/usage/plan/trial/renewal. A local map may only
   supply presentation metadata (label/icon/order/marketing). It must **not** decide access.

## Plans (per CLAUDE.md product spec — confirm against `/plans` at runtime)
3-month trial; ₹49 / ₹99 / ₹199 tiers. **Do not hardcode prices as the payment source of
truth** — fetch from `/subscriptions/plans`; the UI may cache the last good list for
resilience but checkout must use the backend UUID + backend amount.

## Mobile repair plan (Phases 4–7, staged)
1. **api_client:** add `getPlans()`, `getSubscriptionStatus()`, `getUsage()`,
   `upgrade({planCode})`, `cancelSubscription({reason})`, `reactivate()`; keep
   `createCheckout({planId:UUID, billingCycle})` + `verifyPayment(...)`. Regenerate Retrofit.
   Deprecate singular `/subscription` after callers migrate.
2. **DTOs:** `PlanDto{id:UUID, code, name, description, monthlyPaise, yearlyPaise, currency,
   features[], limits, active, displayOrder}`, `SubscriptionStatusDto{isActive, status, plan,
   trialDaysRemaining, daysUntilRenewal, features, limits, usage, cancelAtPeriodEnd}` — from
   the real `/status` JSON (capture a sample in a fixture test).
3. **CheckoutResult DTO** to match the server shape above; validate before opening Razorpay.
4. **Razorpay state machine** (`idle→creatingOrder→openingCheckout→awaitingTerminalEvent→
   verifying→verified|cancelled|paymentFailed|verificationFailed|pendingConfirmation`),
   injectable payment adapter (mock in tests), single terminal callback, external-wallet not
   terminal, `CheckoutResult` sealed union.
5. **Entitlement provider** consumes `/status`; refresh after verify; unknown feature keys
   logged-once + denied (never auto-granted).
6. **Tests:** mocked-HTTP contract tests for the exact paths/payloads (catch singular↔plural
   and code-as-UUID regressions); widget tests for the payment states; **never instantiate
   the native Razorpay plugin** in widget tests.

## Honesty / blockers
- **No live Razorpay run is possible here** (no test-mode keys / device). Verification is
  via mocked HTTP + an injectable payment adapter. **No "live-payment ready" claim** will be
  made without a real test-mode end-to-end run.
- Exact `/status`, `/usage`, `VerifyPaymentDto`, plan-row JSON shapes must be captured from
  the backend (read `subscriptions.service.ts` + `plans` repository + `verify-payment.dto`)
  when implementing — this doc fixes the route/auth/planId-UUID contract; field-level DTOs
  are finalized at implementation against those files + Razorpay test fixtures.
