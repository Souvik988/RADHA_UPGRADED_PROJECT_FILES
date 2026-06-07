# Phase FE-07: State Management (Riverpod) + Auth State

## Phase Metadata
- **Phase ID**: FE-07
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-05 (router), FE-06 (API client)
- **Blocks**: FE-08 (sync needs auth context), FE-09+ (every screen reads auth/role/tenant)
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal
Adopt Riverpod 2.5 (with codegen) as the only state-management solution in the app. Build the canonical providers for: auth state (signed-in, signed-out, refreshing), JWT lifecycle (refresh-before-expiry timer), the active role (Consumer / Business — a user can have both), the active tenant + store (when in business mode), feature flags (BE-47), connectivity, and a "presentation hint" provider that drives the consumer/business shell swap (FE-05).

The auth provider survives backgrounding, app kill, multi-window (Android tablet split-screen), and rapid foreground/background cycles. It exposes a single Stream the GoRouter `refreshListenable` watches. Token storage uses `flutter_secure_storage` (Keychain / Keystore). Logout is a single, irreversible state transition that purges secure storage + Drift tenant data and routes to OTP.

By the end of this phase, every later phase reads `ref.watch(authStateProvider)` to know who the user is. Nothing reaches into `SharedPreferences` or directly into Dio.

## Why This Phase Matters
- **Riverpod codegen + freezed** gives us compile-time guarantees: a new auth state can't be forgotten in a `switch` because the compiler enforces exhaustive matching.
- **Token refresh before expiry** (rather than after-401-bounce) means the user doesn't see a flicker of "session expired" mid-scan.
- **Multi-window survival** matters because business managers run the app in split-screen with their inventory tracker.
- **Role + tenant context** is the substrate of multi-tenancy security — every API call adds tenant header from this provider.
- **Single stream feeding GoRouter** is the cleanest way to keep auth-driven redirects honest.
- **Feature flags** wired at this layer means a new feature can be killed without an app store push.

## Prerequisites
- [ ] Backend: BE-06 (OTP/refresh), BE-08 (roles), BE-09 (tenants), BE-34 (segment), BE-47 (flags).
- [ ] Earlier FE: FE-01, FE-05, FE-06.
- [ ] Storage: `flutter_secure_storage 9.x` (Keychain / KeyStore-AES). iOS Keychain access group set per flavor. Android encrypted shared preferences fallback.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/state/providers.dart` | Re-exports |
| `apps/mobile/lib/state/auth/auth_state.dart` | freezed sealed `AuthState` |
| `apps/mobile/lib/state/auth/auth_controller.dart` | Riverpod `@riverpod` notifier |
| `apps/mobile/lib/state/auth/token_store.dart` | Secure storage wrapper |
| `apps/mobile/lib/state/auth/jwt_decoder.dart` | Lightweight JWT decode (no signature verify) |
| `apps/mobile/lib/state/auth/refresh_scheduler.dart` | Timer that refreshes 60 s before exp |
| `apps/mobile/lib/state/role/active_role_provider.dart` | Consumer vs Business — user-toggle |
| `apps/mobile/lib/state/role/role_capabilities.dart` | Helper getters (`canBusiness`, `isPremium`, …) |
| `apps/mobile/lib/state/tenant/active_tenant_provider.dart` | Selected tenant when in business mode |
| `apps/mobile/lib/state/tenant/active_store_provider.dart` | Selected store within tenant |
| `apps/mobile/lib/state/onboarding/onboarding_state.dart` | First-launch + segment-selected state |
| `apps/mobile/lib/state/connectivity/connectivity_provider.dart` | Online/offline stream |
| `apps/mobile/lib/state/feature_flags/feature_flags_provider.dart` | BE-47 backed |
| `apps/mobile/lib/state/lifecycle/app_lifecycle_provider.dart` | Background/foreground notifier |
| `apps/mobile/lib/state/auth/auth_token_header_interceptor.dart` | Reads tenant id, attaches `X-Tenant-Id`, `X-Store-Id` |
| `apps/mobile/test/state/auth/auth_controller_test.dart` | Unit tests |
| `apps/mobile/test/state/auth/refresh_scheduler_test.dart` | Timer tests with `FakeAsync` |
| `apps/mobile/integration_test/auth_flow_test.dart` | E2E |

## AuthState Shape

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;          // before token check
  const factory AuthState.unauthenticated() = _Unauth;
  const factory AuthState.authenticating() = _AuthIng;   // OTP request in flight
  const factory AuthState.authenticated({
    required String userId,
    required String accessToken,
    required String refreshToken,
    required DateTime accessExpiresAt,
    required Set<RadhaRole> roles,             // Consumer, Business, Auditor
    required List<TenantSummary> tenants,      // empty if pure consumer
    required OnboardingSegment? segment,        // BE-34
    required bool bypassedOnboarding,           // BE-06 v2
    required PremiumTier premiumTier,           // none, premium_consumer, derived (family)
    required String? primaryFamilyOwnerId,      // if member
    required Locale preferredLocale,
  }) = Authenticated;
  const factory AuthState.refreshing(Authenticated previous) = _Refreshing;
  const factory AuthState.sessionExpired() = _SessionExpired;
  const factory AuthState.error(RadhaError error) = _AuthError;
}
```

UI never exposes refresh tokens. Only the controller reads them.

## AuthController

```dart
@riverpod
class AuthController extends _$AuthController {
  late final TokenStore _tokens;
  late final AuthService _api;
  late final RefreshScheduler _scheduler;

  @override
  Future<AuthState> build() async {
    _tokens   = ref.read(tokenStoreProvider);
    _api      = ref.read(authServiceProvider);
    _scheduler = RefreshScheduler(onRefresh: _refreshNow);

    final tokens = await _tokens.read();
    if (tokens == null) return const AuthState.unauthenticated();
    if (JwtDecoder.isExpired(tokens.access)) {
      return _refreshNow(initialRefresh: tokens.refresh);
    }
    final s = _hydrateAuthenticated(tokens);
    _scheduler.scheduleNextRefresh(s.accessExpiresAt);
    return s;
  }

  Future<void> requestOtp(String mobile) async {
    state = const AsyncData(AuthState.authenticating());
    final r = await _api.requestOtp(mobile);
    r.whenErr((e) => state = AsyncData(AuthState.error(e)));
  }

  Future<void> verifyOtp(String mobile, String code) async {
    final r = await _api.verifyOtp(mobile, code);
    r.when(
      ok: (creds) async {
        await _tokens.write(creds.access, creds.refresh);
        final s = _hydrateAuthenticated(creds);
        _scheduler.scheduleNextRefresh(s.accessExpiresAt);
        state = AsyncData(s);
      },
      err: (e) => state = AsyncData(AuthState.error(e)),
    );
  }

  Future<void> logout() async {
    await _scheduler.cancel();
    await _tokens.clear();
    await ref.read(driftDbProvider).wipeUserData();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<AuthState> _refreshNow({String? initialRefresh}) async {
    state = AsyncData(AuthState.refreshing(state.value as Authenticated));
    final res = await _api.refresh(initialRefresh ?? (await _tokens.read())!.refresh);
    return res.when(
      ok: (creds) async {
        await _tokens.write(creds.access, creds.refresh);
        final s = _hydrateAuthenticated(creds);
        _scheduler.scheduleNextRefresh(s.accessExpiresAt);
        state = AsyncData(s);
        return s;
      },
      err: (e) async {
        await _tokens.clear();
        const s = AuthState.sessionExpired();
        state = const AsyncData(s);
        return s;
      },
    );
  }
}
```

## Refresh Scheduler

```dart
class RefreshScheduler {
  final Future<AuthState> Function() onRefresh;
  Timer? _t;
  void scheduleNextRefresh(DateTime exp) {
    cancel();
    final lead = const Duration(seconds: 60);
    final delay = exp.difference(DateTime.now()) - lead;
    if (delay.isNegative) { onRefresh(); return; }
    _t = Timer(delay, onRefresh);
  }
  void cancel() => _t?.cancel();
}
```

When the app backgrounds, the timer is cancelled. On resume, the lifecycle provider checks token expiry and refreshes if needed.

## Active Role + Tenant

```dart
enum ActiveMode { consumer, business }

@riverpod
class ActiveModeController extends _$ActiveModeController {
  @override
  ActiveMode build() {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    if (auth is! Authenticated) return ActiveMode.consumer;
    if (!auth.roles.contains(RadhaRole.business)) return ActiveMode.consumer;
    // default to last-used or consumer
    return ref.watch(lastUsedModeProvider) ?? ActiveMode.consumer;
  }
  void setMode(ActiveMode m) {
    if (m == state) return;
    state = m;
    ref.read(lastUsedModeProvider.notifier).set(m);
  }
}
```

Switching modes triggers the FE-05 shell cross-fade.

```dart
@riverpod
class ActiveTenant extends _$ActiveTenant {
  @override
  TenantSummary? build() {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    if (auth is! Authenticated || auth.tenants.isEmpty) return null;
    return auth.tenants.firstWhere((t) => t.isPersonal == false, orElse: () => auth.tenants.first);
  }
  void switchTo(String tenantId) {
    final auth = ref.read(authControllerProvider).valueOrNull;
    if (auth is! Authenticated) return;
    state = auth.tenants.firstWhere((t) => t.id == tenantId);
  }
}
```

The Dio header interceptor reads `activeTenantProvider` → adds `X-Tenant-Id` to every request. Switching tenant flushes any tenant-scoped query caches (Riverpod `invalidate`).

## Connectivity + Lifecycle

```dart
@riverpod
Stream<bool> connectivity(ConnectivityRef ref) async* {
  yield await Connectivity().checkConnectivity().then((r) => r != ConnectivityResult.none);
  yield* Connectivity().onConnectivityChanged.map((r) => r != ConnectivityResult.none);
}

@riverpod
class AppLifecycle extends _$AppLifecycle {
  @override
  AppLifecycleState build() {
    final binding = WidgetsBinding.instance;
    final observer = _Observer((s) => state = s);
    binding.addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));
    return AppLifecycleState.resumed;
  }
}
```

When `AppLifecycle` flips to `resumed`, AuthController checks token freshness.

## Feature Flags

```dart
@riverpod
class FeatureFlags extends _$FeatureFlags {
  @override
  Future<Map<String, dynamic>> build() async {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user is! Authenticated) return {};
    final r = await ref.read(featureFlagsServiceProvider).fetchAll();
    Timer(const Duration(minutes: 5), () => ref.invalidateSelf());
    return r.fold(ok: (m) => m, err: (_) => state.valueOrNull ?? {});
  }
  bool isOn(String key) => state.valueOrNull?[key] == true;
}
```

5-minute polling matches BE-47 spec.

## Multi-Window Survival

`flutter_secure_storage` is process-safe. The challenge is provider state in two `Activity` instances on Android tablet split-screen. Solution: every screen reads `ref.watch(authControllerProvider)` and never caches the auth value across rebuilds. We don't use static singletons.

## Visual Behaviour

Dev-only diagnostic screen `auth_diagnostics.dart`:

| State | Visual |
|---|---|
| **Initial** | "Loading session…" with Lottie spinner. |
| **Unauthenticated** | "No session. Tap to request OTP." |
| **Authenticating** | Lottie dots spinner inline; button disabled. |
| **Authenticated** | JSON-pretty card showing userId, roles, tenants, segment, premium tier. Mask tokens. |
| **Refreshing** | Banner "Refreshing session…" 1.4 s shimmer. |
| **Session expired** | Modal "Your session has ended. Sign in again." → tap OK → routes to OTP. |
| **Error** | Snackbar with `radhaError.userMessage` + retry button. |
| **Mode toggle** | Switch top-right: Consumer / Business; flipping triggers shell cross-fade in real app. |
| **Active tenant chip** | Tap to open tenant picker bottom sheet (sm 90% snap). |
| **Logout button** | Long-press required (haptic medium); confirm dialog "Sign out and clear data?" |

## Animations
- **Auth state transitions**: `AnimatedSwitcher` 200 ms `motion.normal` cross-fade between AuthState renders.
- **Refresh banner**: 200 ms slide-down on appearance, 200 ms slide-up on disappear.
- **Mode toggle**: handled by FE-05 shell (cross-fade 200 ms).
- **Logout confirm**: standard dialog open/close.
- **Token expiry-flash** (dev only): on the diagnostics screen, the access-expiry countdown ticks; when ≤ 60 s a soft pulse animation on the card draws the eye to the impending refresh.

## Accessibility
- Auth error messages localized via `RadhaError.userMessage(BuildContext)`.
- Logout long-press has a 600 ms hold; surfaced via Semantics hint "Long press to sign out and erase data."
- Mode toggle announced as a switch with on/off labels.
- Tenant chip announces "Active tenant, Mumbai store. Double tap to change."

## Testing
- **Unit**: AuthController.build with no tokens → `unauthenticated`.
- **Unit**: AuthController.build with expired access + valid refresh → triggers refresh, ends `authenticated`.
- **Unit**: refresh failure clears tokens, ends `sessionExpired`.
- **Unit**: 5 concurrent provider readers see one refresh call (mutex).
- **Unit**: RefreshScheduler with `FakeAsync`: schedules at exp - 60s, fires once at expected time.
- **Unit**: ActiveModeController defaults to consumer if user has no business role.
- **Unit**: Switching tenant invalidates tenant-scoped providers (test against a marker provider).
- **Unit**: FeatureFlags.isOn returns false when state has no data.
- **Unit**: Lifecycle resume triggers `_refreshIfNeeded()` when access ttl < 60 s.
- **Integration**: full flow — request OTP → verify OTP → token written → refresh fires automatically → background app 5 min → resume → still authenticated.
- **Integration**: kill app, reopen → auth state restored from secure storage in ≤ 800 ms.
- **Integration**: split-screen on Android tablet — both panes read the same auth state.
- **Golden**: 4 baselines for the auth diagnostics screen (initial, authenticated, refreshing, expired).

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Refresh storm after long sleep | Medium | Single in-flight future (mutex). Plus exponential backoff if refresh repeatedly fails. |
| Secure storage misuse on iOS (Keychain access group) | Medium | Per-flavor Keychain access group; document in README; integration test reads/writes after kill. |
| Token written in plain SharedPreferences by accident | Critical | Lint rule forbids reading tokens outside `TokenStore`; CI grep guard. |
| Riverpod codegen drift | Medium | `build_runner` runs in CI; PRs with stale `.g.dart` fail. |
| Multi-window producing two notifiers | Low | Riverpod `ProviderScope` is per-`MaterialApp` instance; one-app-one-scope guaranteed. |
| Logout race vs in-flight request | Medium | Logout cancels Dio cancel-token, awaits cancellations before clearing. |
| Refresh scheduler leaks Timer on hot reload | Low | `ref.onDispose` cancels timer. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Fresh install: AuthController.build returns `unauthenticated` in ≤ 200 ms. |
| T2 | After `verifyOtp` succeeds, `authStateProvider` becomes `authenticated` with userId set. |
| T3 | `tokenStore.read()` returns the same access/refresh that were written. |
| T4 | Killing the app and reopening restores `authenticated` state from secure storage. |
| T5 | RefreshScheduler with FakeAsync: scheduled at `exp - 60s`; fires exactly once. |
| T6 | Manual `_refreshNow()` with a refresh-token-rejected response transitions to `sessionExpired`. |
| T7 | Logout clears secure storage AND wipes Drift user-scoped tables (verified by row count = 0). |
| T8 | ActiveModeController flips when user toggles mode; persisted to local prefs. |
| T9 | ActiveTenantProvider defaults to first non-personal tenant if any. |
| T10 | Tenant switch invalidates `productsServiceProvider` cache (using a marker provider). |
| T11 | Connectivity provider emits `false` then `true` when network drops then returns. |
| T12 | App backgrounded for 5 min, resumed: auth state remains `authenticated`; refresh ran. |
| T13 | FeatureFlags polls every 5 minutes; provider rebuilds on each poll without UI flicker. |
| T14 | Logout cancels in-flight Dio requests within 200 ms (verified by Dio cancel token). |
| T15 | Lint: any read of `flutter_secure_storage` outside `TokenStore` fails CI. |

### Q&A Questions (8)

1. Why proactive refresh (60 s before expiry) over reactive (refresh on 401)? What's the failure mode of each?
2. How does the controller handle clock skew between client and server? What if the user's clock is wrong by 10 minutes?
3. Why is Drift wiped on logout? What happens to offline-queued writes that were never synced?
4. How does role-toggle survive across app restart vs token-rotation?
5. What's the rule when a Premium user's family member is a separate user — whose state owns the entitlement?
6. How do feature flags reconcile with offline mode? What's served when no flags fetched yet?
7. What's the upgrade story when an `AuthState` variant is added later (e.g. `requires2fa`)?
8. How do we keep `activeTenantProvider` in sync with the `X-Tenant-Id` header read by Dio? Where does the bridge live?

## Sign-off Gate
- [ ] Developer: 15 tests pass.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Developer: Riverpod codegen up-to-date in CI (no diff).
- [ ] Reviewer: Audited that no other code reads tokens directly.
- [ ] Reviewer: Verified secure storage Keychain access group per flavor.
- [ ] Reviewer: Confirmed logout wipes Drift; signed off on data-purge SQL.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-08**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-07 — DO NOT PROCEED WITHOUT APPROVAL**
