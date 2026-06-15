# RADHA — Evidence Ledger

> Every completion claim must trace to a class of evidence. **No assumption may be upgraded to verified
> without evidence.** Classes: `VERIFIED_CODE` (read the code), `VERIFIED_AUTOMATED` (test/gate run this
> program), `VERIFIED_LIVE_API` (hit the running backend), `VERIFIED_ANDROID` (device/emulator),
> `VERIFIED_BROWSER` (dashboard in a real browser), `VERIFIED_PAYMENT`, `VERIFIED_STAGING`, `ASSUMED`
> (carried from prior reports, not re-checked), `EXTERNAL_BLOCKED`, `NOT_REQUIRED`.

Branch `codex/radha-final-convergence` @ `4bf72ee`. Ledger opened 2026-06-15.

## Re-verified THIS program turn (present evidence)
| Claim | Class | Evidence |
|---|---|---|
| Git identity = Souvik988/RADHA_UPGRADED_PROJECT_FILES, branch final-convergence @ 4bf72ee, pushed | VERIFIED_CODE | `git status/branch -avv/rev-parse` 2026-06-15 |
| Branch builds on the prior executive handoff (83e9a8e) + product-detail/profile/select-store l10n | VERIFIED_CODE | `git log --oneline` lineage |
| API contract drift gate passes (zero unexplained drift) | VERIFIED_AUTOMATED | `node tools/generate-api-contract-matrix.mjs --check` → "drift gate passed", exit 0 |
| Flutter analyze --fatal-infos clean | VERIFIED_AUTOMATED | `flutter analyze --fatal-infos` → "No issues found!" (2026-06-15, 34.9s) |
| Flutter test suite = 243 passing | VERIFIED_AUTOMATED | `flutter test` → "+243: All tests passed!" (2026-06-15, ~2min) |
| Safety bundle + working patch created | VERIFIED_AUTOMATED | `../radha-program-safety.bundle`, `../radha-program-working.patch` |
| Mobile localization is PARTIAL (19/63 feature files use l10n; ~19 screens still English) — corrects the "Product Detail localized" claim (that was only `features/catalog/`) | VERIFIED_CODE | grep over `lib/features` 2026-06-15 → defect D10; scorecard H 50%→30% |
| Razorpay FULL server-side payment flow live-verified (order→verify→activate→idempotency→bad-sig reject) | VERIFIED_PAYMENT | owner's real test keys in active server/.env; "Razorpay provider resolved: live". (1) `POST /payments/checkout` → 200 real `order_…` (₹49/4900p). (2) `POST /payments/verify` with a valid HMAC-SHA256(order\|payment, secret) → 200 ok=true, order **captured**, plan starter. (3) `GET /subscriptions/status` → **active / isActive / starter** (entitlement activated, trial→active). (4) verify replay → 200 idempotent. (5) verify with BAD signature → **502 rejected** (security gate). 2026-06-15. **Still NOT verified (needs device + webhook secret):** the actual Razorpay checkout SHEET on Android, and webhook signature path (`RAZORPAY_WEBHOOK_SECRET` empty). |
| Product browse works end-to-end live; catalog enriched 2→11 real products (nutrition + health) | VERIFIED_LIVE_API | `db:import:curated` → `catalog.curated.complete productsUpserted=9` (cumulative 11); live probe `/catalog/products` → 11 items, 11 with health+EAN, `/products/lookup/:ean` → found=true w/ nutrition (2026-06-15). Mobile browse wiring verified VERIFIED_CODE (merge bundled+server, lookup on tap). D11 = bundled-card EAN linking + seed step still open. |

## Carried from prior reports — NOT re-verified this turn (treat as ASSUMED until re-run)
| Claim | Class | Note |
|---|---|---|
| 41 focused backend tests pass | ASSUMED | re-run `pnpm --filter @radha/server test` (targeted) on this branch |
| ~~Server build passes~~ → **VERIFIED_AUTOMATED** | VERIFIED_AUTOMATED | `pnpm build` (shared-types + nest build + tsc-alias) → exit 0 (2026-06-15) |
| 38/38 representative backend endpoints live-verified ON THIS BRANCH | **VERIFIED_LIVE_API** | rebuilt dist + `node dist/main.api` (health 200) + live sweep `radha-verify.mjs` → "PASS 38 / 38" incl. D9 status=trial (2026-06-15) |
| Dashboard 155 vitest pass | ASSUMED | on the export worktree; re-run there |

## EXTERNAL_BLOCKED (cannot be VERIFIED in this environment — owner/credential dependent)
| Item | Class | Unblock requirement |
|---|---|---|
| Android native journeys, camera/scan/OCR, process death, deep links | EXTERNAL_BLOCKED | an Android emulator or device attached (`adb`) |
| Razorpay live test-mode end-to-end (checkout→verify→webhook→entitlement) | EXTERNAL_BLOCKED | owner Razorpay TEST keys + a device |
| Dashboard Playwright E2E live journeys | EXTERNAL_BLOCKED | `@playwright/test` install + a runnable dashboard + backend |
| Cross-client sync proven live | EXTERNAL_BLOCKED | device + dashboard + backend running together |
| AWS staging, RDS/ElastiCache/S3/CloudFront/KMS, backup/restore, rollback | EXTERNAL_BLOCKED | owner AWS account + approval (financial) |
| Production tenant KMS encryption | EXTERNAL_BLOCKED (design VERIFIED_CODE-able now) | a KMS endpoint (real or localstack) |
| Performance/load measurements | EXTERNAL_BLOCKED (mobile profile runs need a device; backend load needs staging) | device + staging |

## Rule of this ledger
A line graduates from ASSUMED → VERIFIED_* only when this program runs the check and records the command
+ result here. The FINAL_COMPLETION_REPORT may cite only VERIFIED_* lines for completion claims.
