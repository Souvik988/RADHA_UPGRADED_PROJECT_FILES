# Phase FE-05: Navigation + Routing

## Phase Metadata
- **Phase ID**: FE-05
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-01
- **Blocks**: FE-07 (auth state needs guards), FE-09+ (every screen registers a route)
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal
Stand up the app's entire navigation graph using `GoRouter 14`. Define type-safe routes for every screen the roadmap will ship (40 phases × ~1.5 routes/phase ≈ 60 routes). Wire up:
- a single redirect-based **auth guard** (uninvited users routed to splash → segment cards → OTP);
- a **role-based redirect** that splits Consumer vs Business on every navigation;
- **deep links** (`radha://` and `https://radha.app/...`) to scan-by-EAN, recall-detail, family-invite-accept, business-activation;
- a **modal stack** above the main shell that survives back-press correctly on Android (predictive-back-aware);
- a **bottom navigation shell** with two layouts (Consumer 4 tabs, Business 5 tabs) that swap based on role without a route flush.

This phase ships placeholder destination widgets — actual screens come later. What ships now is the routing graph and the guard logic that the next 35 phases trust.

## Why This Phase Matters
- **Deep links are the cheapest re-engagement channel.** Recall alerts, weekly digests, family invites all use them. Wrong now = months of spaghetti later.
- **One redirect engine** (instead of per-screen `if (!authenticated) return` checks) keeps auth correctness verifiable.
- **Predictive back** on Android 14+ ships in 2026; getting it wrong means the app feels broken on millions of devices.
- **Role-based shell swap** is the architectural move that keeps the dual-mode design (Consumer / Business) from polluting every feature with `if (role == ...)`.
- **Type-safe route params** prevent classes of bugs that 2024-era Flutter apps hit constantly (string typos, missing path params).

## Prerequisites
- [ ] Backend: BE-08 (roles), BE-34 (segment) — used by guard, but only via mock state in this phase.
- [ ] Earlier FE: FE-01.
- [ ] Design: route map diagram from designer (60 boxes + lines).
- [ ] Domains: `radha.app` (web universal links), `radha://` (custom scheme) for deep links.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/app/router/app_router.dart` | `GoRouter` instance + redirect engine |
| `apps/mobile/lib/app/router/routes.dart` | Type-safe `RadhaRoutes` enum + path builders |
| `apps/mobile/lib/app/router/guards/auth_guard.dart` | Authenticated check |
| `apps/mobile/lib/app/router/guards/role_guard.dart` | Consumer vs Business split |
| `apps/mobile/lib/app/router/guards/onboarding_guard.dart` | First-launch → splash → segment |
| `apps/mobile/lib/app/router/deep_link_handler.dart` | URL parser + open intent |
| `apps/mobile/lib/app/router/route_observer.dart` | Logs every push/pop to analytics + Sentry breadcrumb |
| `apps/mobile/lib/app/router/transition_builders.dart` | Custom transitions (slide, fade, expressive) |
| `apps/mobile/lib/app/shell/consumer_shell.dart` | Bottom nav for Consumer (Scan, Calendar, Recalls, Profile) |
| `apps/mobile/lib/app/shell/business_shell.dart` | Bottom nav for Business (Dashboard, Audit, GRN, Tasks, More) |
| `apps/mobile/lib/app/shell/role_shell_resolver.dart` | Picks shell based on role provider |
| `apps/mobile/lib/app/router/back_policy.dart` | Android back-button policy |
| `apps/mobile/test/app/router/auth_guard_test.dart` | Guard logic tests |
| `apps/mobile/test/app/router/deep_link_test.dart` | URL parsing tests |
| `apps/mobile/test/app/router/back_policy_test.dart` | Back navigation tests |
| `apps/mobile/integration_test/router_smoke_test.dart` | E2E nav |
| `apps/mobile/android/app/src/main/AndroidManifest.xml` | Add `<intent-filter>` for `radha://` and `https://radha.app/*` |
| `apps/mobile/ios/Runner/Info.plist` | Add CFBundleURLTypes + Universal Links |

## Route Map

```dart
// app/router/routes.dart
enum RadhaRoute {
  splash('/splash'),
  onboardingSegment('/onboarding/segment'),
  otpRequest('/auth/otp'),
  otpVerify('/auth/otp/verify'),
  premiumPaywall('/premium'),
  familyInvite('/family/invite/:token'),
  allergenSetup('/allergens/setup'),
  businessActivation('/business/activation'),
  auditorTokenEntry('/auditor/token'),

  // Consumer shell
  consumerHome('/c'),
  scanner('/c/scan'),
  scanResult('/c/scan/result/:ean'),
  productDetail('/c/products/:ean'),
  expiryCalendar('/c/calendar'),
  recallInbox('/c/recalls'),
  recallDetail('/c/recalls/:id'),
  shoppingList('/c/list'),
  profile('/c/profile'),

  // Business shell
  businessHome('/b'),
  ohsDetail('/b/ohs'),
  bulkScan('/b/audit/scan'),
  expiryBusiness('/b/expiry'),
  grnList('/b/grn'),
  grnNew('/b/grn/new'),
  inventory('/b/inventory'),
  tasksInbox('/b/tasks'),
  taskDetail('/b/tasks/:id'),
  reports('/b/reports'),
  reportDetail('/b/reports/:id'),

  // Cross
  settings('/settings'),
  about('/about');

  final String path;
  const RadhaRoute(this.path);
}

extension RadhaRouteX on RadhaRoute {
  String build({Map<String, String>? params, Map<String, String>? query}) { ... }
}
```

## Redirect Engine

A single redirect function gates every navigation. Order of checks matters.

```dart
// app/router/app_router.dart
String? _globalRedirect(BuildContext context, GoRouterState state) {
  final auth = ref.read(authStateProvider);
  final onboarding = ref.read(onboardingStateProvider);
  final role = ref.read(roleProvider);

  final loc = state.matchedLocation;

  // 1. Public routes never redirect
  if (_publicRoutes.contains(loc)) return null;

  // 2. First launch
  if (onboarding == OnboardingState.firstLaunch) return RadhaRoute.splash.path;

  // 3. Authenticated check
  if (auth is Unauthenticated) return RadhaRoute.otpRequest.path;

  // 4. Onboarding incomplete
  if (auth is Authenticated && !auth.bypassedOnboarding && !onboarding.segmentSelected) {
    return RadhaRoute.onboardingSegment.path;
  }

  // 5. Role mismatch (consumer URL but role=Business)
  if (loc.startsWith('/c') && role.isBusinessOnly) return RadhaRoute.businessHome.path;
  if (loc.startsWith('/b') && !role.canBusiness) return RadhaRoute.consumerHome.path;

  return null;
}
```

The redirect runs on every navigation attempt and during route refresh (`refreshListenable: GoRouterRefreshStream(authStream)`).

## Deep Link Handling

| URL Pattern | Behavior |
|---|---|
| `radha://scan/8901234567890` | Opens scanner with EAN pre-loaded → fetches product → routes to scan-result |
| `radha://recall/{recallId}` | Opens recall-detail; if not authenticated, defers via redirect |
| `radha://family/invite/{token}` | Opens family-invite-accept screen; calls BE-36 `/api/v1/family/accept` |
| `radha://business/activate?preset=pharmacy` | Opens business activation wizard with preset |
| `https://radha.app/p/{slug}` | Universal link → product detail (BE-51 SEO page mirror) |
| `https://radha.app/verify/{slug}` | Universal link → verified-badge detail (BE-52) |

Implementation:

```dart
class DeepLinkHandler {
  final GoRouter router;
  StreamSubscription? _sub;

  Future<void> init() async {
    final initial = await getInitialLink();
    if (initial != null) _handle(initial);
    _sub = linkStream.listen(_handle);
  }

  void _handle(String uri) {
    final parsed = Uri.parse(uri);
    if (parsed.scheme == 'radha') {
      switch (parsed.host) {
        case 'scan':
          final ean = parsed.pathSegments.first;
          router.go(RadhaRoute.scanResult.build(params: {'ean': ean}));
          return;
        case 'family':
          if (parsed.pathSegments[0] == 'invite') {
            final token = parsed.pathSegments[1];
            router.push(RadhaRoute.familyInvite.build(params: {'token': token}));
            return;
          }
        // ...
      }
    }
  }
}
```

## Role-based Shell Swap

```dart
class RoleShellResolver extends ConsumerWidget {
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(activeRoleProvider);
    return AnimatedSwitcher(
      duration: RadhaMotion.normal,
      child: role.isBusiness
          ? BusinessShell(key: const ValueKey('b'), child: child)
          : ConsumerShell(key: const ValueKey('c'), child: child),
    );
  }
}
```

Switching role triggers a 200 ms cross-fade. Bottom nav reshapes; tab keys preserve the active tab when possible.

## Android Back Policy

| Scenario | Behavior |
|---|---|
| Top-level tab (Scan, Calendar, etc.) | Back exits app — confirm dialog if scanner has unsynced scans |
| Sub-route inside a tab | Back pops to parent route |
| Modal bottom sheet open | Back closes sheet only |
| Predictive-back gesture (Android 14+) | Live preview of underlying route via `PredictiveBackPageTransitionsBuilder` |
| Hardware back during OTP flow | Confirm dialog "Cancel sign-in?" |
| Hardware back during scan-in-progress | Pause scan, do not pop |

## Visual Behaviour

| State | Visual |
|---|---|
| **First boot** | Splash → segment cards (per FE-09/10). Routing visible only by URL change in dev overlay. |
| **Tab switch (Consumer)** | 120 ms cross-fade between tab content; bottom-nav active indicator slides 200 ms `motion.normal`. |
| **Push detail route** | 320 ms slide-in-from-right (`motion.slow`) on iOS, M3 fade-through on Android. |
| **Pop detail route** | 240 ms reverse + light haptic on swipe-back (iOS edge swipe). |
| **Predictive back** | Live preview underneath; release finishes pop with 240 ms; cancel snaps back 160 ms. |
| **Deep link cold-start** | App launches → splash held until auth state resolved (≤ 800 ms) → redirect to deep target → optional auth detour. |
| **Deep link warm** | Snackbar slides up "Opening recall…" while route resolves. |
| **Role-swap (consumer→business)** | 200 ms cross-fade; bottom nav reshapes from 4 tabs to 5 with stagger 40 ms. |
| **Unknown route (`/foo/bar`)** | 404 screen with Lottie + button "Take me home." Logs Sentry breadcrumb. |
| **Auth-required + unauthenticated** | Redirect to OTP request; toast "Please sign in to continue" appears on landing. |

## Animations
- **Default route transitions**: built into `transition_builders.dart`.
  - iOS-style slide-in for detail routes: 320 ms `motion.slow`, `expressiveOut` curve.
  - M3 fade-through on Android: 200 ms `motion.normal`, opacity + 8 dp Y translation.
- **Tab swap**: cross-fade 120 ms `motion.fast`.
- **Bottom-nav indicator**: `AnimatedAlign` 200 ms `motion.normal`, `expressiveOut`.
- **Modal sheet open**: 320 ms `motion.slow` slide-up + scrim fade 200 ms.
- **Predictive back**: native preview animation; we don't animate, the system does.
- **Role shell swap**: 200 ms cross-fade with bottom-nav stagger.

Total motion budget for any transition: ≤ 320 ms.

## Accessibility
- Every route announces its title via `Semantics(label: route.title)` + `SystemChannels.platform.invokeMethod('routeUpdated', ...)`.
- Screen readers announce route changes ("Scanner opened", "Product detail opened").
- Focus moves to the first interactive element of the new route on push.
- Reduced motion: route transitions collapse to instant cuts.
- Hit targets in bottom nav ≥ 56 dp.
- Tab order in bottom nav matches visual order LTR; flips RTL.
- Custom-scheme deep links surface in screen reader with the destination route name.

## Testing
- **Unit (guards)**: 12 cases — unauthenticated → otp; first-launch → splash; consumer URL with business-only role → business home; etc.
- **Unit (deep link)**: 8 URL patterns parse correctly; malformed URLs surface a 404.
- **Widget (transitions)**: pushing a detail route from consumer home: top route is the detail at frame ≥ 320 ms.
- **Widget (back)**: Android back press in scanner with unsynced scans triggers confirm dialog.
- **Integration**: cold-start with `radha://recall/abc` → app boots, OTP detour completes, lands on recall detail; routes log to analytics in correct order.
- **Integration**: switch role mid-session — bottom nav reshapes, current detail route preserved if compatible.
- **Golden**: 4 baselines — consumer shell, business shell, 404 screen, splash → segment.
- **Predictive-back** integration on Android 14 emulator: gesture preview shows underlying route, release pops, cancel snaps back.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Redirect loop (guard A → B → A) | High | Visualize redirect graph in tests; assert each redirect reduces a "progress" counter; `GoRouter.redirectLimit: 5` as guard. |
| Deep link race vs auth resolution | Medium | Hold splash until auth resolved or 800 ms timeout; queue deep-link target. |
| Predictive back broken on third-party widgets | Medium | Test specifically on Android 14, document widgets that do/don't support it. |
| Universal links require Apple App Site Association + Android Asset Links | Medium | Wire skeleton in this phase (placeholder JSON), validate in FE-40 release prep. |
| Role-swap mid-flight crashes route | Low | `RoleShellResolver` pops to root before swap if current route incompatible with new role. |
| `GoRouter` API changes (10 → 14 → ?) | Inherent | Pin major; document an upgrade SOP. |
| Back-stack survives kill+restore | Medium | `GoRouter.restorationScopeId` set; integration test verifies. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Unauthenticated user navigating to `/c/scan` is redirected to `/auth/otp`. |
| T2 | Authenticated user without segment selection navigating to `/c` is redirected to `/onboarding/segment`. |
| T3 | Authenticated business-only user navigating to `/c/calendar` is redirected to `/b`. |
| T4 | Deep link `radha://scan/8901234567890` opens scanner-result with EAN param after auth resolved. |
| T5 | Deep link `radha://family/invite/abc123` opens family-invite-accept with the token. |
| T6 | Universal link `https://radha.app/p/maggi-noodles-9293` resolves to product-detail. |
| T7 | Cold start with deep link delivers to deep target in ≤ 2.5 s on Pixel 4a. |
| T8 | Tab swap (Consumer Scan → Calendar) completes in ≤ 120 ms with no jank. |
| T9 | Hardware back from scanner with unsaved scans shows confirm dialog "Cancel scan?" |
| T10 | Predictive back on Android 14 emulator: live preview is visible at 50% gesture progress. |
| T11 | Unknown route `/foo` lands on 404 screen and logs a Sentry breadcrumb. |
| T12 | `RadhaRoute.recallDetail.build(params: {'id': 'abc'})` returns `/c/recalls/abc`. |
| T13 | Role change from Consumer to Business cross-fades shell within 200 ms; current detail route survives if compatible. |
| T14 | App killed mid-flow; reopened restores `/c/products/8901234567890` via `restorationScopeId`. |
| T15 | Redirect chain depth never exceeds 3 steps in any user flow. |

### Q&A Questions (8)

1. Why a single global redirect over per-screen guards? What does this gain, what does it cost?
2. How does `GoRouterRefreshStream` interact with auth state changes — what triggers a re-evaluation?
3. What's the right way to handle a deep link that arrives before the auth provider has resolved?
4. How do we test predictive-back without a real Android 14 device?
5. Why does role-swap use `AnimatedSwitcher` instead of a hard route reset?
6. What's the policy when a universal link points to a recalled product (BE-51 returns 410)?
7. How does the route observer feed PostHog events without leaking PII (path params can be PII)?
8. What's the rollback plan if `GoRouter` 14 introduces a regression we hit late?

## Sign-off Gate
- [ ] Developer: 15 tests pass.
- [ ] Developer: deep link smoke-tested on real Android + iOS device.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Developer: `docs/route_map.md` shows the full graph with guards.
- [ ] Reviewer: Audited redirect engine for loops.
- [ ] Reviewer: Confirmed AppLinks + Universal Links wired (placeholder OK at this phase).
- [ ] Reviewer: Predictive-back tested on Android 14.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-06**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-05 — DO NOT PROCEED WITHOUT APPROVAL**
