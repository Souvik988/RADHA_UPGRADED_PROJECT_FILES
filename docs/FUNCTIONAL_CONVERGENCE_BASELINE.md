# RADHA — Functional Convergence Baseline (Phase 2)

Results recorded **before** any repair this phase. Failures are reported, not hidden.

## Mobile (`apps/mobile`, package `radha_mobile`) — canonical worktree
| Gate | Result |
|---|---|
| Flutter / Dart | 3.44.0 / 3.12.0 |
| `flutter analyze --fatal-infos` | ✅ clean |
| `flutter test` | ✅ **227 passing** (45 files) |
| `dart run build_runner build` | ✅ clean |
| `flutter build apk --debug` | ✅ success (214 MB debug) |
| `flutter build web --release` | ⛔ N/A — not web-configured |

## Dashboard (`radha_dashboard`, Next.js 15.3 + React 19) — export tree
| Gate | Result |
|---|---|
| `node_modules` | ✅ present (no install needed) |
| `npm run test` (vitest) | ✅ **155 passing / 26 files** |
| `npm run typecheck` (`tsc --noEmit`) | ⚠️ **fails — pre-existing errors (below)** |
| `npm run lint` / `npm run build` | not yet run this phase |

### Recorded typecheck defects (pre-existing — predate this work)
| # | File | Error | Class |
|---|---|---|---|
| D1 | `app/api/settings/tenant/route.ts:17` | `Property 'tenantId' does not exist on type 'SessionPayload'` | P1 (auth/tenancy type) |
| D2 | `features/analytics/components/lead-detail-panel.tsx:98` | status union has no `'converted'` member (dead comparison) | P2 (analytics enum) |
| D3 | `features/expiry/scope-change.test.tsx:75` | test references `scope` not on the expiry type | P2 (test/type drift) |
| D4 | `tests/perf/navigation.spec.ts` (×4) | `Cannot find module '@playwright/test'` | P2 (E2E dep not installed) |

## Backend (`server`, NestJS) — canonical
| Gate | Result |
|---|---|
| `server/node_modules` | ⛔ **absent** — deps not installed |
| `pnpm install` / `pnpm test` | ⛔ not run (no deps; mobile/dashboard changes don't touch backend; was 2059/2059 per CLAUDE.md) |
| Backend running (`:3000`) | ⛔ not running — **all live cross-client/E2E/payment flows blocked here** |

## Environment limitations (blockers — work continues around them)
- **No backend running** → no live dashboard/mobile end-to-end, no test-mode Razorpay, no
  cross-client sync verification. Unblock: Docker (PG 5433 / Redis 6380) + `pnpm install`
  + `pnpm server:dev`.
- **No emulator/device** (`mobile_list_available_devices` empty; SDK emulator not at default
  path) → no live Android / Mobile-MCP exploratory run.
- **`@playwright/test` not installed** → dashboard browser E2E blocked until `npm i -D @playwright/test && npx playwright install`.

## Verification posture
Mobile + dashboard **unit/component/integration suites are the authoritative automated
evidence here** (227 + 155 = 382 tests green, minus the recorded dashboard typecheck
defects). Live/E2E/payment/sync are environment-gated and explicitly marked
`BLOCKED_EXTERNAL` in the master matrix.
