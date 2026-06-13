# PHASE 19 — Hardening (a11y, dark mode, responsive, performance, security review)

## Goal
A cross-cutting polish pass: full accessibility audit, dark-mode toggle, responsive/mobile behavior,
performance tuning, a security review against Doc 3 Part C, and the anti-slop gate across all screens.

## Depends on
Phases 06–18 (all screens exist).

## Doc references
- Doc 2 §2.2 (dark mode), §7 (responsive & a11y), §9 (anti-slop gate).
- Doc 3 Part B (full security design), Part C (delivery checklist).

## Scope (in)
- **Accessibility:** verify 4.5:1 contrast (light + dark separately), visible orange focus rings, tab
  order = visual order, skip-to-content link, `aria-sort` on tables, `aria-live`/`role="alert"` on
  toasts + form errors, chart `aria-label` + data-table fallback, never color-only meaning,
  `prefers-reduced-motion` honored everywhere.
- **Dark mode:** implement the §2.2 tonal inversion via `[data-theme]` toggle (persisted), verify
  contrast independently; accent lifts to `#F26419` on dark.
- **Responsive:** breakpoints `375/768/1024/1280/1536`; sidebar drawer<768 / icon-rail 768–1024 /
  full ≥1024; tables → stacked cards on mobile; charts simplify.
- **Performance:** code-split admin + heavy charts; lazy-load below-fold; memoize tables; tune
  TanStack staleTime; image `next/image` for product cutouts; check bundle size; debounce/throttle.
- **Security review:** walk Doc 3 Part C Security checklist end-to-end; fix gaps.
- **Anti-slop sweep:** run Doc 2 §9 gate on every screen; fix structure not paint.

## Out of scope
New features. Backend changes. The 🆕 surfaces stay gated.

## Step-by-step
1. a11y audit (axe/Lighthouse + manual keyboard + screen-reader spot checks); fix findings.
2. Implement + persist dark-mode toggle; re-verify contrast on every screen in dark.
3. Responsive pass at each breakpoint; convert dense tables to mobile cards.
4. Performance: code-splitting, lazy charts, memoization, image optimization, bundle audit.
5. Security review vs Part C: confirm httpOnly cookies, server re-checks, CSRF, CSP/headers, step-up
   + audit on sensitive ops, Sentry PII scrubbing, `x-request-id` propagation, `npm audit` clean,
   pinned deps, no secrets in bundle.
6. Anti-slop sweep across all screens. Verify.

## API wiring
No new endpoints. Verify all existing wiring still passes scope + handles 401/429/error states.

## Design spec
- Tokens-only confirmed; dark mode per §2.2; motion + reduced-motion correct; one orange CTA per
  region everywhere; mono numbers; no banned styles (§9).

## Security checks (Doc 3 Part C — Security)
- [ ] Tokens in httpOnly Secure SameSite cookies; none in localStorage/URL.
- [ ] Middleware + server re-check for role/permission; client gate cosmetic only.
- [ ] CSRF on browser mutations; mutations via server actions.
- [ ] CSP + HSTS + nosniff + frame-deny + referrer-policy set.
- [ ] Step-up + audit on impersonation/refund/destructive/bulk/broadcast.
- [ ] Sentry scrubs PII/tokens; `x-request-id` propagated.
- [ ] `npm audit` clean; deps pinned; no secrets in bundle.

## Acceptance criteria
- [ ] a11y: contrast/focus/keyboard/aria/reduced-motion all pass (light + dark).
- [ ] Dark mode shipped + persisted + contrast-verified.
- [ ] Responsive correct at all five breakpoints.
- [ ] Performance: code-split + lazy + bundle within budget; no obvious jank.
- [ ] Doc 3 Part C security checklist fully ticked.
- [ ] Anti-slop gate passes on every screen. `build`+`typecheck`+`lint` clean.

## Verification
- `npm run typecheck && npm run lint && npm run build`.
- `npm audit` clean (or documented). Lighthouse a11y + perf run.
- User: toggle dark mode on each screen; navigate at 375/1024/1536; tab-only navigation; reduced-motion on.

## Rollback note
Mostly in-place refinements + a theme toggle. Revert the dark-mode toggle and any regressions per file
via git. No feature removal.
