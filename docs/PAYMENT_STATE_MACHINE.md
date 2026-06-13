# RADHA — Payment State Machine

How a subscription purchase flows on mobile, end to end. Implemented in
`apps/mobile/lib/features/subscription/payment/` and driven from
`subscription_screen.dart`. Verified with mocked HTTP + a fake Razorpay adapter
(no native plugin, no live backend) — **no live-payment claim is made here**.

## Components
| File | Role |
|---|---|
| `payment/checkout_models.dart` | sealed `CheckoutResult`, normalised `Rp*` event types, `PaymentPhase`, `kRazorpayCancelledCode` |
| `payment/razorpay_adapter.dart` | `RazorpayAdapter` interface + `FlutterRazorpayAdapter` (the only file touching `razorpay_flutter`) |
| `payment/checkout_engine.dart` | `CheckoutEngine.run({planId, billingCycle})` — the state machine |
| `subscription_screen.dart` | plans UI + `checkoutEngineProvider` + result handling + entitlement refresh |

## Phases
```
idle → creatingOrder → openingCheckout → awaitingTerminalEvent → verifying → verified
                                              │                         │
                              externalWallet ─┘ (NOT terminal)          ├→ verificationFailed
                              cancelled / paymentFailed / timedOut      └→ pendingConfirmation
```

## Flow
1. **Guard inputs.** `planId` must be a UUID v4 (a plan *code* is rejected before any
   network call — kills the code-as-UUID regression); `billingCycle ∈ {monthly, yearly}`.
2. **creatingOrder** → `POST /api/v1/payments/checkout {planId: UUID, billingCycle}`.
   Failure → `CheckoutFailed(create_order)`.
3. **Validate the response** before opening the sheet: `keyId` non-empty, `razorpayOrderId`
   non-empty, `amountPaise > 0`, `currency == INR`. Failure → `CheckoutFailed(invalid_checkout)`.
4. **openingCheckout** → `adapter.open(options)` (key from the server response — never
   compiled in). **awaitingTerminalEvent.**
5. Terminal handling (first event wins; a duplicate never triggers a second verify):
   - **external wallet** → *not terminal*; keep awaiting the real success/error.
   - **error, code 2** → `CheckoutCancelled` (user dismissed).
   - **error, other** → `CheckoutFailed(provider)`.
   - **success** → **verifying** → `POST /api/v1/payments/verify`:
     - `success: true` → `CheckoutVerified(status)`.
     - `success: false` (server reached, signature rejected) → `CheckoutFailed(verification)`.
     - verify **throws** (server unreachable after a provider success) → `CheckoutPending`
       (money may have moved — never "failed"; carries a no-PII support ref).
   - **no event before timeout** (default 5 min) → `CheckoutFailed(timeout)`.
6. Always `adapter.dispose()`.

## Screen reaction (`subscription_screen.dart`)
- `CheckoutVerified` → `entitlementController.refresh()` (silent, preserves last good
  state on failure), medium-impact haptic, "You're on <plan>" success.
- `CheckoutCancelled` → "unchanged" snackbar; plan/cycle preserved for retry.
- `CheckoutPending` → "Payment received — confirming. Ref … Pull to refresh." recovery.
- `CheckoutFailed` → contained error snackbar; the rest of the screen is intact.

Features unlock **only** after server-verified `refresh()` confirms the new plan —
never from the client callback alone. Webhook + verify are idempotent server-side
(`payment_webhooks_inbox`), so duplicate provider callbacks are safe; the client also
latches the first terminal event.

## Tests
- `test/features/subscription/checkout_engine_test.dart` — 14 cases (all branches above).
- `test/features/subscription/subscription_screen_test.dart` — 3 cases incl. the
  **UUID-not-code** regression guard and billing-cycle propagation.

## Not yet validated (honest)
- A real **test-mode end-to-end** run (your `.env` Razorpay test keys + a running backend)
  has not been executed here. The engine is built to work against that backend; run it on a
  device/emulator with the API up to confirm the live path before any production claim.
