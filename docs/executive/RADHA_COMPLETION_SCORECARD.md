# RADHA — Completion Scorecard (calculated, not chosen)

> Score is computed from the weighted categories in the executive directive §4. Rules: code presence
> alone ≤ 50% of an item; automated tests ≤ 75%; live/API/browser/device evidence required for 90%+;
> staging/production operational evidence required for 100%. **As of 2026-06-15 / commit `4bf72ee`.**

| # | Category | Weight | Scope | Done | Verified | Item % | Weighted | Confidence | Primary evidence |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| A | Backend architecture & domain correctness | 15% | — | — | — | **80%** | 12.0 | High (functional) / Low (scale) | feature-complete build; 38/38 live sweep (prior); contracts PASS |
| B | Mobile product functionality | 15% | 8 domains | most | automated only | **70%** | 10.5 | Medium | 243 flutter tests; no device run |
| C | Mobile/backend contract correctness | 10% | — | — | automated+live | **85%** | 8.5 | High | `contracts:check` PASS (re-run); 38/38 live |
| D | Dashboard functionality & convergence | 10% | 13 pages | partial | vitest only | **55%** | 5.5 | Medium | 155 vitest; no Playwright/live/port |
| E | Automated QA & regression | 8% | — | — | automated | **80%** | 6.4 | High | flutter+backend+vitest+contracts gates |
| F | Android native/live verification | 8% | critical journeys | none | none | **15%** | 1.2 | Low | no device this session (EXTERNAL) |
| G | Cross-client synchronisation | 6% | 12 flows | none proven | none | **20%** | 1.2 | Low | logic present; not proven live |
| H | Localization & accessibility | 6% | 6 locales + a11y | l10n PARTIAL (19/63 files) | automated | **30%** | 1.8 | Medium | DISCOVER 2026-06-15: ~19 screens still hardcoded English (D10); a11y unaudited |
| I | Payment & subscription validation | 5% | test-mode matrix | engine+contract | automated mock | **50%** | 2.5 | Medium | CheckoutEngine + structured results; no live test-mode |
| J | Security, privacy & compliance | 6% | MASVS+privacy+KMS | seeds exist | none | **15%** | 0.9 | Low | AES service seed; no KMS/MASVS/data-inventory |
| K | Observability & operations | 4% | mobile+backend | partial | none | **20%** | 0.8 | Low | Sentry/Terminus hooks; SLOs not proven |
| L | Performance & scale evidence | 4% | budgets+load | none | none | **10%** | 0.4 | Low | no load/profile measurements |
| M | Deployment, backup & recovery | 3% | staging+restore | runbook | none | **5%** | 0.15 | Low | DEPLOY_AWS.md exists; nothing deployed |
| | **TOTAL** | **100%** | | | | | **≈ 51.8%** | **Medium** | |

> Adjusted down from 53.0% → 51.8% on 2026-06-15 after DISCOVER found mobile localization materially
> incomplete (H: 50%→30%, defect D10). Backend live 38/38, server build, contracts, flutter
> analyze/test were independently RE-VERIFIED on this branch the same day (confidence ↑, value unchanged).

## What this number means (honest reading)
- The **functional/automated core is strong** (A,B,C,E ≈ 12+10.5+8.5+6.4 = 37.4 of a possible 48).
- The **release-readiness half is largely unproven** (F,G,I,J,K,L,M ≈ 7.15 of a possible 36) — Android
  native, cross-client, live payment, security/privacy, observability, performance, and deployment all
  need real evidence this program has not yet produced.
- **Do not round up.** 53% is the calculated truth. It rises only as VERIFIED_LIVE / VERIFIED_ANDROID /
  VERIFIED_STAGING evidence lands in the EVIDENCE_LEDGER — not from more code or docs.

## Path of biggest score gains (where to spend effort)
1. **F + G** (14% weight): an Android device + cross-client live runs would move ~12 points.
2. **D** (10%): dashboard Playwright + live login + port → ~+4.5.
3. **J** (6%): tenant KMS encryption + MASVS matrix + data inventory → ~+4.5.
4. **I** (5%): Razorpay test-mode end-to-end (needs keys + device) → ~+2.5.
