# PHASE 02 — Design-system primitives

## Goal
Implement the Doc 2 §4 component catalogue as a themed, reusable component library and a
`/styleguide` page that renders every component in all its states — the single visual reference
the rest of the app composes from.

## Depends on
Phase 01 (tokens, Tailwind, shadcn/ui, fonts).

## Doc references
- Doc 2 §4 (component catalogue 4.1–4.15), §2 (tokens), §2.5 (motion), §7 (a11y), §9 (anti-slop).
- Doc 3 §A.5 (loading/empty/error model), Part C Design checklist.

## Scope (in)
Under `radha_dashboard/components/ui/` (shadcn-themed where applicable) + a styleguide route:
- `kpi-tile.tsx` (4.1) — category glyph + mono count-up number + label + trend chip + optional
  "Action needed ›". Props: `label, value, format, trend, tint, href?, state`.
- `data-table.tsx` (4.2) — sticky header, `aria-sort`, zebra, mono numeric cols, row hover/actions,
  sticky first col, cursor pagination footer, column show/hide, CSV export, empty/error/skeleton rows.
  Generic `<DataTable<T>>` with column defs.
- `chart-card.tsx` (4.3) — eyebrow + title + range chip + interactive legend wrapper; thin wrappers
  `LineTrend`, `BarCompare`, `Donut`, `Funnel` (Recharts, token-themed), tooltip keyboard-reachable,
  reduced-motion safe, empty/error.
- `filter-bar.tsx` (4.4) — segmented control with sliding orange indicator (transform-animated),
  date-range picker, multi-select chips, search input with orange focus ring; sticky on scroll.
- `status-chip.tsx` (4.5) — icon + label, tint bg 8% + border 35%; variants matched/expired/
  expiring/pending; always `aria-label`.
- `ohs-gauge.tsx` (4.6) — circular arc sweep 0→value, mono center, dashed "–" pending, 6 component bars.
- `side-panel.tsx` (4.7) — right slide-in drawer, `xl` left radius, scrim, confirm-on-dismiss-if-dirty.
- `modal.tsx` (4.8) — centered scale `0.96→1`; destructive variant (danger CTA separated); undo-toast hook.
- `form-field.tsx` (4.9) — cream field, hairline, orange focus ring, visible label, mono numeric,
  inline validation on blur, helper text, required asterisk (built on RHF + shadcn `Form`).
- `page-header.tsx` (4.10) — eyebrow + `w800` title + subtitle + one orange CTA + ghost actions + tabs.
- `states.tsx` (4.11) — `<EmptyState>`, `<ErrorState>` (retry), `<Skeleton>` blocks (reduced-motion shimmer).
- `locked-overlay.tsx` (4.12) — real layout + blur/scrim + lock glyph + plan CTA.
- `toast.tsx` / `toaster.tsx` (4.13) — `aria-live="polite"`, auto-dismiss 3–5s, action; `offline-banner.tsx` pinned.
- `activity-item.tsx` (4.14) — monogram + actor + action + target + mono timestamp + type glyph tint.
- `command-palette.tsx` (4.15) — ⌘K fuzzy nav + actions (shadcn `Command` themed); wired in Phase 04.
- `button.tsx`, `chip.tsx`, `eyebrow.tsx`, `mono-number.tsx` (count-up hook honoring reduced-motion).
- `app/(misc)/styleguide/page.tsx` — renders all components × states (default/hover/pressed/loading/
  disabled/empty/error). Dev-only (gate from prod nav).

## Out of scope
No API calls, no real data (use static fixtures in the styleguide), no auth, no app shell.

## Step-by-step
1. Add shadcn primitives used as bases: `npx shadcn@latest add button dialog dropdown-menu command
   table tabs popover tooltip toast form input select checkbox`. Re-theme each to RADHA tokens
   (cream surfaces, orange focus ring, hairline borders) — strip default blue/violet.
2. Build `mono-number.tsx` with a `useCountUp(value, {durationMs:600})` hook (rAF-based) that
   renders final value instantly under `prefers-reduced-motion`.
3. Build primitives in the order listed; each exports a typed props interface and supports the full
   state matrix. Press-scale `0.98` via a shared `pressable` utility (transform only).
4. Token discipline: every color/space/radius reads a CSS var or Tailwind token mapped to one.
   No raw hex. One orange CTA per region enforced by `<PageHeader>` API (single `primaryAction`).
5. Charts: theme Recharts (axis/grid low-contrast hairline, accent series, tabular tick formatter,
   `isAnimationActive={!reducedMotion}`); always pass through `<ChartCard>` with empty/error.
6. Build `/styleguide` enumerating each component and state; add a contrast/focus sanity row.
7. Verify.

## API wiring
None. Components are data-shape-agnostic (generic props). Real wiring begins Phase 05.

## Design spec
- Exact tokens from Doc 2 §2; motion durations §2.5 (micro 120–200ms, panels 200–320ms, exit ~70%,
  transform/opacity only, reduced-motion honored). Eyebrow labels 11–12px `w600` +0.06em uppercase.
- Mono for all numbers/dates/EAN/money (tabular). Soft warm shadow `--shadow-card`; never nest cards.
- Anti-slop gate (§9): no gradients/neon/glass/pure-black/emoji/Material-clone/gradient-text.

## Security checks
- Output encoding: components rely on React escaping; **no** `dangerouslySetInnerHTML` with
  external content (Doc 3 §B.4). If rich text ever needed, sanitize with DOMPurify (note in code).
- `/styleguide` must not ship to prod nav / must be excluded or guarded (no data leakage).

## Acceptance criteria
- [ ] Every Doc 2 §4 component (4.1–4.15) exists, typed, token-only.
- [ ] `/styleguide` renders each component across default/loading/empty/error/disabled.
- [ ] Numbers render in JetBrains Mono and count up (instant under reduced-motion).
- [ ] Focus rings are orange and visible; status chips/charts have `aria-label`/data fallback.
- [ ] `npm run build` + `typecheck` clean; anti-slop gate passes on the styleguide.

## Verification
- `npm run typecheck && npm run lint && npm run build`.
- User opens `/styleguide`; tab through to confirm focus rings + keyboard reachability; toggle OS
  reduced-motion and confirm animations stop; eyeball against Doc 2 §4 specs.

## Rollback note
Additive: all new files under `components/ui/` + one styleguide route. Revert by deleting those
files; nothing else depends on them yet.
