// Tests for the auth-aware redirect logic in `app_router.dart`.
//
// These tests stub out [SessionStorage] (the underlying source of truth for
// both the session and the onboarding flag) and assert that GoRouter funnels
// the user to the correct destination given the bootstrap state:
//
//   * Onboarding incomplete  ⇒ /onboarding
//   * Onboarded, no session  ⇒ /auth/otp
//   * Logged in, no store    ⇒ /select-store
//   * Logged in, store picked ⇒ /home
//
// Real Dio / secure storage / mobile_scanner plugin code is never touched.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/main.dart';

class _StubTokenStore implements TokenStore {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> persistTokens({
    required String access,
    required String refresh,
  }) async {}
  @override
  Future<void> clear() async {}
}

class _MockSessionStorage extends Mock implements SessionStorage {}

ProviderScope _wrap(SessionStorage storage) => ProviderScope(
  overrides: [
    tokenStoreProvider.overrideWith((ref) => _StubTokenStore()),
    sessionStorageProvider.overrideWith((ref) => storage),
  ],
  child: const RadhaApp(),
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AuthSession(
        accessToken: '',
        refreshToken: '',
        userId: '',
        tenantId: '',
        roles: <String>[],
        stores: <StoreAccess>[],
      ),
    );
  });

  group('app_router redirect', () {
    testWidgets('routes a fresh install to /onboarding', (tester) async {
      final storage = _MockSessionStorage();
      when(() => storage.readSession()).thenAnswer((_) async => null);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(_wrap(storage));
      await tester.pumpAndSettle();

      // The onboarding screen lands on its first page — the brand wordmark.
      expect(find.text('RADHA'), findsOneWidget);
      expect(
        find.text('Retail Assistant for Data, Health & Audits.'),
        findsOneWidget,
      );
    });

    testWidgets('routes an onboarded, signed-out user to /auth/otp', (
      tester,
    ) async {
      final storage = _MockSessionStorage();
      when(() => storage.readSession()).thenAnswer((_) async => null);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(_wrap(storage));
      await tester.pumpAndSettle();

      // The OTP request screen shows a "Sign in" headline.
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('routes a signed-in user with no store to /select-store', (
      tester,
    ) async {
      final storage = _MockSessionStorage();
      const session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'u-1',
        tenantId: 't-1',
        roles: ['staff'],
        stores: [
          StoreAccess(storeId: 's-1', storeName: 'Andheri', role: 'staff'),
          StoreAccess(storeId: 's-2', storeName: 'Bandra', role: 'staff'),
        ],
        // selectedStoreId omitted ⇒ user must pick one
      );
      when(() => storage.readSession()).thenAnswer((_) async => session);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(_wrap(storage));
      await tester.pumpAndSettle();

      expect(find.text('Select store'), findsOneWidget);
      expect(find.text('Andheri'), findsOneWidget);
    });

    testWidgets('routes a fully provisioned user to /home', (tester) async {
      final storage = _MockSessionStorage();
      const session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'u-1',
        tenantId: 't-1',
        roles: ['staff'],
        stores: [
          StoreAccess(storeId: 's-1', storeName: 'Andheri', role: 'staff'),
        ],
        selectedStoreId: 's-1',
      );
      when(() => storage.readSession()).thenAnswer((_) async => session);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(_wrap(storage));
      // Home renders the Mor companion mascot, whose gentle "breathing" idle
      // is an intentional perpetual animation — so `pumpAndSettle` would time
      // out waiting for it to stop. Pump fixed frames instead: enough to clear
      // the bootstrap (600 ms splash floor) + the redirect + the staggered
      // section entrance, then assert on a stable target.
      await tester.pump(); // first frame
      await tester.pump(const Duration(milliseconds: 700)); // splash floor
      await tester.pump(const Duration(milliseconds: 700)); // entrance stagger

      // Home renders a "Quick actions" section header — a stable target
      // that doesn't depend on the summary providers settling. (The
      // redesigned home screen no longer uses an AppBar.)
      expect(find.text('Quick actions'), findsOneWidget);
    });

    test('AppRoute constants stay in sync with the spec', () {
      // Sanity check — the spec listed exactly these 25 routes for Task 4.
      // If a maintainer removes one, this test catches the drift.
      const expected = <String>[
        AppRoute.splash,
        AppRoute.onboarding,
        AppRoute.authOtp,
        AppRoute.authOtpVerify,
        AppRoute.selectStore,
        AppRoute.home,
        AppRoute.scan,
        AppRoute.scanResult,
        AppRoute.expiry,
        AppRoute.expiryNew,
        AppRoute.tasks,
        AppRoute.taskDetail,
        AppRoute.inventory,
        AppRoute.inventoryStockMovement,
        AppRoute.grn,
        AppRoute.grnDetail,
        AppRoute.grnItems,
        AppRoute.profile,
        AppRoute.settings,
        AppRoute.subscription,
        AppRoute.shoppingList,
        AppRoute.recallAlerts,
        AppRoute.allergens,
        AppRoute.referrals,
        AppRoute.expiryCalendar,
      ];
      expect(expected.toSet().length, expected.length);
    });
  });
}
