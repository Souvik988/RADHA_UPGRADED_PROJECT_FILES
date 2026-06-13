# RADHA Admin Dashboard — Master Doc 2/3

## Full UI / UX Design System (Next.js, app-like vibe)

> **Scope.** The complete visual + interaction design for the **RADHA Admin/Owner
> Dashboard** web app (Next.js). It adapts RADHA's mobile **Visual System Bible**
> (warm cream + burnt-orange, editorial, content-heavy-but-breathing) into a
> **desktop back-office** that still feels like *one product* with the Flutter app —
> not a generic admin template. Every screen here maps to the APIs in Doc 1.
>
> **North star:** a back-office a Gujarat retail owner is *proud* to run their
> business from — merchandised, glanceable, alive, unmistakably RADHA-warm. Beat
> the polish of Linear / Vercel / Stripe dashboards, but in RADHA's warm palette.

---

## 1. Design principles (web back-office)

1. **Same soul, different body.** Reuse the mobile brand tokens (§2) verbatim.
   The dashboard is the desktop sibling of the app: warm cream canvas, one
   confident orange, editorial eyebrow labels, mono numbers, soft warm shadows.
2. **Density is a feature; clutter is the enemy.** Back-office users want a lot on
   screen. Achieve density with a strict 12-col grid, generous *internal* padding,
   clear section eyebrows, and **one focal point per region**. Big breaths between
   zones (`32–48px`).
3. **One primary action per region.** Exactly one orange CTA per zone. Everything
   else is subordinate (ghost/secondary).
4. **Numbers are the plot.** KPIs, money, dates, EANs, counts → JetBrains Mono,
   tabular figures, count-up on first reveal.
5. **Every state is designed.** loading (skeleton) · empty (with personality) ·
   error (with retry) · locked (paid, blurred-value) · offline. Never a raw spinner.
6. **Accessible by default.** 4.5:1 contrast, visible focus rings (orange), full
   keyboard nav, `aria-sort` on tables, reduced-motion honored.

---

## 2. Brand tokens (locked — identical to the mobile bible)

### 2.1 Color

| Token | Hex | Role |
|---|---|---|
| `--accent` | `#EA580C` | Primary CTA, active nav, focus ring, gauge fill, brand mark |
| `--accent-deep` | `#9A3412` | Pressed CTA, eyebrow headers, dark-surface accent |
| `--accent-tint` | `#FED7AA` | Soft badges, chips, hover wells |
| `--ink` | `#1C1917` | Primary text (never pure black) |
| `--ink-soft` | `#57534E` | Secondary text, captions |
| `--surface` | `#FFFBF5` | App canvas — warm cream, never flat white |
| `--surface-raised` | `#FFFFFF` | Cards, sheets, table surfaces |
| `--surface-sunken` | `#F5F1E8` | Skeletons, empty wells, image backers |
| `--hairline` | `#E7E1D4` | Borders, dividers, table rules (1px) |
| `--success` | `#15803D` | Confirmed, fresh, in-stock, matched-EAN |
| `--warn` | `#B45309` | Expiring soon, low stock |
| `--danger` | `#B91C1C` | Expired, not-in-list, errors |
| `--teal` | `#0F766E` | Very sparing — one info cue / one chart series |

**Category tints** (≤12% alpha tile backings only): Cat-amber `#B45309` (expiry),
Cat-violet `#6D5BD0` (low stock), Cat-green `#15803D` (GRN), Cat-teal `#0F766E`
(health), Cat-orange `#EA580C` (scans/audit). **Festive accent** (celebratory only):
marigold `#F59E0B` + turmeric `#FACC15`.

> Rule: orange ≤10% of any screen. Tints whisper; orange speaks. No purple-blue
> gradients, no neon, no glassmorphism, no pure `#000`.

### 2.2 Dark mode (back-office night shift)

Desaturated tonal inversion, not literal invert: canvas `#1A1714`, raised `#221E1A`,
ink `#F5F1E8`, hairline `#3A332B`, accent stays `#EA580C` (slightly lifted `#F26419`
for AA on dark). Test contrast independently. Ship light first; dark as a toggle.

### 2.3 Typography

- **Display + body:** Plus Jakarta Sans. **Mono (all numbers/EAN/dates/money/IDs):**
  JetBrains Mono.
- Web scale: `12 / 14 / 16 / 18 / 20 / 24 / 30 / 38`. Body 14–16, line-height 1.5.
- **Eyebrow labels** — 11–12px, `w600`, +0.06em tracking, uppercase, ink-soft or
  accent-deep — open every section.
- Page titles `w800`; section headers `w700`; body `w400`; labels `w500`.

### 2.4 Spacing / radii / elevation

- Spacing on a 4pt grid: `4 8 12 16 24 32 48 64`. In-card `16`; section gap `24`;
  zone break `32–48`.
- Radii: `sm 8 / md 12 / lg 16 / xl 24 / full`. Cards `lg`, chips `full`, wells
  `md`, sheets/modals `xl`.
- Elevation: one warm shadow language — `0 2px 8px rgba(28,25,23,.06)` + 1px
  hairline on raised cards. No black shadows, no glassmorphism.

### 2.5 Motion (web)

- Durations: micro 120–200ms; panels/sheets 200–320ms; never >400ms (celebration
  ≤800ms). Easing: enter `cubic-bezier(.23,1,.32,1)`, exit faster (~70%).
- Press-scale `0.98` on cards/buttons. Stagger list/grid 30–50ms. Animate only
  `transform`/`opacity`. Honor `prefers-reduced-motion`.
- Count-up KPIs on first reveal; chart entrance respects reduced-motion (data
  readable immediately).

---

## 3. App shell & navigation

The dashboard is an **adaptive sidebar app** (≥1024px). Below 1024px the sidebar
collapses to icons; below 768px it becomes a slide-in drawer + top bar.

```
┌──────────────────────────────────────────────────────────────────────┐
│  TOP BAR  ▸ RADHA mark · Store switcher ▾ · Global search · ⌘K ·       │
│             date-range · notifications · avatar ▾                      │
├──────────────┬───────────────────────────────────────────────────────┤
│  SIDEBAR     │  PAGE CANVAS (warm cream, faint paper grain)            │
│  (240px)     │                                                         │
│  ▸ Overview  │   ┌── Page header (title w800 + eyebrow + 1 CTA) ──┐    │
│  ▸ Stores    │   │                                                │    │
│  ▸ Expiry    │   └────────────────────────────────────────────────┘    │
│  ▸ Tasks     │   ┌── Zone 1: KPI bento ───────────────────────────┐    │
│  ▸ Inventory │   │  [tile][tile][tile][tile]                      │    │
│  ▸ GRN       │   └────────────────────────────────────────────────┘    │
│  ▸ Suppliers │   ┌── Zone 2: chart + table ───────────────────────┐    │
│  ▸ Audit/EAN │   └────────────────────────────────────────────────┘    │
│  ▸ Reports   │                                                         │
│  ▸ Analytics │                                                         │
│  ▸ Billing   │                                                         │
│  ─ ─ ─ ─ ─   │                                                         │
│  ⚙ Settings  │                                                         │
│  ◆ Admin*    │                                                         │
└──────────────┴───────────────────────────────────────────────────────┘
   * Admin section only renders for role === 'admin' (platform/support).
```

### 3.1 Navigation rules
- Sidebar groups: **Operate** (Overview, Expiry, Tasks, Inventory, GRN, Suppliers,
  Audit/EAN), **Grow** (Reports, Analytics, Billing), **Admin** (Tenants,
  Impersonation, Feature flags — `admin` only), **Settings**.
- Active item: orange left indicator + accent-tint background + ink label `w600`.
- Each item: icon + text label (never icon-only in expanded state).
- **Store switcher** lives in the top bar (drives `?storeId=` on every data call);
  owners get an "All stores" option that routes to the multi-store overview.
- **⌘K command palette**: jump to any page/store, run quick actions (new task,
  new GRN, export report).
- Breadcrumbs on 3+ level drill-downs (e.g. GRN → GRN #1024 → Item).
- Role-gate nav items by permission; if a destination is unavailable, explain why
  (locked tooltip) rather than silently hiding paid ones.

---

## 4. Component catalogue (canonical look)

Build once, reuse everywhere. Each component has the state matrix: default ·
hover · pressed (`0.98`) · loading · disabled (0.4) · empty · error.

| # | Component | Spec |
|---|---|---|
| 4.1 | **KPI tile** | `lg` white card, hairline. Category glyph in tint top-left; big **mono** number (count-up); ink-soft label; micro-trend chip (▲/▼ + %); optional "Action needed ›". Grid of 4 (xl) → 2 (md) → 1 (sm). |
| 4.2 | **Data table** | Sticky header, `aria-sort`, zebra via cream tint, mono numeric columns (tabular), row hover well, row actions on hover/overflow, sticky first col on scroll, pagination footer (cursor), column show/hide, CSV export. Empty + error + skeleton rows. |
| 4.3 | **Chart card** | Header eyebrow + title + range chip + legend (interactive toggle). Line (trends), bar (comparison), donut (≤5 cats), funnel (leads). Tooltip on hover/focus, keyboard-reachable, reduced-motion safe, empty + error states. |
| 4.4 | **Filter bar** | Pill segmented control with **sliding orange indicator**; date-range picker; multi-select store/role/status chips (tint when active); search input with orange focus ring. Sticky on scroll. |
| 4.5 | **Status chip** | Pill, icon + label, tint bg (8%) + tint border (35%). matched→success, expired→danger, expiring→warn, pending→neutral. Always `aria-label`. |
| 4.6 | **OHS gauge** | Circular arc 0→value sweep on reveal, mono center number, dashed ring + "–" for "pending". 6-component breakdown bars below. |
| 4.7 | **Side panel / drawer** | Right slide-in for detail/edit (GRN item, supplier, task). `xl` left radius, scrim 40–60%, confirm-on-dismiss if dirty. |
| 4.8 | **Modal / confirm** | Centered, scale `0.96→1` + opacity. Destructive confirms use danger CTA, separated from cancel. Undo toast for reversible bulk actions. |
| 4.9 | **Form field** | Cream field, hairline, **orange focus ring**, visible label (never placeholder-only), mono for numeric, inline validation on blur, helper text, required asterisk. |
| 4.10 | **Toolbar / page header** | Eyebrow + title `w800` + subtitle + **one** orange CTA + secondary ghost actions + (optional) tabs. |
| 4.11 | **Empty / error / skeleton** | Empty: tonal icon badge + `w700` title + one line + one orange CTA + sunken backer, personality required. Error: danger-tint icon + retry. Skeleton: sunken blocks matching final layout, shimmer respects reduced-motion. |
| 4.12 | **Locked overlay (paid)** | Real layout rendered + tasteful blur/scrim + lock glyph + plan CTA. Show value behind glass, never a blank wall. |
| 4.13 | **Toast / banner** | `aria-live="polite"`, auto-dismiss 3–5s, action affordance. Offline banner pinned top. |
| 4.14 | **Activity feed item** | Avatar/monogram + actor + action + target + mono timestamp; type glyph tint. |
| 4.15 | **Command palette (⌘K)** | Fuzzy nav + actions, recent items, keyboard-first. |

### Icons
One custom warm rounded glyph family (single weight ~1.75px, ~2px corners). SVG
only — no emoji, no off-family Material clones. Inactive = ink-soft line; active =
orange fill. `aria-label` on every icon-only control.

---

## 5. Screen-by-screen specs (each maps to Doc 1 APIs)

Every screen: **Human beat (header) → Substance (zones) → Action.**

### 5.1 Overview / Command Centre — `/`  (owner, manager+)
- **Header:** "Good morning, {name}" + store switcher + date-range + "Generate
  report" CTA.
- **Z1 KPI bento (4):** Scans today · Expiring next 7d · Pending tasks · Low-stock
  — from `GET /dashboard/kpis`. Trend chips from `kpis.trends`.
- **Z2 Two-up:** OHS gauge (`GET /dashboard/health-score`) + 30d trend line
  (`GET /dashboard/trends`).
- **Z3 Alerts panel:** critical/warning/info (`GET /dashboard/alerts`); each row →
  drill route via `actionUrl`; "Create task" inline.
- **Z4 Team + Activity:** top scanners / task leaders (`GET /dashboard/team`) +
  live feed (`GET /dashboard/activity?limit=`).
- **Multi-store view** (owner, "All stores"): store cards grid from
  `GET /dashboard/multi-store` with per-store mini-KPIs + health score; click → store overview.

### 5.2 Stores — `/stores`  (owner, admin)
- Table from `GET /stores`; create (`POST /stores`); detail panel
  (`GET /stores/:id`); access management (`POST /stores/:id/access`, `DELETE
  /stores/:id/access/:userId`). Empty state: "Add your first store".

### 5.3 Expiry — `/expiry`  (owner, manager, staff, auditor)
- **Filter bar:** store, status (near/expired), category, date-range.
- **Z1 KPI:** near-expiry, expired, forecast loss (`/expiry-records/stats`,
  `/stats/by-category`).
- **Z2 Calendar heat grid:** day cells dot-coded by density; click → day list.
- **Z3 Table:** records (`/expiry-records`, `/near-expiry`, `/expired`), mono
  EAN + expiry date + status chip; row → acknowledge/resolve alert.
- **Thresholds editor** (manager+): `GET/PUT /expiry-thresholds`.
- Action: "Add expiry record" (`POST /expiry-records`); OCR validate via
  `/expiry/ocr/validate`.

### 5.4 Tasks — `/tasks`  (all business roles)
- Board (Kanban: To-do / In-progress / Done) + table toggle from `/tasks` +
  `/tasks/stats`. Create from `/tasks` or template (`/task-templates`,
  `/:id/instantiate`). Workflow buttons map to `/tasks/:id/start|complete|reject|
  cancel|reassign`. Evidence drawer (`/tasks/:id/evidence`). "Auto from alert"
  surfaces `/tasks/auto-from-alert`.

### 5.5 Inventory — `/inventory`  (owner, manager+)
- KPI: total products, low-stock, movements (`/inventory/summary`,
  `/category-breakdown`, `/counts`). Movements table (`/movements`). Low-stock
  panel (`/low-stock`, rules `/low-stock-rules`). Actions: stock-in / stock-out /
  adjust (drawers → `/inventory/stock-in|stock-out|adjust`), permission-gated.

### 5.6 GRN — `/grn`  (owner, manager, staff, auditor)
- Stats strip (`/grn/stats`). Table (`/grn`) with status workflow chips. Detail
  page `/grn/:id` with line-item editor (`/:id/items`) and workflow rail:
  validate → post → cancel/reverse (`/grn/:id/validate|post|cancel|reverse`).
  Stepper timeline component.

### 5.7 Suppliers — `/suppliers`  (owner, manager+)
- Table (`/suppliers`, search `/search`), import/export (`/import`, `/export`),
  detail with contacts (`/:id/contacts`) + performance chart (`/:id/performance`),
  status actions (activate/deactivate/blacklist).

### 5.8 Audit / EAN lists — `/audit`  (owner, manager+)
- Lists table (`/ean-lists`) with active toggle (`/:id/activate|deactivate`).
- Upload wizard → `POST /ean-lists/:id/import`; progress + error report
  (`/imports/:batchId`, `/errors`, `/errors/csv`).
- Items table (`/:id/items`); EAN match-rate KPI; `ean_mismatch_spike` alert tie-in.
- Scan sessions review (`/scan-sessions`, `/sync-batches`).

### 5.9 Reports — `/reports`  (owner, manager, admin)
- Report builder (pick dataset, range, store) → `POST /reports/export`
  (XLSX/PDF/CSV). Artefact list (`/reports/:id/files`) with presigned download
  (`/download/:format`, `/report-files/:id/download`). Re-export existing
  (`/reports/:id/export`). Loading = job-progress card.

### 5.10 Analytics & Leads — `/analytics`, `/leads`  (owner, admin)
- **Analytics:** website stats + funnel (`/analytics/website/stats`,
  `/website/funnel`, `/funnel`) — funnel chart, traffic line, conversion KPIs.
  Tenant app activity (`/analytics/app/tenant`).
- **Leads:** pipeline table (`/marketing/leads`), detail (`/leads/:id`), status
  update (`PATCH`), convert → tenant (`/leads/:id/convert`). Kanban by status.

### 5.11 Billing — `/billing`  (owner, admin)
- Current plan + usage cards (`/subscriptions/status`, `/usage`). Plan picker
  (`/subscriptions/plans`) → upgrade/cancel/reactivate. Checkout via Razorpay
  (`/payments/checkout` → `/verify`). Refund action (admin/owner) `/payments/refund`.

### 5.12 Notifications — `/notifications`  (all)
- Inbox (`GET /notifications`), preferences (`/preferences`), mark read
  (`/:id/read`, `/read-all`). Admin/owner test send (`/notifications/test`).

### 5.13 Admin console — `/admin/*`  (admin only)
- **Impersonation:** start/stop support session (`/admin/impersonate`), audit
  trail table (`/admin/impersonations/audit`) — prominent "you are impersonating"
  banner while active.
- **Feature flags:** current variants (`/feature-flags/me`) (+ 🆕 management UI per
  Doc 1 §8.4 when backend lands).
- **Webhooks:** endpoints CRUD + deliveries + replay (`/webhooks/*`).

### 5.14 Settings — `/settings`
- Profile (`/auth/me`), language (`PUT /users/me/language`), team (🆕 user mgmt per
  Doc 1 §8.1), security (password change), tenant info (`/tenants/me`).

---

## 6. Charts & data-viz guide

| Use | Chart | API source |
|---|---|---|
| Scans / activity over time | Line (smooth, area fill ≤10%) | `/dashboard/trends` |
| KPI deltas | Sparkline in KPI tile | `/dashboard/kpis` |
| Expiry by category | Horizontal bar | `/expiry-records/stats/by-category` |
| OHS components | Radial gauge + 6 stacked bars | `/dashboard/health-score` |
| Lead funnel | Funnel | `/analytics/funnel` |
| Store comparison | Grouped bar | 🆕 `/analytics/stores/compare` |
| Inventory movement | Bar (in/out) | `/inventory/movements` |
| Subscription usage | Donut (≤5) | `/subscriptions/usage` |

Rules: legends near chart + interactive toggle; tooltips on hover/focus
(keyboard-reachable); gridlines low-contrast; tabular figures; locale number
formatting; skeleton while loading; empty + error states; reduced-motion safe;
provide CSV/table alternative for accessibility. Recommended lib: **Recharts** or
**visx** (token-themed), or ECharts for heavier dashboards.

---

## 7. Responsive & accessibility

- Breakpoints: `375 / 768 / 1024 / 1280 / 1536`. Sidebar: drawer <768, icon-rail
  768–1024, full ≥1024.
- Tables → stacked cards on mobile; charts simplify (fewer ticks, horizontal bars).
- Contrast ≥4.5:1 body, ≥3:1 large/UI glyphs; verify dark mode separately.
- Visible orange focus ring (2px) on all interactive elements; tab order = visual
  order; skip-to-content link.
- `aria-sort` on sortable columns; `role="alert"` / `aria-live` on form errors +
  toasts; charts get `aria-label` summary + data-table fallback.
- Honor `prefers-reduced-motion`; never convey meaning by color alone (icon+text).

---

## 8. Recommended Next.js implementation stack

- **Next.js (App Router)** + TypeScript; Server Components for data-heavy reads,
  Client Components for interactive widgets.
- **Data:** TanStack Query (client) and/or RSC `fetch` with the typed API client;
  cursor pagination; optimistic updates for task/GRN workflow.
- **Styling:** Tailwind CSS with the RADHA tokens mapped to CSS variables (§2) +
  **shadcn/ui** (Radix) themed to RADHA — gives accessible tables, dialogs,
  dropdowns, command palette out of the box.
- **Charts:** Recharts/visx themed to tokens.
- **Auth:** httpOnly cookie session wrapping the JWT pair (see Doc 3), middleware
  route-guards by role/permission.
- **Forms:** React Hook Form + Zod (mirror backend Zod schemas from Doc 1).
- **State of truth:** never call HTTP from components directly — go through a typed
  `lib/api/*` client layer (mirrors the mobile "no direct HTTP" rule).

### 8.1 Suggested route tree
```
app/
  (auth)/login, /reset
  (dash)/
    layout.tsx            // shell: sidebar + topbar + store switcher
    page.tsx              // Overview
    stores/  expiry/  tasks/  inventory/  grn/  suppliers/
    audit/  reports/  analytics/  leads/  billing/  notifications/
    settings/
    admin/                // role-gated: impersonation, flags, webhooks, tenants(🆕)
lib/
  api/                    // typed clients per Doc 1 domain
  auth/  hooks/  charts/  components/ui/   // shadcn-themed
  design/tokens.css       // §2 tokens
```

---

## 9. Anti-slop gate (run before "done")

Reject if it could read as "an AI admin template": purple-blue gradients, neon,
glassmorphism, pure black, emoji icons, generic Material clones, nested cards,
identical repeated grids, gradient text, side-stripe borders, fake charts, two
competing orange CTAs, tiny unreadable text, hero-metric SaaS cliché. Fix the
*structure*, not the paint. Done = mockup-beaten · tokens-only · motion +
reduced-motion · empty/error/skeleton present · slop gate passed · a11y verified.

*End of Doc 2. See `01_ARCHITECTURE_AND_API.md` and `03_FUNCTIONS_AND_SECURITY_DESIGN.md`.*
