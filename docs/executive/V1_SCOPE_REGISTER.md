# RADHA — V1 Scope Register (frozen)

> Scope is frozen for the release candidate. Each item: `V1_REQUIRED` | `V1_OPTIONAL` | `V2_DEFERRED` |
> `NOT_REQUIRED` | `LEGAL_REVIEW` | `OWNER_DECISION_REQUIRED`. No scope creep while core completion is
> open. Frozen 2026-06-15 @ `4bf72ee`.

## V1_REQUIRED — the promised product domains (must reach release gate)
| Domain | Class | Notes |
|---|---|---|
| Authentication & onboarding (OTP, segment, session) | V1_REQUIRED | live-verified earlier |
| Tenant / store selection & scoping | V1_REQUIRED | RBAC + TenantScopeGuard |
| Catalog & search | V1_REQUIRED | consumer-accessible; localized |
| Product Detail (nutrition/health/insights, gated) | V1_REQUIRED | localized this branch |
| Barcode scan | V1_REQUIRED | needs Android native verification |
| Label OCR | V1_REQUIRED | needs Android native verification |
| Bulk audit (EAN lists / scan sessions) | V1_REQUIRED | — |
| Expiry | V1_REQUIRED | — |
| Tasks | V1_REQUIRED | — |
| Inventory | V1_REQUIRED | module wired (D5 fixed) |
| GRN | V1_REQUIRED | — |
| Consumer safety (allergens, recalls, saved, shopping list, digest, referrals) | V1_REQUIRED | recall is tenant-scoped by design |
| Subscriptions | V1_REQUIRED | server-driven plans/entitlements |
| Payments (Razorpay TEST mode) | V1_REQUIRED | live test-mode EXTERNAL_BLOCKED |
| Reports | V1_REQUIRED | — |
| OHS (operational health score) | V1_REQUIRED | — |
| Profile / settings / notifications / support / legal | V1_REQUIRED | profile localized this branch |
| Existing owner dashboard (radha_dashboard) | V1_REQUIRED | converge, do NOT rebuild |

## V1_REQUIRED — cross-cutting release gates
| Gate | Class |
|---|---|
| Six-locale localization parity + completeness | V1_REQUIRED |
| Accessibility (mobile semantics + dashboard WCAG 2.2 AA critical) | V1_REQUIRED |
| Tenant data privacy + per-tenant encryption (KMS) | V1_REQUIRED · partly OWNER_DECISION_REQUIRED (KMS infra) |
| Observability (Sentry/Pino/health/SLO) | V1_REQUIRED |
| Performance budgets (measured) | V1_REQUIRED |
| AWS staging + backup/restore + rollback | V1_REQUIRED · OWNER_DECISION_REQUIRED (AWS cost) |
| CI/CD + supply-chain gates | V1_REQUIRED |

## Explicit V1 NON-GOALS (do not build)
`NOT_REQUIRED`: Full POS · GST invoicing · Sales ledger · Full accounting · Printer workflows ·
Consumer retail checkout.

## LEGAL_REVIEW / OWNER_DECISION_REQUIRED (cannot be closed by engineering alone)
- Privacy notice, consent flows, DPDP-Act mapping, retention/deletion legal basis → `LEGAL_REVIEW`.
- Razorpay production credentials; AWS account + financial provisioning; data-safety declaration;
  store listing; closed-beta go/no-go → `OWNER_DECISION_REQUIRED` (see OWNER_ACTIONS_REQUIRED.md).

## V2_DEFERRED (record so they are not re-litigated as creep)
Real-time push sync (vs. invalidation+refetch), marketing website build-out, advanced analytics
beyond V1 leads, multi-currency, non-food/pharmacy ruleset expansion beyond what exists.
