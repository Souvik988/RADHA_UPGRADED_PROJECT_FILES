# Implementation Plan: Dashboard Production Ready

## Overview

This plan hardens the existing RADHA web dashboard (`radha_dashboard/`, Next.js 15 App Router,
TypeScript, React 19) into a production-ready, demoable state. It is an improvement effort: it
reorganizes and tightens existing code rather than adding product features. Work proceeds bottom-up —
shared types and pure modules first (scope filtering, redirect validation, session/retry decisions,
image-source selection, proxy resolution), then the server proxy and session/auth wiring, then the
scan, image, navigation, and visual layers, finishing with cross-cutting error handling and
smoke/lint/perf verification.

Implementation language: **TypeScript**. Property-based tests use **fast-check** with **Vitest** (added
as dev dependencies), each running a minimum of 100 generated cases. Component tests use React Testing
Library; timing percentiles use the existing Playwright harness. Test sub-tasks are marked `*`
(optional) and are placed close to the implementation they validate so regressions surface early.

## Tasks

- [x] 1. Set up test tooling and shared scope types
  - [x] 1.1 Add and configure Vitest + fast-check + React Testing Library
    - Add `vitest`, `fast-check`, `@testing-library/react`, `@testing-library/jest-dom`, and `jsdom`
      as dev dependencies in `radha_dashboard/package.json`
    - Add `vitest.config.ts` (jsdom environment, path aliases matching `tsconfig.json`) and a `test`
      script (`vitest run`)
    - Add a shared property-test setup note/helper enforcing `fc.assert(..., { numRuns: 100 })`
    - _Requirements: 1.1, 9.1 (test infrastructure for all properties)_

  - [x] 1.2 Define shared scope types
    - Create `lib/api/core/scope-types.ts` exporting `Role`, `Scoped`, and `StoreScope`
      (`tenantId`, `storeId: string | null`, `role`)
    - _Requirements: 8.4_

- [x] 2. Implement Demo_Data_Provider (server-only)
  - [x] 2.1 Implement scope filtering
    - Create `lib/demo/scope.ts` with `import 'server-only'`, `Scoped`/`StoreScope` re-exports, and the
      pure `filterByScope` (tenant match required; `storeId === null` rollup includes all; tenant-level
      records visible under rollup)
    - _Requirements: 1.4, 8.4_

  - [x] 2.2 Write property test for scope filtering
    - **Property 3: Scope filtering keeps only in-scope records**
    - **Validates: Requirements 1.4, 8.4**

  - [x] 2.3 Implement demo dataset registry
    - Create `lib/demo/index.ts` with `import 'server-only'`, the `FeatureArea` union, `DemoDataset`
      shape, and `getDemoDataset(area, scope)` that returns the scoped dataset or `null`, logging the
      missing-dataset indication exactly once per area without throwing
    - _Requirements: 1.3, 1.7_

  - [x] 2.6 Create per-Feature_Area demo dataset modules
    - Create `lib/demo/data/{overview,analytics,audit,expiry,grn,inventory,tasks,billing,suppliers,
      reports,notifications,settings,admin}.ts`, each `import 'server-only'`, exporting scoped records
      tagged with `tenantId`/`storeId`: ≥1 record per primary region, ≥5 per list/table region
    - Wire each module into the `lib/demo/index.ts` registry (exactly one dataset per Feature_Area)
    - _Requirements: 1.1, 1.3_

  - [x] 2.4 Write property test for demo coverage minimums
    - **Property 1: Demo datasets meet coverage minimums**
    - **Validates: Requirements 1.1**

  - [x] 2.5 Write property test for missing demo dataset handling
    - **Property 6: Missing demo dataset yields an empty state and a log, never a crash**
    - **Validates: Requirements 1.7**

- [x] 3. Harden the API_Proxy (honest-data + scope resolution)
  - [x] 3.1 Implement the scope guard
    - Create `lib/api/core/scope-guard.ts` with `import 'server-only'` and `assertRecordsInScope`
      (throws `CrossScopeError` when any record's `tenantId`/`storeId` is outside the active scope)
    - _Requirements: 8.6_

  - [x] 3.2 Write property test for the scope guard
    - **Property 23: Out-of-scope responses are rejected wholesale**
    - **Validates: Requirements 8.6**

  - [x] 3.3 Implement resolveFeatureData
    - Create `lib/api/core/resolve.ts` with `import 'server-only'`, the `ResolveResult<T>` union, and
      `resolveFeatureData` encoding: demo-on → `selectDemo` (or `empty` + log when missing, never
      backend); demo-off → `fetchReal` + `assertScope`, mapping non-2xx (≠401)/timeout/abort and
      schema-validation failures to `error`, empty backend to `empty`, scope mismatch to
      `error{code:'CROSS_SCOPE'}`, and never emitting demo-origin values
    - _Requirements: 1.2, 1.7, 2.4, 2.5, 2.6, 8.6, 10.1, 10.2, 10.4_

  - [x] 3.4 Write property test for defined demo region resolution
    - **Property 2: A defined demo region always resolves non-empty in demo mode**
    - **Validates: Requirements 1.2**

  - [x] 3.5 Write property test for honest-data isolation
    - **Property 4: Demo-origin data never appears when demo mode is off**
    - **Validates: Requirements 2.4, 2.5**

  - [x] 3.6 Write property test for empty backend mapping
    - **Property 5: Empty backend result maps to an empty state, not demo data**
    - **Validates: Requirements 2.6**

  - [x] 3.7 Write property test for backend-failure mapping
    - **Property 24: Backend failures map to a region error, not data**
    - **Validates: Requirements 10.1, 10.2, 10.4**

  - [x] 3.8 Refactor route handlers onto resolveFeatureData
    - Rewrite each `app/api/*` Feature_Area handler to call `resolveFeatureData`, forward the session
      `tenantId` plus active `storeId` (or owner/admin tenant-rollup marker) to the backend, and wrap
      every backend call in a 30s `AbortController`
    - Remove all inline `DEMO_*` constants and the `try backend / catch { return DEMO_* }` fallbacks
    - _Requirements: 1.6, 8.1, 8.3, 10.2_

  - [x] 3.9 Write property test for forwarded scope
    - **Property 20: Forwarded scope always carries the session tenant and the active store**
    - **Validates: Requirements 8.1, 8.3, 8.4**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Harden the Session_Manager
  - [x] 5.1 Implement safe redirect-target validation
    - Create `lib/auth/next-param.ts` with pure `isSafeNextPath` (single leading `/`, no `//`/`/\`, no
      scheme/authority, no control chars, ≤2048) and `safeNextOrHome`
    - _Requirements: 7.1, 7.2, 7.3_

  - [x] 5.2 Write property test for next-param validation
    - **Property 18: `next` redirect targets are same-origin relative paths only**
    - **Validates: Requirements 7.1, 7.2, 7.3**

  - [x] 5.3 Implement transient-error retry schedule
    - Create `lib/auth/retry.ts` with pure `isTransient` (502/503/504, `'timeout'`, `'no-response'`)
      and `backoffSchedule` (`[1000, 2000, 4000]`, factor 2, cap 8000)
    - _Requirements: 6.3_

  - [x] 5.4 Write property test for the backoff schedule
    - **Property 13: Retry backoff schedule is bounded and monotonic**
    - **Validates: Requirements 6.3**

  - [x] 5.5 Implement single-flight refresh lock
    - Create `lib/auth/refresh-lock.ts` with `refreshOnce` (module-level in-flight promise cleared on
      settle)
    - _Requirements: 6.6_

  - [x] 5.6 Write property test for single-flight refresh
    - **Property 16: Token refresh is single-flight under concurrency**
    - **Validates: Requirements 6.6**

  - [x] 5.7 Harden session helpers
    - In `lib/auth/session.ts`, ensure `isTokenExpiringSoon` is exact (`expiresAt - now < 60000`) and
      `getSession` returns `null` on absent/unparseable cookie without throwing
    - _Requirements: 6.4, 6.1, 6.7, 7.7_

  - [x] 5.8 Write property test for the token-expiry predicate
    - **Property 14: Token-expiry predicate is exact**
    - **Validates: Requirements 6.4**

  - [x] 5.9 Write property test for unparseable-cookie handling
    - **Property 17: Unparseable or invalid cookies are treated as unauthenticated**
    - **Validates: Requirements 6.1, 6.7, 7.7**

  - [x] 5.10 Wire the server fetcher and auth routes
    - In `lib/api/core/api-fetch.ts`, apply `isTransient`/`backoffSchedule` retry for `/api/auth/me`
      (retaining the cookie throughout and on exhaustion), proactive refresh when within 60s of expiry
      (≤5s), and `refreshOnce` single-flight on 401; on hard refresh failure clear the cookie, drop
      client session state, and redirect to `/login` within 1s with a validated `next`
    - Update `app/api/auth/{me,refresh,logout}` handlers to match (no spurious logout on transient
      failure; tokens never returned to the client)
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 5.11 Write property test for transient-failure session preservation
    - **Property 12: Transient `/me` failures preserve the session**
    - **Validates: Requirements 6.2**

  - [x] 5.12 Write property test for hard refresh failure
    - **Property 15: Hard refresh failure clears the session and redirects safely**
    - **Validates: Requirements 6.5**

- [x] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Close the Auth_Gateway redirect and role holes
  - [x] 7.1 Harden middleware presence gate
    - Update `middleware.ts` to validate every `next` via `safeNextOrHome`/`isSafeNextPath`, treat an
      unparseable cookie as unauthenticated, and apply a cosmetic `/admin/*` role check redirecting
      non-admins to `/403`
    - _Requirements: 7.1, 7.2, 7.3, 7.7_

  - [x] 7.2 Re-verify session and enforce role in the (dash) layout
    - Update `app/(dash)/layout.tsx` to call `getSession()` server-side before rendering any
      Feature_Area data, redirect to `/login` with a validated `next` on failure, and redirect admin
      segments to `/403` for insufficient roles (rendering no admin data first)
    - _Requirements: 7.4, 7.5, 7.6_

  - [x] 7.3 Write property test for the admin-route gate
    - **Property 19: Admin routes admit only owner and admin roles**
    - **Validates: Requirements 7.4**

  - [x] 7.4 Write component test for layout redirect safety
    - Assert a null/invalid session renders no Feature_Area data and redirects to `/login` with a
      validated same-origin `next`
    - _Requirements: 7.6_

- [x] 8. Enforce store-scope integrity
  - [x] 8.1 Clamp selectable store scope
    - Update `lib/hooks/use-store-scope.ts` to clamp non-owner/non-admin roles to assigned
      `session.storeIds`, and gate the "all stores" rollup to owner/admin
    - _Requirements: 8.2, 8.5_

  - [x] 8.2 Write property test for store clamping
    - **Property 21: Selectable store is clamped to assigned stores**
    - **Validates: Requirements 8.5**

  - [x] 8.3 Write property test for the rollup gate
    - **Property 22: Rollup view is shown only to owner/admin with no store selected**
    - **Validates: Requirements 8.2**

  - [x] 8.4 Wire scope-change refetch and stale abandonment
    - Ensure TanStack Query keys include `storeId`/scope so a scope change refetches within 2s, shows a
      loading state, and abandons stale in-flight responses keyed to the previous scope
    - _Requirements: 8.7, 8.8_

  - [x] 8.5 Write component test for scope-change behavior
    - Assert demo/real data updates to the new scope and previous-scope data is not shown during refetch
    - _Requirements: 1.5, 8.7, 8.8_

- [x] 9. Build the Scan_Result_View and scan proxy
  - [x] 9.1 Implement scan pure logic and view model
    - Create `features/audit/scan.types.ts` and pure helpers: `mapVerification` (total, single-valued),
      a result builder that always retains the exact `barcode` and `scannedAt`, a store-scope local
      timestamp formatter, and a placeholder marker for null/token product names (never fabricated)
    - _Requirements: 3.3, 3.4, 3.5, 3.8_

  - [x] 9.2 Write property test for verification status
    - **Property 7: Verification status is total and single-valued**
    - **Validates: Requirements 3.3**

  - [x] 9.3 Write property test for barcode preservation
    - **Property 8: Scan result preserves the exact scanned barcode**
    - **Validates: Requirements 3.4, 3.5**

  - [x] 9.4 Write property test for non-fabricated names
    - **Property 9: Product names are never fabricated**
    - **Validates: Requirements 3.8**

  - [x] 9.5 Implement the store-scoped scan proxy
    - Create `app/api/audit/scan/route.ts` bounding the backend lookup to 5s, mapping outcomes to
      `matched`/`not in list`/`invalid`, returning a `not in list` result on no match within 5s, and
      returning a demo product within 1s when demo mode is active
    - _Requirements: 3.1, 3.5, 3.9_

  - [x] 9.6 Implement the Scan_Result_View UI
    - Render loading state on submit (clearing any prior result), product name/EAN, verification
      status, store-scope timestamp and exact barcode, and an error state with a retry action that
      re-submits while keeping the barcode visible
    - _Requirements: 3.1, 3.2, 3.6, 3.7_

  - [x] 9.7 Write component test for scan UI behavior
    - Cover request initiation, field rendering, prior-result clearing, error/retry wiring, and demo scan
    - _Requirements: 3.1, 3.2, 3.6, 3.7, 3.9_

- [x] 10. Build the Product_Image_Service
  - [x] 10.1 Implement the image-source state machine
    - Create `features/_shared/product-image/resolve-image.ts` with pure `chooseImageSource`
      (backend URL → backend; empty URL + non-empty EAN → off; both empty → placeholder, no OFF request)
      and the `ImageState` transitions terminating in `image` or `placeholder`
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 10.2 Write property test for image-source selection
    - **Property 10: Image source selection follows the resolution order**
    - **Validates: Requirements 4.1, 4.2, 4.4**

  - [x] 10.3 Write property test for image resolution termination
    - **Property 11: Image resolution always terminates in image or placeholder**
    - **Validates: Requirements 4.3, 4.5, 4.6**

  - [x] 10.5 Permit the Open Food Facts image host
    - Extend `next.config.mjs` `images.remotePatterns` and the CSP `img-src` to allow the Open Food
      Facts image host
    - _Requirements: 4.8_

  - [x] 10.4 Implement the <ProductImage> component and resolve proxy
    - Build a fixed-dimension (token `width`/`height`) `<ProductImage>` with zero layout shift, an OFF
      lookup via the backend integration with a 5s timeout, a skeleton/placeholder occupying the same
      box, and an `onError` placeholder with a non-text broken-image indicator
    - _Requirements: 4.7, 4.9, 4.6_

  - [x] 10.6 Write component test for zero layout shift
    - Assert the cell's outer dimensions are unchanged before/during/after load
    - _Requirements: 4.7, 4.9_

- [x] 11. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Improve navigation performance and designed states
  - [x] 12.1 Add route skeletons and a persistent shell
    - Add `loading.tsx` to each `(dash)` route segment and render a persistent, interactive `DashShell`
      from the layout that stays mounted during data loads
    - _Requirements: 5.2, 5.4_

  - [x] 12.2 Configure cache-then-revalidate and region guards
    - Set TanStack Query `staleTime`/`gcTime` for cached revisits within 500ms with background
      revalidation, update on differing data, and a per-region 10s guard that swaps skeletons to an
      error state with retry
    - _Requirements: 5.5, 5.6, 5.7_

  - [x] 12.3 Implement designed system states
    - Create `components/system/` `EmptyState` (tonal icon, title, one support line, one orange CTA),
      `RegionSkeleton` (block layout matching final content), and `RegionError` (error indication +
      retry, preserving sibling regions)
    - _Requirements: 9.4, 9.5, 9.6_

  - [x] 12.4 Implement the Demo_Indicator
    - Create `components/system/demo-indicator.tsx` rendered in `DashShell` whenever the session is a
      demo session: persistent across scroll and navigation, marking content as sample/demo data,
      absent when demo mode is off, and toggling within 1s via session state (no reload)
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 12.5 Write component test for the Demo_Indicator
    - Cover presence, absence, and toggle within 1s without reload
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 12.6 Write component test for navigation behavior
    - Cover skeleton-on-navigation, cached revisit, 10s error swap, and background-update render
    - _Requirements: 5.2, 5.5, 5.6, 5.7_

- [x] 13. Enforce visual quality and design consistency
  - [x] 13.1 Apply brand foundations and tokens-only styling
    - Enforce the cream `#FFFBF5` canvas, ink `#1C1917`, Plus Jakarta Sans, and JetBrains Mono for
      numeric values in `app/layout.tsx`/`globals.css`; refactor feature components to read tokens only,
      apply one-orange-CTA-per-region primitives, reduced-motion suppression, and visible orange focus
      rings with accessible names
    - _Requirements: 9.2, 9.3, 9.7, 9.8_

  - [x] 13.2 Add a token-lint guard
    - Add an ESLint rule (or token-lint script) flagging hard-coded color/spacing/radius/duration
      literals in `features/**` and `components/**`
    - _Requirements: 9.1_

  - [x] 13.3 Write component test for visual rules
    - Cover brand foundations applied, one-CTA-per-region, designed empty/skeleton/error, reduced-motion,
      and focus/accessible-name
    - _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

- [x] 14. Wire cross-cutting error handling
  - [x] 14.1 Integrate region error/retry and login-redirect policy
    - Wire `RegionError` + per-region TanStack queries so a failed region shows error+retry while
      siblings keep their last data, retry re-issues only that region's request (loading state), and
      only `UnauthorizedError` (Requirement 6) ever redirects to login
    - _Requirements: 10.1, 10.4, 10.5, 10.6_

  - [x] 14.2 Write property test for login-redirect policy
    - **Property 25: Only authentication failures redirect to login**
    - **Validates: Requirements 10.6**

  - [x] 14.3 Write component test for region error isolation
    - Cover per-region retry isolation and timeout-to-error rendering
    - _Requirements: 10.3, 10.5_

- [x] 15. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 16. Verify production-readiness invariants
  - [x] 16.1 Write smoke/lint checks
    - Assert exactly one demo dataset module per Feature_Area with no inline `DEMO_*` constants in
      `app/api/*` (R1.3, R1.6); every `lib/demo/*` begins with `import 'server-only'` (R2.7); OFF host
      present in `next.config.mjs` and CSP (R4.8); `(dash)/layout.tsx` calls `getSession` before
      rendering children (R7.5); responses and logs contain no token fields and the cookie is `httpOnly`
      (R7.8)
    - _Requirements: 1.3, 1.6, 2.7, 4.8, 7.5, 7.8_

  - [x] 16.2 Add a navigation performance harness
    - Use the existing Playwright harness against a warm session to assert header/shell within 1s for
      ≥95% of navigations, primary data within 2.5s for ≥95%, and shell responsiveness during load
    - _Requirements: 5.1, 5.3, 5.4_

## Notes

- Tasks marked with `*` are optional test sub-tasks and can be skipped for a faster MVP.
- Each task references specific requirement sub-clauses for traceability; property tests cite both the
  design property number and the requirement clauses they validate.
- All 25 correctness properties from the design map to exactly one property-based test each:
  P1→2.4, P2→3.4, P3→2.2, P4→3.5, P5→3.6, P6→2.5, P7→9.2, P8→9.3, P9→9.4, P10→10.2, P11→10.3,
  P12→5.11, P13→5.4, P14→5.8, P15→5.12, P16→5.6, P17→5.9, P18→5.2, P19→7.3, P20→3.9, P21→8.2,
  P22→8.3, P23→3.2, P24→3.7, P25→14.2.
- Property tests use fast-check (`numRuns: 100` minimum) and are tagged
  `// Feature: dashboard-production-ready, Property {n}: {text}`.
- Honest-data discipline and multi-tenant scoping are preserved throughout; no new product features are
  added.
- Checkpoints ensure incremental validation; run `npm run typecheck`, `npm run lint`, and `vitest run`
  at each.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "2.3", "3.1", "5.1", "5.3", "5.5", "5.7", "9.1", "10.1"] },
    { "id": 2, "tasks": ["2.2", "2.6", "3.2", "3.3", "5.2", "5.4", "5.6", "5.8", "5.9", "8.1", "9.2", "9.3", "9.4", "10.2", "10.3", "10.5"] },
    { "id": 3, "tasks": ["2.4", "2.5", "3.4", "3.5", "3.6", "3.7", "3.8", "5.10", "7.1", "7.2", "8.2", "8.3", "8.4", "9.5", "9.6", "10.4", "12.3", "13.2"] },
    { "id": 4, "tasks": ["3.9", "5.11", "5.12", "7.3", "7.4", "8.5", "9.7", "10.6", "12.1", "12.2", "13.1"] },
    { "id": 5, "tasks": ["12.4", "12.5", "12.6", "13.3", "14.1", "14.2", "14.3", "16.1", "16.2"] }
  ]
}
```
