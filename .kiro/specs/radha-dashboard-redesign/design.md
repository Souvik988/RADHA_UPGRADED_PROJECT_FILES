# Design Document

**Feature:** `radha-dashboard-redesign` — RADHA Dashboard Premium UI Redesign

---

## Overview

This is a **visual-layer-only** redesign of the RADHA Admin Dashboard. Zero changes to business logic, API wiring, auth, RBAC, or data structures. Every component upgrade preserves the existing props contract so all parent pages and feature modules continue to work without modification.

The redesign eliminates the "generic SaaS scaffolding" aesthetic and replaces it with a premium, editorial, warm-Indian-retail dashboard that matches the RADHA Flutter mobile app's Visual System Bible.

**Design system source of truth:** `lib/design/tokens.css` (already fully correct, no token changes needed)
**Framework:** Next.js 15 App Router, React 19, Tailwind CSS 3, shadcn/ui (Radix UI), Recharts 2

---

## Architecture

### Technology Choices

| Choice | Rationale |
|---|---|
| CSS tokens only (no hardcoded values) | Already enforced in codebase — continue strictly |
| Tailwind CSS 3 utility classes mapped to tokens | Existing `tailwind.config.ts` already maps all tokens |
| lucide-react (existing) | Use elegantly: consistent `w-[18px] h-[18px]` sizing, `strokeWidth={1.5}` for refinement |
| Radix UI primitives (existing via shadcn/ui) | Popover-based StoreSwitcher replacing raw `<select>` |
| CSS transitions only (no new animation libraries) | Keep bundle lean; `animate-fade-up` already defined in Tailwind config |
| IntersectionObserver for count-up trigger | Already implemented in `useCountUp` — wire it correctly |
| CSS custom property `--font-sans` / `--font-mono` | Already loaded via `next/font/google` in root layout |

### No New Dependencies

All changes use packages already in `package.json`. The only additions are using the existing `@radix-ui/react-popover` (already installed) for the StoreSwitcher upgrade.

---

## Detailed Design

### 1. Shell Redesign

#### 1A. DashShell (`components/shell/dash-shell.tsx`)

**Problem:** `h-screen overflow-hidden` — broken on iOS Safari (viewport jumping).  
**Fix:** Replace with `min-h-[100dvh]` and `flex flex-col` to allow natural scrolling.

```
Before: <div className="flex h-screen overflow-hidden bg-[var(--surface)]">
After:  <div className="flex min-h-[100dvh] bg-[var(--surface)]">
```

Main content area: change `p-5 md:p-6 lg:p-8` to `px-6 py-6 md:px-8` for better rhythm.

#### 1B. Sidebar (`components/shell/sidebar.tsx`)

**Problems:**
1. Active item uses full `bg-accent-tint` — too heavy, not editorial
2. No transition on sidebar width
3. Brand mark is just "R" in a box — no wordmark elegance

**Redesign:**
- Active item: `relative bg-surface-sunken` (not accent-tint) + a 2px left indicator pill `bg-accent`
- Inactive hover: `hover:bg-surface-sunken hover:text-ink` (unchanged — already good)
- Active label: `text-ink font-semibold` (not accent-deep)
- Active icon: `text-accent` (unchanged)
- Sidebar transition: `transition-[width] duration-280 ease-[cubic-bezier(.23,1,.32,1)]`
- Brand mark: orange `R` glyph with `RADHA` wordmark in `font-extrabold text-[15px]` — unchanged, but wrapped in `select-none`
- Nav group eyebrow: add `mt-1` top padding, slightly smaller letter-spacing

```tsx
// Active item (redesigned):
isActive
  ? 'relative bg-surface-sunken text-ink font-semibold'
  : 'text-ink-soft hover:bg-surface-sunken hover:text-ink'

// Active indicator (already correct — keep as-is):
{isActive && (
  <span className="absolute left-0 top-1 bottom-1 w-1 rounded-r-full bg-accent" />
)}
```

#### 1C. TopBar (`components/shell/top-bar.tsx`)

**Problems:**
1. No visual warmth — just a white bar
2. Shadow is too generic (`shadow-[0_1px_3px_...]`)
3. Store switcher is buried

**Redesign:**
- TopBar height stays `h-14` (correct)
- Background: `bg-surface-raised/95 backdrop-blur-sm` — subtle blur for premium feel
- Bottom border: `border-b border-hairline` (unchanged — already correct)
- Remove the explicit shadow — the `border-b` alone is cleaner
- Store switcher: replaced with Popover-based `<StoreSwitcher>` (see below)

#### 1D. StoreSwitcher (`components/shell/store-switcher.tsx`)

**Problem:** Raw `<select>` HTML element looks like a 1990s browser form control.

**Redesign:** Replace with a Radix Popover-based custom dropdown:

```tsx
// Trigger: pill chip
<button className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full 
  bg-surface-sunken border border-hairline text-[13px] font-medium text-ink
  hover:border-accent/40 transition-colors duration-150
  focus-visible:outline-2 focus-visible:outline-accent">
  <Store className="w-3.5 h-3.5 text-ink-soft" />
  <span className="max-w-[140px] truncate">{label}</span>
  <ChevronDown className="w-3 h-3 text-ink-soft" />
</button>

// Dropdown content: bg-surface-raised rounded-xl border border-hairline shadow-card-md
// Each option: px-3 py-2 text-[13px] hover:bg-surface-sunken text-ink
// Active option: font-semibold text-accent with a checkmark icon
```

---

### 2. Component Catalogue Upgrades

#### 2A. KPI Tile (`components/ui/kpi-tile.tsx`)

**Problems:**
1. All tiles are identical squares — no asymmetric bento
2. `KpiBento` uses `grid-cols-4` equal columns — no variation
3. The `value` prop uses `useCountUp` but it's not triggered by viewport entry — always fires on mount

**Redesign of `KpiBento` (`features/overview/components/kpi-bento.tsx`):**

Replace the `grid grid-cols-2 lg:grid-cols-4 gap-4` equal grid with an asymmetric bento:

```tsx
// Desktop: 2 large + 2 small asymmetric
<div className="grid grid-cols-2 lg:grid-cols-4 lg:grid-rows-2 gap-4">
  {/* Expiring — large (col-span-2 on mobile, col-span-2 lg) */}
  <KpiTile ... className="lg:col-span-2 lg:row-span-1" />
  {/* Expired — normal */}
  <KpiTile ... />
  {/* Open tasks — normal */}
  <KpiTile ... />
  {/* Low stock — spans 2 cols on lg to balance */}
  <KpiTile ... className="col-span-2 lg:col-span-2" />
</div>
```

Wait — the existing `KpiTile` doesn't accept className for layout — it does (`className` prop exists). Keep the component, update `KpiBento` to apply asymmetric `className` per tile.

**Redesign of `KpiTile`:**
- Add stagger animation to each tile via `animation-delay`
- Tile on hover: `hover:shadow-card-md transition-shadow duration-150` (subtle elevation lift)
- The loading skeleton: already correct — keep
- Remove `colorClass` prop (doesn't exist in current component — was in the KpiBento usage); the `tint`/`tintBg` props are correct

#### 2B. DataTable (`components/ui/data-table.tsx`)

**Problems:**
1. Zebra striping (`bg-surface-sunken/30` on odd rows) — looks dated
2. Table header uses `bg-surface-raised` — should be `bg-surface-sunken` for visual separation
3. Row hover uses `hover:bg-accent-tint/20` — keep but make it slightly warmer

**Redesign:**
- Remove zebra: delete `idx % 2 === 1 && 'bg-surface-sunken/30'` from row class
- Header: `bg-surface-sunken` (change from `bg-surface-raised`)
- Row hover: keep `hover:bg-surface-sunken` (cleaner than accent tint)
- Loading skeleton rows: add `animate-fade-up` with stagger delay using CSS variable

```tsx
// Row (redesigned — no zebra):
<tr className="border-t border-hairline transition-colors hover:bg-surface-sunken">

// Header (redesigned):
<thead className="bg-surface-sunken border-b border-hairline">
  <th className="px-4 py-3 text-[11px] font-semibold text-ink-soft uppercase tracking-[0.06em] whitespace-nowrap">
```

#### 2C. Button (`components/ui/button.tsx`)

**Current state:** Already very good. Minor refinements:
- `primary` variant: add `shadow-sm` (the button deserves a tiny lift from the surface)
- Font size: keep `text-[15px]` for `md`, use `text-[13px]` for `sm` (already done)
- `loading` spinner: already correct

**Redesign (minimal):**
```tsx
primary: 'bg-accent text-white hover:bg-accent-deep shadow-sm px-6 py-3',
```

#### 2D. PageHeader (`components/ui/page-header.tsx`)

**Problem:** Header has no visual warmth — just text on the default surface background.

**Redesign:**
- Wrap header in a subtle warm band: `pb-5 mb-2 border-b border-hairline/60`
- Title: keep `text-[24px] font-extrabold text-ink` — already good
- Eyebrow: already using `<Eyebrow>` correctly
- Add `animate-fade-up` to the whole header on mount

#### 2E. EmptyState and Skeleton (`components/ui/states.tsx`)

**Current state:** Already correct. Minor refinements:
- `EmptyState` icon well: change from `bg-accent-tint` to `bg-surface-sunken` (more neutral, less orange-heavy)
- The "No active alerts" empty state in `alerts-panel.tsx`: make it more editorial

#### 2F. FilterBar (`components/ui/filter-bar.tsx`)

**Current state:** The segmented control is already good with the sliding indicator. Issues:
- `bg-surface-sunken rounded-full` for the container — good
- Segments: `px-4 py-1.5` — good
- The indicator positioning math using `calc()` with inline style — technically correct but fragile

**Redesign:** 
- Keep the sliding indicator approach — it's correct
- Search input: widen to `w-full md:w-[240px]`
- Add `animate-fade-up` to the container on mount

#### 2G. OHS Gauge (`components/ui/ohs-gauge.tsx`)

**Problem:** SVG arc animation triggers immediately on mount, not on viewport entry.

**Redesign:** Add `useIntersectionObserver` trigger:

```tsx
// Add IntersectionObserver to trigger the animation only on viewport entry
const ref = useRef<HTMLDivElement>(null);
const [revealed, setRevealed] = useState(false);

useEffect(() => {
  const el = ref.current;
  if (!el) return;
  const obs = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) { setRevealed(true); obs.disconnect(); }
  }, { threshold: 0.3 });
  obs.observe(el);
  return () => obs.disconnect();
}, []);

// Use `revealed ? sweep : 0` in stroke-dasharray
```

#### 2H. MonoNumber — IntersectionObserver trigger

**Problem:** `useCountUp` fires on mount regardless of viewport position.

**Redesign:** Wrap `MonoNumber` in a ref + `IntersectionObserver` that triggers the count-up only when the element enters the viewport.

```tsx
const ref = useRef<HTMLSpanElement>(null);
const [started, setStarted] = useState(false);

useEffect(() => {
  const el = ref.current;
  if (!el) return;
  const obs = new IntersectionObserver(([e]) => {
    if (e.isIntersecting) { setStarted(true); obs.disconnect(); }
  }, { threshold: 0.5 });
  obs.observe(el);
  return () => obs.disconnect();
}, []);

const animated = useCountUp(started ? value : 0, durationMs);
```

---

### 3. Login Page Redesign

**Current state:** Centered card on cream surface — decent but generic.

**Redesign:** Split-screen layout on desktop:
- **Left panel (desktop only, 45% width):** `bg-accent` warm gradient panel with RADHA wordmark (large, white), tagline "Your retail command centre", abstract warm illustration placeholder (or generated asset), and a footer quote
- **Right panel (55% width on desktop, full width mobile):** Login form on `bg-surface`
- The form card itself becomes borderless on desktop (no shadow/border needed when the background IS the container)
- Mobile: single column, `bg-surface`, RADHA wordmark in accent, form below

```tsx
// Layout wrapper:
<div className="min-h-[100dvh] flex flex-col md:flex-row">
  {/* Left brand panel — hidden on mobile */}
  <div className="hidden md:flex md:w-[45%] bg-accent flex-col items-start 
    justify-between p-12 relative overflow-hidden">
    {/* Brand content */}
    <div className="flex flex-col gap-4">
      <span className="text-white/60 text-[11px] font-semibold tracking-widest uppercase">
        RADHA · Admin Dashboard
      </span>
      <h1 className="text-white font-extrabold text-[40px] leading-tight tracking-tight">
        Your retail<br />command centre.
      </h1>
      <p className="text-white/70 text-[15px] leading-relaxed max-w-[280px]">
        Expiry tracking, inventory, tasks, and audits — in one premium back-office.
      </p>
    </div>
    {/* Abstract decoration */}
    <div className="text-white/20 text-[11px]">RADHA v1 · Private</div>
  </div>

  {/* Right form panel */}
  <div className="flex-1 flex flex-col items-center justify-center 
    bg-surface px-6 py-12 md:py-0">
    {/* ... form content ... */}
  </div>
</div>
```

---

### 4. Alerts Panel Redesign

**Current state:** Each alert is a rounded box with colored border — looks card-heavy.

**Redesign:** Alerts as horizontal rows with left colored dot, no individual card wrappers:

```tsx
// Alert row (redesigned):
<div className="flex items-start gap-3 py-3 border-b border-hairline 
  last:border-0 hover:bg-surface-sunken -mx-5 px-5 transition-colors">
  <span className={cn('mt-1.5 w-2 h-2 rounded-full flex-shrink-0', dotColor)} />
  <Icon className={cn('h-4 w-4 flex-shrink-0 mt-0.5', color)} />
  <p className="flex-1 text-[13px] text-ink leading-snug">{alert.message}</p>
  <div className="flex items-center gap-1.5 flex-shrink-0">
    {/* CTA links */}
  </div>
</div>
```

Remove the individual `rounded-lg border` wrapper around each alert. The panel itself (`card`) provides the container.

---

### 5. Activity Feed Redesign

**Current state:** Items divided by `divide-y` — flat and monotonous.

**Redesign:** Timeline style with connecting line:

```tsx
// Timeline wrapper:
<div className="relative flex flex-col">
  {/* Vertical connecting line */}
  <div className="absolute left-3.5 top-4 bottom-4 w-px bg-hairline" aria-hidden="true" />
  
  {items.map((item) => (
    <div key={item.id} className="relative flex items-start gap-3 py-3">
      {/* Node */}
      <span className="w-7 h-7 rounded-full bg-surface-sunken border border-hairline 
        flex items-center justify-center flex-shrink-0 z-10">
        <ActivityIcon action={item.action} />
      </span>
      <div className="flex-1 min-w-0 pt-1">
        <p className="text-[13px] text-ink leading-snug">
          <span className="font-semibold">{item.actor}</span>
          {' '}{item.action}
          {item.target && <span className="text-ink-soft"> · {item.target}</span>}
        </p>
        <span className="text-[11px] font-mono tabular-nums text-ink-soft">
          {formatRelativeTime(item.timestamp)}
        </span>
      </div>
    </div>
  ))}
</div>
```

---

### 6. Trend Card Redesign

**Current state:** Line chart wrapped in a card, `ChartCard` with `type="line-trend"` — but `ChartCard` doesn't have a `type` prop. The `TrendCard` passes incorrect props.

**Fix + Redesign:** Fix the `TrendCard` to use `LineTrend` directly:

```tsx
// trend-card.tsx (fixed):
import { LineTrend, CHART_COLORS } from '@/components/ui/chart-card';

// In the card content:
<LineTrend
  data={chartData}
  xKey="date"
  yKey="value"
  color={CHART_COLORS.accent}
  height={160}
  aria-label="30-day scan and expiry trend"
/>
```

Also redesign the chart visual:
- Remove `CartesianGrid` (already no gridlines in spec)
- Area fill gradient (need to use `AreaChart` instead of `LineChart` in `ChartCard`)

**Redesign `LineTrend` in `chart-card.tsx`:** Convert to AreaChart with gradient fill:

```tsx
import { AreaChart, Area, ... } from 'recharts';

// Gradient definition:
<defs>
  <linearGradient id="accentGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="5%" stopColor="#ea580c" stopOpacity={0.15}/>
    <stop offset="95%" stopColor="#ea580c" stopOpacity={0}/>
  </linearGradient>
</defs>

// Area:
<Area type="monotone" dataKey={yKey} 
  stroke={color} strokeWidth={1.5}
  fill="url(#accentGrad)"
  dot={false} />
```

---

### 7. CSS Additions to globals.css

Add fade-up animation to sections (staggered entry):

```css
/* Section entrance — add to @layer utilities */
.section-enter {
  animation: fadeUp 200ms cubic-bezier(.23,1,.32,1) both;
}

/* Stagger variants — apply to nth sections */
.section-enter-1 { animation-delay: 0ms; }
.section-enter-2 { animation-delay: 60ms; }
.section-enter-3 { animation-delay: 120ms; }
.section-enter-4 { animation-delay: 180ms; }

/* Sidebar slide-in */
@keyframes slide-in-left {
  from { transform: translateX(-100%); }
  to { transform: translateX(0); }
}
```

---

### 8. KpiBento Asymmetric Bento Layout

The key visual upgrade for the Overview page — from 4 identical tiles to an editorial bento:

```tsx
// features/overview/components/kpi-bento.tsx (redesigned):
<div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
  {/* Expiring — full width on mobile, 2-cols wide on lg */}
  <KpiTile
    key="expiring"
    ...expiringProps
    className="col-span-2 lg:col-span-2 animate-fade-up"
    style={{ animationDelay: '0ms' }}
  />
  {/* Expired */}
  <KpiTile
    ...expiredProps
    className="animate-fade-up"
    style={{ animationDelay: '60ms' }}
  />
  {/* Open tasks */}
  <KpiTile
    ...tasksProps
    className="animate-fade-up"
    style={{ animationDelay: '120ms' }}
  />
  {/* Low stock — full width on mobile */}
  <KpiTile
    ...lowStockProps
    className="col-span-2 lg:col-span-2 animate-fade-up"
    style={{ animationDelay: '180ms' }}
  />
</div>
```

Wait — `style` prop with animation-delay on KpiTile won't work because `KpiTile` doesn't spread `style`. Better approach: apply stagger via parent utility classes or add a `delayMs` prop to KpiTile.

**Decision:** Use CSS animation-delay via Tailwind config's inline approach — add `[animation-delay:Xms]` arbitrary value directly on the KpiTile className (Tailwind 3 supports this), OR wrap each tile in a div with the delay. The simplest: wrap in `<div>` with the stagger class inside `KpiBento`, not inside `KpiTile`.

---

### 9. Page-Level Section Entrance Animations

Apply to Overview sections (`app/(dash)/page.tsx`):

```tsx
// Each section gets a fade-up class with stagger:
<section aria-label="Store KPIs" className="flex flex-col gap-3 animate-fade-up [animation-delay:80ms]">
  ...
</section>
<section aria-label="Health and trends" className="flex flex-col gap-3 animate-fade-up [animation-delay:160ms]">
  ...
</section>
```

---

### 10. Asset Generation Plan

Using `kiro-gpt-bridge` MCP server before implementing each visual:

| Asset | Tool | Save Path | When |
|---|---|---|---|
| Login brand panel hero | `generate_hero` | `public/assets/hero/login-panel.png` | Before login page implementation |
| Dashboard overview mockup | `generate_ui_mockup` | `public/assets/mockup/overview.png` | Design validation |
| Sidebar nav icon set | `generate_icon_set` | `public/assets/icon/nav-*.png` | After shell redesign |
| Empty state illustrations | `generate_image` | `public/assets/illustration/empty-*.png` | Per feature |

---

### 11. Playwright Verification Plan

After each implementation phase:

1. Start dev server (`npm run dev`)
2. Navigate to each route
3. Screenshot in light + dark mode
4. Check for console errors
5. Check no horizontal overflow
6. Verify orange CTAs visible and singular per region
7. Fix any issues found

**Verification order:**
1. `/login` — split layout, form, demo mode
2. `/` (Overview) — KPI bento asymmetry, OHS gauge, trend chart, alerts rows, activity timeline
3. `/expiry` — KPI tiles, filter bar, table (no zebra), calendar heat grid
4. `/tasks` — board columns, create panel, detail panel
5. All remaining routes: `/inventory`, `/grn`, `/suppliers`, `/audit`, `/reports`, `/analytics`, `/billing`, `/notifications`, `/stores`, `/admin`, `/settings`

---

## Components and Interfaces

### Component Change Summary

| Component | File | Change Type | Scope |
|---|---|---|---|
| `DashShell` | `components/shell/dash-shell.tsx` | Fix + Visual | Replace `h-screen` with `min-h-[100dvh]`, adjust padding |
| `Sidebar` | `components/shell/sidebar.tsx` | Visual | Soften active state, refine transition |
| `TopBar` | `components/shell/top-bar.tsx` | Visual | Remove explicit shadow, add `backdrop-blur-sm` |
| `StoreSwitcher` | `components/shell/store-switcher.tsx` | Rebuild | Replace `<select>` with Radix Popover pill |
| `KpiBento` | `features/overview/components/kpi-bento.tsx` | Visual | Asymmetric bento grid with stagger animation |
| `KpiTile` | `components/ui/kpi-tile.tsx` | Visual | Add hover shadow, entrance animation support |
| `DataTable` | `components/ui/data-table.tsx` | Visual | Remove zebra, fix header background |
| `Button` | `components/ui/button.tsx` | Visual | Add `shadow-sm` to primary variant |
| `LineTrend` | `components/ui/chart-card.tsx` | Rebuild | Convert to AreaChart with gradient fill |
| `TrendCard` | `features/overview/components/trend-card.tsx` | Fix | Fix incorrect prop usage of ChartCard |
| `AlertsPanel` | `features/overview/components/alerts-panel.tsx` | Visual | Row-based alerts (remove per-alert card wrappers) |
| `ActivityFeed` | `features/overview/components/activity-feed.tsx` | Visual | Timeline with connector line |
| `OhsGauge` | `components/ui/ohs-gauge.tsx` | Enhancement | Add IntersectionObserver trigger for arc animation |
| `MonoNumber` | `components/ui/mono-number.tsx` | Enhancement | Add IntersectionObserver trigger for count-up |
| `PageHeader` | `components/ui/page-header.tsx` | Visual | Add bottom border, entrance animation |
| `LoginPage` | `app/(auth)/login/page.tsx` | Rebuild | Split-screen layout |
| `globals.css` | `app/globals.css` | Addition | Section stagger utilities, slide-in keyframe |

### Preserved Interfaces (zero breaking changes)

All component props interfaces are **unchanged**. The redesign touches only className values, layout structure, and visual appearance. Every parent that currently uses these components will continue to work.

### New Helper: `useIntersectionObserver`

A small custom hook to trigger animations on viewport entry — used by `MonoNumber` and `OhsGauge`:

```ts
// lib/hooks/use-intersection-observer.ts
export function useIntersectionObserver(
  ref: React.RefObject<Element | null>,
  threshold = 0.3
): boolean {
  const [isVisible, setIsVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) { setIsVisible(true); obs.disconnect(); } },
      { threshold }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [ref, threshold]);
  return isVisible;
}
```

---

## Data Models

No data model changes. This is a pure visual redesign. All existing Zod schemas, API response types, TanStack Query keys, and Server Actions are unchanged.

The following data flow is preserved in its entirety:
- `useOverviewKpis(storeId)` → `KpiBento` → `KpiTile`
- `useHealthScore(storeId)` → `OhsCard` → `OhsGauge`
- `useOverviewTrends(storeId, from, to)` → `TrendCard` → `LineTrend`
- `useOverviewAlerts(storeId)` → `AlertsPanel`
- `useOverviewActivity(storeId, limit)` → `ActivityFeed`
- `useExpiryList`, `useExpiryKpis`, `useExpiryCalendar` → expiry feature components (unchanged)
- `useTasksList`, `useTaskStats`, `useTaskDetail` → tasks feature components (unchanged)

---

## Correctness Properties

The following properties define visual correctness and can be verified programmatically:

### Property 1: No Raw Colors
No component file under `components/`, `features/`, or `app/` SHALL contain raw hex color values or `rgba()` values. All colors come from CSS token classes.

**Validates: Requirements 1.1, 1.2**

### Property 2: No Heavy Shadows
No component file SHALL use `shadow-md`, `shadow-lg`, `shadow-xl`, or `shadow-2xl` Tailwind classes. Only `shadow-card` and `shadow-card-md` are permitted.

**Validates: Requirements 1.8, 17.3**

### Property 3: Single Orange CTA Per Region
In any rendered page, at most one `bg-accent` button SHALL be present per visual region (page header, section, panel).

**Validates: Requirements 3.1, 6.4, 17.1**

### Property 4: Mono Numbers
Every element displaying a KPI count, date, price, EAN, or percentage SHALL have `font-mono` and `tabular-nums` in its computed class list.

**Validates: Requirements 1.4, 3.2, 5.6**

### Property 5: Skeleton on Load
Every component that uses `useQuery` SHALL render at least one element with the `.skeleton` class when `isLoading === true`.

**Validates: Requirements 3.9, 17.6**

### Property 6: Non-Empty Empty States
Every list or table component SHALL render a heading (not "No data") when its data array is empty.

**Validates: Requirements 3.10, 5.7, 17.7**

---

## Error Handling

All error states are handled by existing components:
- `KpiTile state="error"` — already renders "Failed to load" text
- `DataTable state="error"` — already renders "Failed to load data." row
- `ErrorState` component — used in panels, chart cards
- `ChartCard state="error"` — already handled

No new error handling logic is added.

---

## Testing Strategy

**Visual verification (Playwright):**
1. Start dev server at `localhost:3001`
2. Navigate each route, screenshot light + dark mode
3. Verify: no horizontal overflow, correct fonts, single orange CTA per region, tables have no zebra striping, sidepanel opens/closes correctly

**Token compliance (static analysis):**
- Grep `components/ features/` for hardcoded hex — expect zero
- Grep for `shadow-md|lg|xl` — expect zero

**Component state tests (manual verification):**
- Each feature page loading state shows skeleton
- Empty state shows meaningful message
- Error state shows retry affordance
