# PHASE 04 — App shell & navigation

## Goal
Build the adaptive dashboard shell: sidebar + top bar, store switcher, global date-range, ⌘K
command palette, role-gated navigation, and a notifications bell — the frame every screen renders into.

## Depends on
Phase 02 (command palette, primitives), Phase 03 (session, RBAC gates).

## Doc references
- Doc 2 §3 (app shell layout), §3.1 (navigation rules), §4.15 (command palette), §7 (responsive).
- Doc 1 §6.3 (`/stores` for switcher), §6.1 (`/dashboard/multi-store` route target), §6.17 (notifications bell).
- Doc 3 §B.3 (least privilege / code-split admin), §A.2 (`useStoreScope`, `useDateRange`).

## Scope (in)
- `app/(dash)/layout.tsx` — server layout: re-checks session (redirect if none), renders
  `<Sidebar>` + `<TopBar>` + `{children}` on the cream canvas. Code-splits the Admin nav group for
  `role==='admin'` only.
- `components/shell/sidebar.tsx` — groups **Operate / Grow / Admin / Settings** (Doc 2 §3.1); active
  item = orange left indicator + accent-tint bg + `w600`; icon+label; role/permission-gated items;
  locked tooltip for unavailable-but-visible destinations (not silent hide for paid).
- `components/shell/top-bar.tsx` — RADHA mark, store switcher, global search trigger (⌘K), date-range,
  notifications bell, avatar menu (profile/settings/logout).
- `components/shell/store-switcher.tsx` — populated from `GET /stores`; owners get "All stores" →
  routes to multi-store overview; selection drives `?storeId=` globally.
- `components/shell/date-range.tsx` — global `from`/`to` control.
- `components/shell/notifications-bell.tsx` — unread count from `GET /notifications` (throttled poll);
  opens inbox popover (full inbox in Phase 15).
- `lib/hooks/use-store-scope.ts` — current `storeId` (URL/searchParams + context), guarded to
  `session.storeIds`; never lets a user select outside scope.
- `lib/hooks/use-date-range.ts` — global date range (URL-synced).
- `components/shell/command-palette-provider.tsx` — wires ⌘K: fuzzy nav to pages/stores + quick
  actions (new task/GRN, export). Recent items, keyboard-first.
- `components/shell/breadcrumbs.tsx` — for 3+ level drill-downs.
- Responsive behavior: full sidebar ≥1024, icon-rail 768–1024, slide-in drawer <768 (Doc 2 §7).
- Placeholder pages for each nav destination (`/`, `/stores`, `/expiry`, … `/settings`) so nav works
  before the real screens land (each = `<PageHeader>` + an "implemented in Phase NN" `<EmptyState>`).

## Out of scope
Real screen content (Phases 06–17), the full notifications inbox (Phase 15), the API client
(Phase 05 — this phase may use minimal `/stores` + `/notifications` fetch via temporary server
helpers, refactored onto `apiFetch` in Phase 05).

## Step-by-step
1. Build `(dash)/layout.tsx` with server-side session re-check + role-derived nav config.
2. Sidebar: define nav config as data (`{label, href, icon, group, requires?}`); filter by
   `can()/hasRole()`; render groups with eyebrow group labels; active state from `usePathname`.
3. Top bar: compose store switcher + date-range + ⌘K trigger + bell + avatar; sticky, hairline bottom.
4. Store switcher: query `/stores`, render shadcn `Select`/`Command`; persist selection to URL
   (`?storeId=`) + context via `useStoreScope`; guard to `session.storeIds`; "All stores" for owner.
5. Command palette provider mounts at shell root; register page routes + quick actions; ⌘K / Ctrl-K.
6. Implement responsive sidebar (CSS + a `useMediaQuery`): drawer below 768 with overlay + focus trap.
7. Add placeholder pages for every nav route. Breadcrumbs component ready for drill-downs.
8. Verify.

## API wiring
- `GET /api/v1/stores` → store list for the switcher (role-scoped server-side).
- `GET /api/v1/notifications` → unread count for the bell (throttled poll, Doc 3 §B.8).
- Store scope: every downstream data call (later phases) reads `useStoreScope().storeId`.

## Design spec
- Layout exactly per Doc 2 §3 ASCII (sidebar 240px, top bar). Active nav = orange indicator +
  accent-tint. One orange CTA max per region. Eyebrow group labels. Warm shadow, hairline dividers.
- Motion: sidebar/drawer 200–320ms `cubic-bezier(.23,1,.32,1)`, exit faster; reduced-motion safe.
- All shell states: store list loading skeleton, empty ("Add your first store"), error retry.

## Security checks
- Admin nav group + its route bundle code-split, loaded only for `role==='admin'` (Doc 3 §B.3).
- Store switcher cannot select a store outside `session.storeIds`; cross-scope attempt is ignored
  (and would 403 at the API anyway).
- Server layout re-checks session/role — middleware presence-check is not trusted alone.

## Acceptance criteria
- [ ] Shell renders with sidebar + top bar; nav reflects role (admin sees Admin group, others don't).
- [ ] Store switcher loads `/stores`, sets `?storeId=`, and is scope-guarded; owner sees "All stores".
- [ ] ⌘K opens, fuzzy-navigates, and runs at least the registered quick actions.
- [ ] Notifications bell shows unread count (throttled).
- [ ] Responsive: full/icon-rail/drawer at the three breakpoints; drawer traps focus.
- [ ] Every nav link routes to a placeholder page; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: log in, confirm nav groups per role, switch stores (URL updates), open ⌘K and jump pages,
  resize to 1024/768/375 to see sidebar adapt, tab-navigate the shell for focus order.

## Rollback note
Additive shell components + `(dash)/layout.tsx` + placeholder pages. Revert by removing
`components/shell/*` and the layout; placeholder pages can stay or be deleted. No backend impact.
