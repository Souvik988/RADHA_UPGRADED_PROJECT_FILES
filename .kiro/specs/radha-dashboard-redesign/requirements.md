# Requirements Document

**Feature:** `radha-dashboard-redesign` — RADHA Dashboard Premium UI Redesign
**Type:** Visual Layer Redesign (zero backend changes)
**Platform:** Next.js 15 App Router + Tailwind CSS 3 + shadcn/ui + Recharts 2
**Scope:** All authenticated dashboard screens — shell, auth pages, and every feature module

---

## Introduction

The RADHA Admin Dashboard is a private back-office application for the RADHA retail-ops SaaS platform — used by owners and admins of Indian retail stores (primary market: Gujarat) to manage expiry tracking, inventory, GRN, tasks, suppliers, EAN audits, analytics, and billing.

The current UI reads as generic SaaS scaffolding: predictable card grids, stock icons, flat typography hierarchy, and default shadcn/ui styling. The redesign elevates every pixel to match the premium visual bar set by the RADHA Flutter mobile app: warm cream canvas, confident burnt-orange accent, editorial eyebrow labels, tabular mono KPIs, soft warm shadows, and a narrative flow that makes the product feel authored — not assembled.

**All backend wiring, API calls, auth, RBAC, route handlers, session management, and business logic remain completely unchanged.** This is a pure visual layer transformation.

---

## Glossary

| Term | Definition |
|---|---|
| Token | CSS custom property defined in `lib/design/tokens.css` — the only source of color, spacing, radius, and shadow values |
| Eyebrow label | Small (11px), uppercase, `font-weight: 600`, letter-spaced label that introduces every major section |
| KPI tile | Metric card showing a large mono number, category glyph, label, and optional micro-trend |
| Surface | Background layer: `--surface` (cream canvas), `--surface-raised` (white cards), `--surface-sunken` (skeleton wells) |
| Hairline | 1px border in `--hairline` (#E7E1D4) — the only border width allowed |
| Skeleton | Loading placeholder that mirrors the exact layout of the final component — never a spinner |
| Anti-slop gate | Visual quality check: the interface must not read as "AI-generated generic SaaS" |
| Category tint | Domain-specific low-alpha (8–12%) tile background: amber=expiry, violet=inventory, green=GRN, teal=analytics, orange=audit |
| OHS | Operational Health Score — circular arc gauge animated on reveal |
| Bento | Asymmetric grid of varied-size KPI tiles, not identical card columns |
| Shell | Persistent layout wrapper: collapsible sidebar + top bar |

---

## Requirements

## Requirement 1: Design Token Enforcement

### User Story
As a developer maintaining the dashboard, I want every visual value to come from CSS tokens so that the design system remains consistent and dark mode works without per-component overrides.

### Acceptance Criteria

1. WHERE a color, spacing, border-radius, or shadow value is needed, THE component SHALL use the Tailwind utility classes that map to the token system (`bg-surface`, `text-ink`, `border-hairline`, `shadow-card`, `rounded-lg`, etc.) and SHALL NOT use hardcoded hex values, arbitrary `bg-[#xyz]` values, or `style={{}}` inline color overrides.

2. WHEN a new component is created, it SHALL reference only the token-mapped Tailwind classes defined in `tailwind.config.ts` — specifically: `accent`, `accent-deep`, `accent-tint`, `ink`, `ink-soft`, `surface`, `surface-raised`, `surface-sunken`, `hairline`, `success`, `warn`, `danger`, `teal`, `cat-amber`, `cat-violet`, `cat-green`, `cat-teal`, `cat-orange`, `marigold`, `turmeric`.

3. THE typography system SHALL use Plus Jakarta Sans for all display and body text and JetBrains Mono for all numeric values (KPIs, counts, dates, prices, IDs, percentages). These SHALL be loaded via Next.js `next/font/google` in `app/layout.tsx` and injected as `--font-sans` and `--font-mono` CSS variables.

4. WHERE a number is displayed (revenue, item counts, percentages, timestamps, EAN codes), it SHALL receive the `font-mono tabular-nums` CSS class.

5. WHEN the `[data-theme="dark"]` attribute is set on `<html>`, ALL token-using components SHALL automatically render the dark-mode token values without any conditional class logic in component code.

6. THE spacing system SHALL follow the 4pt grid: `space-2` (2px), `space-4` (4px), `space-8` (8px), `space-12` (12px), `space-16` (16px), `space-24` (24px), `space-32` (32px), `space-48` (48px), `space-64` (64px). Arbitrary spacing values (`p-[13px]`, `mt-[7px]`) are forbidden.

7. THE border-radius scale SHALL use only `rounded-sm` (8px), `rounded-md` (12px), `rounded-lg` (16px), `rounded-xl` (24px), or `rounded-full`. Arbitrary radius values are forbidden.

8. THE shadow scale SHALL use only `shadow-card` or `shadow-card-md`. No `shadow-md`, `shadow-lg`, `shadow-xl`, or `drop-shadow-*` classes. Heavy black shadows are forbidden.

---

## Requirement 2: Page Layout Shell (Sidebar + Top Bar)

### User Story
As a dashboard user, I want the navigation shell to feel structured and premium so that switching between modules feels confident and oriented.

### Acceptance Criteria

1. THE sidebar SHALL be collapsible between a full-width state (~220px) and an icon-rail state (~64px) with a smooth 280ms `easeOut` CSS transition on `width`. The collapsed/expanded preference SHALL be persisted in `localStorage`.

2. WHEN the sidebar is rendered, it SHALL display navigation groups (Operate · Grow · Admin · Settings) separated by eyebrow labels (uppercase, 11px, `text-ink-soft`, `tracking-widest`). The active item SHALL show a solid `bg-accent` left indicator pill (2px wide, `rounded-full`, `h-[20px]`), NOT a full-width highlight bar.

3. THE sidebar SHALL use `bg-surface-raised` background with a right `border-r border-hairline` — no box-shadow on the sidebar itself.

4. WHEN a nav item is active, its icon SHALL render in `text-accent` and its label in `text-ink font-semibold`. Inactive items SHALL render in `text-ink-soft` with `hover:text-ink hover:bg-surface-sunken` transitions.

5. THE top bar SHALL contain: hamburger/collapse toggle (left), store-switcher chip (center-left), global search trigger (center, cmd+K), notifications bell, theme toggle, and user avatar (right). Height SHALL be 56px with `border-b border-hairline bg-surface-raised`.

6. THE store-switcher chip SHALL render as a pill: `bg-surface-sunken border border-hairline rounded-full px-3 py-1.5` with a small store icon, store name truncated to 20 chars, and a chevron. Clicking it SHALL open a popover (not modal) listing available stores.

7. THE theme toggle SHALL be an icon-only button showing a sun or moon lucide icon, toggling `data-theme="dark"` on `<html>` and persisting to `localStorage`. No text label.

8. THE user avatar SHALL be a circular 32px element: photo if available, else a warm monogram (`bg-accent-tint text-accent-deep font-semibold`) with the user's initials. Clicking it SHALL open a dropdown with profile, settings, and logout.

9. THE main content area SHALL have `bg-surface` (warm cream) background with `padding: 24px 32px` on desktop and `16px` on mobile.

10. WHEN the viewport is below 1024px, the sidebar SHALL collapse behind an overlay drawer triggered by the hamburger. The overlay SHALL use `bg-ink/20 backdrop-blur-sm`.

---

## Requirement 3: Overview / Command Centre Page

### User Story
As an owner or admin opening the dashboard, I want the first screen to immediately tell me the most critical things about my store(s) today — at a glance, with one clear action path.

### Acceptance Criteria

1. THE page SHALL open with a human-beat header band: time-aware greeting (`Good morning / afternoon / evening, [FirstName]`), subtitle ("Here's what needs your attention today"), and ONE primary orange CTA button ("Generate report" or contextual action). The header background SHALL use a subtle warm tonal wash (`#FFF3E6` to `#FFFBF5`) — not a plain surface.

2. THE KPI bento grid SHALL display 4 KPI tiles in a 2×2 asymmetric grid on desktop (not 4 identical equal columns). Each tile SHALL have: category icon in its domain tint color at 8% alpha background, a large mono number in the tint color, a label in `text-ink-soft text-sm`, and an optional micro-trend (up/down arrow + percentage). The number SHALL animate from 0 to its value on first reveal using a CSS counter animation.

3. WHEN the KPI tiles render, the grid SHALL use `grid-cols-2 md:grid-cols-4 gap-4` with tiles having varied emphasis — the most critical metric (e.g., expiring items) takes `col-span-2` on one row, creating asymmetry.

4. THE OHS (Operational Health Score) card SHALL display a circular arc gauge: neutral dashed ring background, animated orange fill sweeping from 0 to the score value over 800ms on reveal, mono score number centered, "Store Health" label below, and a brief interpretation text ("Good" / "Needs attention").

5. THE trends chart (Recharts AreaChart) SHALL use: `stroke="#ea580c"` for the primary series, `fill` as a gradient from `rgba(234,88,12,0.15)` to transparent, `strokeWidth={1.5}`, no grid lines except a subtle horizontal `stroke="#e7e1d4"`, and custom tooltip with rounded corners and `bg-surface-raised border-hairline`.

6. THE alerts panel SHALL render each alert as a horizontal row (not a card): left colored dot (amber/danger/warn by severity) + icon + title + `text-ink-soft` meta + right-aligned CTA link. Rows SHALL have `border-b border-hairline` and `hover:bg-surface-sunken` transitions. No card wrapper around each row.

7. THE activity feed SHALL render as a vertical timeline: connecting line in `bg-hairline`, circular node (8px) in the domain color, action text, actor name in `font-semibold`, timestamp in `font-mono text-xs text-ink-soft`.

8. WHEN the user is an owner with no store selected (multi-store mode), the page SHALL render a multi-store grid showing each store as a card with its name, OHS score gauge (small, inline), and 2–3 key metrics. The grid SHALL use `grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4`.

9. WHEN data is loading, every section SHALL show a skeleton that mirrors the final layout (matching heights and positions) using `bg-surface-sunken` blocks with shimmer animation. No spinner.

10. WHEN a section has no data, an empty state SHALL render: icon in `bg-surface-sunken rounded-full p-3`, heading in `text-ink font-semibold`, one supportive line in `text-ink-soft`, and one orange CTA.

---

## Requirement 4: Authentication Pages (Login / Reset / Verify / Invite)

### User Story
As a user accessing the dashboard for the first time, I want the authentication screens to feel polished and on-brand so that I trust the product before I even log in.

### Acceptance Criteria

1. THE login page SHALL use a split-screen layout on desktop: left half is an illustrative/editorial brand panel (warm gradient, RADHA wordmark, one illustrative hero element, a brand tagline); right half is the form panel on `bg-surface`.

2. THE form card on the login page SHALL use `bg-surface-raised rounded-xl shadow-card border border-hairline` with `p-8` padding. It SHALL NOT be centered on a dark background.

3. WHEN the form is in a loading/submitting state, the primary submit button SHALL show an inline spinner (16px, `text-white`) replacing the button text — the button dimensions SHALL NOT change.

4. THE input fields SHALL use: `bg-surface-sunken border border-hairline rounded-md`, orange focus ring (`ring-2 ring-accent ring-offset-1`), `text-ink`, placeholder in `text-ink-soft`. Labels SHALL be above inputs, never floating.

5. WHEN a form validation error occurs, an error message SHALL appear directly below the input in `text-sm text-danger` with a `AlertCircle` icon (16px) prepended.

6. THE mobile layout (below 768px) SHALL show the form full-width with `px-6` padding. The brand panel SHALL collapse to a slim top band (60px) showing just the RADHA wordmark on `bg-accent`.

7. THE "RADHA" wordmark on auth pages SHALL use Plus Jakarta Sans `font-weight: 800`, `text-accent`. No logo image is required — the wordmark is the brand mark.

---

## Requirement 5: Expiry Module

### User Story
As a store manager, I want the expiry screen to surface critical items immediately so that I can prioritize clearance actions before items expire unsold.

### Acceptance Criteria

1. THE expiry page header SHALL include the module title, an eyebrow label "EXPIRY MANAGEMENT", the total count of items in the active filter in a `font-mono` badge, and a primary "Add expiry" orange CTA button.

2. THE filter/tab row SHALL use a segmented control (pill shape, sliding orange indicator) for: All · Expired · This Week · Next Month. The active segment SHALL animate its indicator via CSS `transform: translateX()` transition, not background color swap.

3. THE expiry table SHALL use: `bg-surface-raised rounded-lg border border-hairline overflow-hidden`. Header row in `bg-surface-sunken border-b border-hairline text-ink-soft text-xs uppercase tracking-wide`. Data rows in `hover:bg-surface-sunken` with `border-b border-hairline`. No zebra striping.

4. WHEN an item is expired, its expiry date cell SHALL render in `text-danger font-mono` with a `text-xs` "EXPIRED" pill badge (`bg-danger/10 text-danger border border-danger/20 rounded-full`).

5. WHEN an item expires within 7 days, its expiry date SHALL render in `text-warn font-mono` with a "SOON" pill badge in warn colors.

6. THE product name cell SHALL show the product name (truncated at 40 chars with tooltip) + a mono EAN code below in `text-xs text-ink-soft font-mono`.

7. WHEN the table has no items matching the current filter, an empty state SHALL render inside the table body area (not replacing the entire page) with an illustration placeholder, "No expiring items" heading, and a contextual action.

---

## Requirement 6: Tasks Module

### User Story
As a manager, I want to see outstanding tasks at a glance and assign them quickly so that my team stays coordinated.

### Acceptance Criteria

1. THE tasks page SHALL use a kanban-inspired visual with status pill filters at the top: All · Open · In Progress · Completed. Each status chip SHALL include the item count in `font-mono`.

2. EACH task row SHALL display: priority dot (red/amber/green), task title, assignee avatar (24px circular), due date in `font-mono text-xs`, and a status badge pill. The row SHALL be `hover:bg-surface-sunken` with `cursor-pointer`.

3. WHEN a task is overdue, its due date SHALL render in `text-danger font-mono` with no additional badge (the color IS the signal).

4. THE "New task" button SHALL be the sole orange primary CTA on the page. Secondary actions (filter, sort, export) SHALL use `variant="ghost"` or `variant="outline"` buttons in `text-ink`.

5. WHEN a task is clicked, a right-side panel (not full dialog) SHALL slide in from the right at 320px width with details, assignee selector, and status controls. The panel uses `border-l border-hairline bg-surface-raised shadow-card-md`.

---

## Requirement 7: Inventory Module

### User Story
As a manager, I want inventory levels and low-stock alerts surfaced prominently so that I can initiate restocking before stockouts occur.

### Acceptance Criteria

1. THE inventory page SHALL show 3 summary KPI tiles at the top (total SKUs, low stock count, out-of-stock count) using the category tint system (`cat-violet` for inventory domain tiles).

2. THE low-stock alert banner — when active — SHALL render as a full-width attention bar above the main table: `bg-warn/8 border border-warn/20 rounded-lg` with warn icon, count text, and a "View low stock" link.

3. THE main inventory table SHALL have a search input (`bg-surface-sunken`) above it with filter chips for category. The search field SHALL be 100% width on mobile and 320px max on desktop.

4. WHEN a stock level is zero, the row's stock cell SHALL use `text-danger font-mono font-semibold` and the row SHALL have a subtle `bg-danger/4` left indicator (2px solid `bg-danger` border-left on the row).

---

## Requirement 8: GRN Module (Goods Received Notes)

### User Story
As a store manager receiving a supplier delivery, I want to record the GRN quickly with minimal friction so that inventory is updated accurately.

### Acceptance Criteria

1. THE GRN list page SHALL display each GRN as a card row: GRN number in `font-mono`, supplier name, date, item count, total value (if available), and a status badge (Pending / Partial / Complete) in the appropriate semantic color.

2. THE GRN detail page (`/grn/[id]`) SHALL display line items in a table with: product thumb placeholder, product name, EAN in `font-mono`, ordered qty, received qty (editable inline), and variance column highlighted in `text-warn` if non-zero.

3. THE primary CTA on the GRN detail page SHALL be "Mark as received" — single orange button, always visible in a sticky bottom bar on mobile.

---

## Requirement 9: Suppliers Module

### User Story
As an admin, I want a clean supplier directory so that I can quickly find contact details and order history.

### Acceptance Criteria

1. THE suppliers list SHALL render in a two-column card grid on desktop (`grid-cols-2 lg:grid-cols-3`) — NOT a table — since suppliers have minimal data and the grid reads better than rows.

2. EACH supplier card SHALL show: supplier name (`font-semibold text-ink`), category tag pill, contact number in `font-mono`, active GRN count badge, and a "View" button (`variant="ghost"`). The card SHALL use `bg-surface-raised rounded-lg border border-hairline hover:shadow-card-md` transition.

3. THE supplier detail page SHALL have a tab row (Details · GRN History · Products) using the segmented control component from Requirement 5.2.

---

## Requirement 10: Audit / EAN Module

### User Story
As an auditor, I want a clear view of EAN scan sessions and verification results so that I can track shelf compliance.

### Acceptance Criteria

1. THE audit page SHALL show a KPI summary row: sessions today (mono number), items scanned (mono), matched % (mono, colored `text-success` if >95%), unmatched count (mono, colored `text-danger` if >0).

2. EACH scan session row SHALL show: session ID in `font-mono text-xs`, store name, date/time, scan count, match rate as a thin horizontal progress bar (orange fill on hairline track), and a "View" link.

3. WHEN verification status is "matched", the cell SHALL show a `text-success` checkmark icon + "Matched" text. For "not-in-list" status, `text-danger` × icon + "Not in list". For "no-list" status, `text-warn` info icon + "No list". All statuses SHALL include a `aria-label` describing the status.

---

## Requirement 11: Reports Module

### User Story
As an owner, I want to generate and download operational reports with one click so that I have data for business reviews.

### Acceptance Criteria

1. THE reports page SHALL use a grid of report-type cards (`grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4`). Each card: report icon (lucide, 20px, `text-accent-deep`), report name, brief description (1 line), last generated date in `font-mono text-xs text-ink-soft`, and a primary/outline button pair ("Generate" orange / "Download" outline).

2. WHEN a report is generating, the "Generate" button SHALL show a loading spinner inline and become disabled. No full-page loading state.

3. WHEN a feature is gated (behind `<NeedsBackend>`), the card SHALL render in full with the real layout but with a `blur-sm pointer-events-none` overlay inside the card area and a "Requires backend" pill badge on top right. The card itself SHALL NOT be hidden.

---

## Requirement 12: Analytics Module

### User Story
As an owner, I want visual trend charts and cross-store comparisons so that I can spot performance patterns over time.

### Acceptance Criteria

1. THE analytics page SHALL use a time range selector (tabs: 7D · 30D · 90D · Custom) with the segmented control component. Selecting a range SHALL update all charts without page reload.

2. CHARTS SHALL follow the token system: primary series `stroke="#ea580c"`, area fill `rgba(234,88,12,0.12)`, grid lines `stroke="#e7e1d4"`, axis labels in `font-mono text-xs fill="#57534e"`, custom tooltips in `bg-surface-raised border border-hairline rounded-md shadow-card`.

3. THE cross-store compare page SHALL render a grouped bar chart (Recharts) with each store as a bar group, using `cat-teal` and `cat-orange` as the two series colors.

---

## Requirement 13: Billing Module

### User Story
As an owner, I want clear visibility of my current plan, usage, and upcoming charges so that I can manage my subscription confidently.

### Acceptance Criteria

1. THE billing page SHALL open with a current plan summary card: plan name (`font-semibold text-lg`), status badge (Active in `text-success`, Trial in `text-warn`), renewal date in `font-mono`, and a "Manage plan" orange CTA.

2. USAGE meters (stores, scans, team members) SHALL render as horizontal bars: label left, mono number right, progress bar between them (`bg-surface-sunken rounded-full h-2`, fill `bg-accent rounded-full`). When usage exceeds 80%, the fill SHALL switch to `bg-warn`.

3. THE invoice history table SHALL be gated behind `<NeedsBackend>` with the visual-blur treatment from Requirement 11.3.

---

## Requirement 14: Notifications Module

### User Story
As any user, I want to see and manage my notifications in a clean feed so that I don't miss important alerts.

### Acceptance Criteria

1. THE notifications feed SHALL render as a vertical list of notification rows: left icon in a 32px rounded-full colored well (color matches notification type), notification message, timestamp in `font-mono text-xs text-ink-soft`, and a read/unread indicator (2px orange dot on the left edge of unread rows).

2. THE "Mark all read" action SHALL be a ghost button in the page header. It SHALL apply an optimistic update (mark all dots removed instantly), then confirm via API.

3. WHEN there are no notifications, a centered empty state SHALL show a bell illustration placeholder, "You're all caught up" heading, and no CTA (this is a success state, not an error).

---

## Requirement 15: Admin Console

### User Story
As an admin, I want a structured console to manage tenants, feature flags, webhooks, and audit logs with confidence.

### Acceptance Criteria

1. THE admin console (`/admin`) SHALL open with a tab navigation (Tenants · Feature Flags · Webhooks · Audit Logs · Impersonation) using the segmented control or tab component in `bg-surface-raised rounded-lg`.

2. THE tenants tab SHALL list tenants in a sortable table: tenant name, plan, created date (mono), store count (mono), status badge. Row actions (impersonate, view) SHALL be in an overflow dropdown menu, NOT in-row buttons.

3. WHEN impersonation is active, a persistent banner SHALL appear at the top of the shell (above the sidebar): `bg-warn/10 border-b border-warn/20 text-warn` with "Viewing as [tenant name] — Exit" link. This banner SHALL be present on every page while impersonating.

4. FEATURE FLAGS SHALL render as a two-column list: flag name in `font-mono text-sm`, description, toggle switch (Radix Switch, colored orange when on).

---

## Requirement 16: Settings Module

### User Story
As an admin, I want to manage profile, tenant settings, language preferences, and team members from one organized settings page.

### Acceptance Criteria

1. THE settings page SHALL use a left-side settings nav rail (vertical list of settings categories) + right-side content panel — NOT a tab bar at the top.

2. EACH settings section SHALL be visually separated by a `border-t border-hairline` and a section heading in `font-semibold text-ink` with an optional helper line in `text-sm text-ink-soft`.

3. THE profile avatar edit control SHALL show the current avatar (circular, 64px) with an overlay edit button (pencil icon, `bg-accent text-white rounded-full p-1.5`, positioned bottom-right of the avatar).

4. THE team management page SHALL be gated behind `<NeedsBackend>`. The page SHALL render its real layout with blur/lock treatment.

5. THE "Save changes" button SHALL appear in a sticky bottom bar on mobile and inline (right-aligned) on desktop.

---

## Requirement 17: Component Catalogue Standards

### User Story
As a developer building new screens, I want a consistent set of component specifications so that every screen looks cohesive.

### Acceptance Criteria

1. THE `Button` component SHALL have variants: `default` (orange, `bg-accent hover:bg-accent-deep text-white`), `outline` (`border border-hairline text-ink hover:bg-surface-sunken`), `ghost` (`text-ink hover:bg-surface-sunken`), `danger` (`bg-danger text-white`). ALL buttons use `rounded-md` radius and transition `150ms easeOut`. On active press, ALL buttons scale `scale-[0.98]`.

2. THE `Badge`/status pill SHALL follow: `rounded-full px-2 py-0.5 text-xs font-medium`. Colors: success (`bg-success/10 text-success border border-success/20`), warn (`bg-warn/10 text-warn border border-warn/20`), danger (`bg-danger/10 text-danger border border-danger/20`), neutral (`bg-surface-sunken text-ink-soft border border-hairline`).

3. THE `Card` component SHALL use the `.card` utility class: `bg-surface-raised border border-hairline rounded-lg shadow-card`. No additional decorative borders, no colored accent stripes on the left or top edge.

4. THE `Table` component SHALL use: `w-full text-sm`, header `bg-surface-sunken border-b border-hairline text-xs uppercase tracking-wide text-ink-soft font-medium`, rows `border-b border-hairline hover:bg-surface-sunken`, no zebra striping, no outer border.

5. THE `Input` component SHALL use: `bg-surface-sunken border border-hairline rounded-md px-3 py-2 text-sm text-ink`, focus: `ring-2 ring-accent/50 border-accent`, error: `border-danger ring-danger/30`. All numeric inputs use `font-mono`.

6. THE `Skeleton` component SHALL use the `.skeleton` shimmer class from `globals.css`. Each skeleton SHALL mirror the exact dimensions and layout of the final rendered component.

7. THE `EmptyState` component SHALL always include: an icon in `bg-surface-sunken rounded-full p-4` (48px icon well), a `font-semibold text-ink` heading, a `text-sm text-ink-soft` support line, and at most ONE orange CTA. The empty state SHALL never use generic "No data" — every message must be contextually specific.

8. THE `PageHeader` component (already exists) SHALL always have: an eyebrow label (uppercase, `text-ink-soft text-xs tracking-widest font-semibold`), title (`font-bold text-2xl text-ink`), optional subtitle (`text-sm text-ink-soft`), and at most ONE primary orange CTA aligned to the right.

---

## Requirement 18: Asset Generation (kiro-gpt-bridge MCP)

### User Story
As a developer implementing the redesign, I want all visual assets generated through the kiro-gpt-bridge tool so that icons, mockups, and illustrations are premium and consistent.

### Acceptance Criteria

1. BEFORE coding each major page, a UI mockup SHALL be generated using `generate_ui_mockup` with the RADHA Design Bible Block prepended to the brief and the shared negative footer appended.

2. THE design tokens reference board SHALL be generated ONCE at the start using `generate_image` and saved to `radha_dashboard/public/assets/other/radha-tokens-board.png`. This SHALL be referenced when generating all subsequent assets for visual consistency.

3. THE login page illustrative panel SHALL have a hero image generated via `generate_hero` (warm cream background, RADHA wordmark, illustrative retail shelf motif, burnt orange accent, clean cutout objects).

4. NAVIGATION icons (sidebar glyphs) SHALL be generated as an icon set via `generate_icon_set` in batches of 4–6 related glyphs: same line weight (~1.5px), ~2px corner radius, `#57534E` ink-soft color. Generated as SVG-style PNGs, saved to `public/assets/icon/`.

5. ALL generated assets SHALL be saved under `radha_dashboard/public/assets/{category}/{kebab-name}.png` where category is one of: `mockup`, `icon`, `hero`, `illustration`, `other`.

6. WHEN any generated asset fails the anti-slop gate (reads as generic, AI-obvious, or off-brand), it SHALL be re-briefed and regenerated before being used in code.

---

## Requirement 19: Accessibility

### User Story
As a user with accessibility needs, I want the dashboard to be navigable by keyboard and screen reader so that I can use it without a mouse.

### Acceptance Criteria

1. ALL interactive elements SHALL be reachable by keyboard (Tab/Shift-Tab navigation) and visually indicated by the orange focus ring (`outline: 2px solid var(--accent); outline-offset: 2px`).

2. THE skip-to-content link SHALL be the first focusable element on every page, becoming visible on focus with `transform: translateY(0)`.

3. ALL icon-only buttons SHALL have an `aria-label` attribute describing the action.

4. ALL status indicators (colored dots, colored text) SHALL include a text or ARIA label that conveys the status without relying on color alone.

5. ALL data tables SHALL use proper `<th scope="col">` and `<caption>` elements.

6. WHEN `prefers-reduced-motion: reduce` is active, all CSS transitions and animations SHALL be collapsed to `0.01ms` (the base rule in `globals.css` already handles this — components must not use `!important` overrides that break it).

7. ALL form inputs SHALL have a visible `<label>` element (not just a placeholder) associated via `htmlFor`/`id`.

8. THE contrast ratio for all text SHALL meet WCAG AA (4.5:1 for body text, 3:1 for large text). The token system already ensures this for light mode; dark mode token values SHALL be verified during implementation.

---

## Requirement 20: Animation and Motion

### User Story
As a user navigating the dashboard, I want subtle, purposeful motion that makes the interface feel alive and responsive without being distracting.

### Acceptance Criteria

1. ALL button and interactive element hover states SHALL use `transition-colors duration-150` and all transforms SHALL use `transition-transform duration-150`.

2. PAGE content SHALL fade up on mount: `animate-fade-up` (already defined in `tailwind.config.ts` as `fadeUp 200ms cubic-bezier(.23,1,.32,1) both`). Section zones SHALL stagger their fade-up 50ms apart using CSS animation-delay.

3. THE sidebar collapse/expand SHALL animate via `transition: width 280ms cubic-bezier(.23,1,.32,1)` on the sidebar element. Icon labels SHALL fade out on collapse with `opacity-0 transition-opacity duration-120`.

4. KPI numbers SHALL animate from 0 to their target value using a CSS counter animation triggered by `IntersectionObserver` on first viewport entry. Duration: 600ms, easing: `easeOut`.

5. THE OHS gauge arc SHALL animate via SVG `stroke-dashoffset` from full-offset to the score-mapped offset on first viewport entry. Duration: 800ms, easing: `cubic-bezier(.23,1,.32,1)`.

6. WHEN a row/item is added or removed from a list (tasks, notifications, alerts), it SHALL appear/disappear with a 150ms fade + height transition, not an abrupt reflow.

7. NO animation SHALL animate CSS layout properties (`width`, `height`, `padding`, `margin` during scroll). Only `transform` and `opacity`.

8. ALL transitions SHALL use the custom easings: enter → `cubic-bezier(.23,1,.32,1)`, exit → `cubic-bezier(.55,0,1,.45)`.

---

## Requirement 21: Dark Mode

### User Story
As a dashboard user working in low-light conditions, I want a dark mode that preserves the warm brand character rather than inverting to a cold dark theme.

### Acceptance Criteria

1. THE `ThemeToggle` component SHALL toggle `data-theme="dark"` on `document.documentElement`, persist the preference to `localStorage`, and fall back to `prefers-color-scheme` on first visit.

2. WHEN dark mode is active, ALL components SHALL use only the token-system values (which already include dark overrides in `tokens.css`). No component SHALL have hardcoded dark mode conditionals like `dark:bg-gray-900`.

3. THE dark mode surfaces SHALL use the warm dark inversion already defined in tokens: `--surface: #1a1714`, `--surface-raised: #221e1a`, `--surface-sunken: #2a2420` — warm espresso tones, NOT cold gray.

4. CHARTS in dark mode SHALL update their axis/grid colors to use the dark-mode `--hairline` and `--ink-soft` values.

---

## Requirement 22: Playwright Visual Verification

### User Story
As a developer completing the redesign, I want automated visual verification of every redesigned page so that regressions and layout issues are caught and fixed before handover.

### Acceptance Criteria

1. AFTER implementation of each page group, Playwright SHALL navigate to the page in both light and dark modes and take a screenshot.

2. PLAYWRIGHT SHALL verify: no visible console errors, no elements overflowing the viewport horizontally, all primary CTA buttons are visible and not overlapped, and all skeleton/loading states display correctly when API responses are simulated as slow.

3. WHEN Playwright finds a UI issue (overflow, invisible text, broken layout, missing hover state), it SHALL be fixed in the component code before proceeding to the next page group.

4. THE Playwright verification order SHALL follow the nav groups: Auth → Shell → Overview → Operate (Expiry → Tasks → Inventory → GRN → Suppliers → Audit) → Grow (Reports → Analytics → Leads → Billing → Notifications → Stores) → Admin → Settings.

---

## Correctness Properties (Property-Based Testing)

These formal properties define what "correct" means for the RADHA Dashboard visual layer. They are executable via the project's linter + visual test tooling.

### P1: Token Purity
**Property:** For every CSS rule in every `.tsx` component file under `components/`, `features/`, and `app/`, there SHALL exist no raw hex color values, raw `px` spacing values outside the 4pt grid, or `rgba()` values with non-zero chroma that don't map to a design token.
**Test:** Static grep/AST scan — any match is a failure.

### P2: Shadow Constraint
**Property:** No component file SHALL reference `shadow-md`, `shadow-lg`, `shadow-xl`, `shadow-2xl`, `drop-shadow`, or `box-shadow` with alpha > 0.15.
**Test:** Regex scan of all `.tsx` files.

### P3: Single Orange CTA Per Region
**Property:** In any rendered page, there SHALL be at most one element with `bg-accent` styling that is a primary interactive button within any single visual region (page header, section, modal).
**Test:** Playwright DOM query — `document.querySelectorAll('[class*="bg-accent"]')` filtered to buttons per region.

### P4: Mono Numbers
**Property:** Every element that displays a number representing a KPI, count, date, price, EAN, ID, or percentage SHALL have both `font-mono` and `tabular-nums` in its class list.
**Test:** Playwright + custom audit script identifying numeric text nodes and checking their computed font-family.

### P5: Skeleton Completeness
**Property:** Every component that makes an async data fetch (uses `useQuery`) SHALL have a corresponding loading skeleton rendered when `isLoading === true`. The skeleton SHALL have at least one `.skeleton` shimmer element.
**Test:** Component-level test — render with a mocked loading TanStack Query provider and assert at least one `.skeleton` element is present.

### P6: Empty State Completeness
**Property:** Every list/table component SHALL render a non-trivial empty state (containing at minimum a heading and contextually specific message) when its data array is empty.
**Test:** Component-level test — render with empty data prop and assert empty state heading exists and does not equal "No data".

### P7: Accessibility — Focus Ring
**Property:** Every interactive element (button, link, input, select, checkbox) SHALL have a visible focus ring with `outline` color matching `var(--accent)` when focused via keyboard.
**Test:** Playwright accessibility audit — tab through all interactive elements and verify focus indicator visibility.

### P8: Animation Safety
**Property:** No CSS animation or transition in the codebase SHALL animate `top`, `left`, `width`, `height`, `padding`, or `margin` directly. All motion SHALL operate on `transform` and/or `opacity` only.
**Test:** Regex scan of all CSS/Tailwind transition/animation utilities in component files.
