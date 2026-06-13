# PHASE 14 — Billing + payments

## Goal
Build the Billing screen: current plan + usage, the plan picker (upgrade/cancel/reactivate),
Razorpay checkout with server-side verify, and the refund action with step-up confirm.

## Depends on
Phases 02, 04, 05.

## Doc references
- Doc 1 §6.14 (`/subscriptions/*`, `/payments/*`), §7.5 (billing lifecycle).
- Doc 2 §5.11 (Billing spec), §6 (usage donut).
- Doc 3 §A.3.10 (billing functions), §B.5 (Razorpay verify on server, webhook is source of truth),
  §B.7 (refund step-up + confirm + audit).

## Scope (in)
- `app/(dash)/billing/page.tsx` — plan + usage + plan picker + (admin/owner) refund.
- `features/billing/billing.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components: `current-plan.tsx` (`/subscriptions/status`), `usage-cards.tsx` (`/subscriptions/usage`,
  donut ≤5), `plan-picker.tsx` (`/subscriptions/plans` → upgrade/cancel/reactivate),
  `checkout.tsx` (Razorpay: `/payments/checkout` → client SDK → server `/payments/verify`),
  `refund-panel.tsx` (`/payments/refund`, admin/owner, step-up confirm with amount + reason).

## Out of scope
Invoice history / transaction ledger (🆕, Phase 18). Changing plan definitions. Trusting client-side
payment success (webhook is the backend source of truth).

## Step-by-step
1. Current plan + usage cards (mono money/usage, donut). Trial/active/expired states.
2. Plan picker from `/subscriptions/plans`; upgrade → `/payments/checkout` → Razorpay SDK → on
   callback `/payments/verify` **server-side**; cancel/reactivate with confirm.
3. Refund panel (admin/owner): step-up confirm dialog (re-auth) showing amount + reason → `/payments/refund`; audited.
4. States: skeleton cards, empty ("No active subscription"), error retry, payment pending/failed,
   locked where applicable. Verify.

## API wiring
- `GET /subscriptions/plans` (public), `/subscriptions/status`, `/usage`.
- `POST /subscriptions/upgrade|cancel|reactivate`.
- `POST /payments/checkout` (create order), `POST /payments/verify` (server signature verify),
  `POST /payments/refund` (admin/owner). Webhook `POST /payments/webhooks/razorpay` is backend-only.

## Design spec
- Doc 2 §5.11. Plan cards with one orange "Upgrade" CTA (one per region). Usage donut ≤5 cats. Mono
  money/dates. Refund dialog uses danger CTA separated from cancel.

## Security checks (Doc 3 §B.5, §B.7)
- Payment verification happens **server-side** (`/payments/verify`); never trust client success alone;
  webhook is source of truth. Razorpay key handling: only public key client-side, secrets server-side.
- Refund = admin/owner only + step-up re-auth confirm (amount + reason) + audited.
- Plan changes = sensitive → confirm. Tenant scope on all calls.

## Acceptance criteria
- [ ] Plan + usage render; plan picker upgrade/cancel/reactivate work with confirm.
- [ ] Checkout creates an order and verifies server-side; failure handled gracefully.
- [ ] Refund gated to admin/owner with step-up confirm + audit.
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User (TEST/mock Razorpay): view plan + usage, run an upgrade checkout (verify server-side), attempt
  a refund as owner (step-up confirm) and confirm a manager cannot.

## Rollback note
Additive under `features/billing/` + the page. No shared-layer/backend changes.
