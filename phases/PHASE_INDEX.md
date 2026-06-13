# RADHA Admin Dashboard — PHASE INDEX (master checklist)

> Single source of build order for the **RADHA Admin/Owner Dashboard** (private Next.js
> back-office web app consuming the NestJS backend at `/api/v1`).
> Source of truth = `ADMIN_DASHBOARD_DOCS/01_ARCHITECTURE_AND_API.md` (Doc 1),
> `02_DASHBOARD_UI_DESIGN.md` (Doc 2), `03_FUNCTIONS_AND_SECURITY_DESIGN.md` (Doc 3).
>
> **Location note:** there is no dashboard project on disk yet — only the docs. Phase 01
> scaffolds the Next.js app at the repo root in a new `radha_dashboard/` folder. All later
> phase paths are relative to `radha_dashboard/`.
>
> **Protocol:** I implement one phase only when told `execute phase <N>`, run its Verification,
> report the Acceptance checklist, and wait for `done` before advancing. Status boxes below are
> updated to `[x]` on `done`.

## Legend
- `[ ]` not started · `[~]` in progress · `[x]` done
- 🆕 = depends on PROPOSED backend (Doc 1 §8 / Doc 3 §A.4) — built behind a "needs backend" / locked state, never wired to a non-existent endpoint.

## Phases

| # | Title | Goal (1 line) | Covers (screens / functions) | Doc refs | Status |
|---|---|---|---|---|---|
| 01 | Project setup | Scaffold Next.js App Router + TS, RADHA tokens, shadcn/ui, fonts, security headers, env, folder tree | Project skeleton, `design/tokens.css`, `next.config` headers | D2 §2, §8 / D3 §B.6, §B.10 | [x] |
| 02 | Design-system primitives | Build the Doc 2 §4 component library + `/styleguide` page | KPI tile, data table, chart card, filter bar, status chip, OHS gauge, side panel, modal, form field, page header, empty/error/skeleton, toast, ⌘K palette | D2 §4, §2, §9 | [x] |
| 03 | Auth & session | httpOnly-cookie session, login/reset/invite, silent refresh, logout, middleware guard, RBAC helpers | `(auth)/login`, `/reset`, `useSession`, `can()/hasRole()`, `middleware.ts` | D1 §4 / D2 §5.14 / D3 §A.3.1, §B.2–B.3 | [x] |
| 04 | App shell & navigation | Adaptive sidebar + top bar, store switcher, date-range, ⌘K, role-gated nav, notifications bell | `(dash)/layout.tsx`, shell components | D2 §3, §3.1 | [x] |
| 05 | API client layer | Typed `lib/api/*` per domain, `apiFetch` (auth/401-refresh/x-request-id/error-norm), Zod schemas, TanStack Query | HTTP layer, schemas, query provider | D1 §2.4, §6 / D3 §A.1–A.2, §A.5, §B.4 | [x] |
| 06 | Overview / Command Centre | KPIs, alerts, quick-actions, trends, team, activity, OHS gauge, multi-store rollup | `/` Overview | D1 §6.1, §7.1 / D2 §5.1 | [x] |
| 07 | Expiry module | Expiry KPIs, calendar heat grid, records table, thresholds editor, alert ack/resolve | `/expiry` | D1 §6.8, §7.2 / D2 §5.3 | [x] |
| 08 | Tasks module | Kanban + table, create/templates, workflow transitions, evidence, auto-from-alert | `/tasks` | D1 §6.9 / D2 §5.4 | [x] |
| 09 | Inventory + GRN | Inventory KPIs/movements/low-stock + stock ops; GRN list/detail/line-items/workflow | `/inventory`, `/grn` | D1 §6.10–6.11, §7.4 / D2 §5.5–5.6 | [x] |
| 10 | Suppliers | Table, search, import/export, contacts, performance, status actions | `/suppliers` | D1 §6.12 / D2 §5.7 | [x] |
| 11 | Audit / EAN + scan sessions | Lists, activate/deactivate, import wizard + error report, items, match-rate, scan sessions | `/audit` | D1 §6.6–6.7, §7.3 / D2 §5.8 | [x] |
| 12 | Reports + exports | Report builder, export job polling, artefact list, presigned download, re-export | `/reports` | D1 §6.13 / D2 §5.9 / D3 §B.7 | [x] |
| 13 | Analytics + Leads | Website stats/funnel, tenant activity; leads pipeline + convert | `/analytics`, `/leads` | D1 §6.15 / D2 §5.10 | [x] |
| 14 | Billing + payments | Plan + usage, plan picker, Razorpay checkout/verify, refund (step-up) | `/billing` | D1 §6.14, §7.5 / D2 §5.11 / D3 §B.5, §B.7 | [x] |
| 15 | Notifications | Inbox, preferences, mark read, test send | `/notifications` | D1 §6.17 / D2 §5.12 | [x] |
| 16 | Admin console | Impersonation (step-up + banner + audit), feature flags read, webhooks CRUD/deliveries/replay | `/admin/*` (admin role) | D1 §6.16, §6.18 / D2 §5.13 / D3 §B.7 | [x] |
| 17 | Settings + profile + language | Profile, language, security (password change), tenant info | `/settings` | D2 §5.14 / D1 §4 | [x] |
| 18 | 🆕 PROPOSED enterprise features | Gated "needs backend": user/team mgmt, audit-log viewer, saved views/alert rules, scheduled reports, cross-store compare, platform-admin console, broadcasts, billing back-office, bulk ops + undo, global search | Locked/empty-state surfaces | D1 §8 / D3 §A.4 | [x] |
| 19 | Hardening | Full a11y pass, dark mode, responsive/mobile, performance, security review, anti-slop gate | Cross-cutting | D2 §2.2, §7, §9 / D3 Part C | [x] |
| 20 | Final QA + handover | Per-role end-to-end click-through, fix list, statuses, README | Cross-cutting | D1 §5.3 / D3 Part C | [x] |

## Build philosophy
Foundations first (01–05) → visible value (06–17) → proposed/gated (18) → polish (19–20).
Each phase leaves the app compiling and running. No phase wires UI to a non-existent endpoint.
