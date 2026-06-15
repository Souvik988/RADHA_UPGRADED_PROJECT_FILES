// Widget tests for the onboarding flow (Task 6).
//
// What we cover here:
//
//   * Page 1 renders the brand wordmark and a "Continue" CTA.
//   * Tapping Continue advances Page 1 → Page 2 → Page 3 (the segment grid).
//   * Page 3 renders all six segment tap-cards (the 2×3 grid).
//   * Selecting Personal enables the "Get started" CTA.
//   * Tapping Get started persists the wire-value `'personal'` to secure
//     storage and flips `onboarding_complete = true`.
//
// We isolate the widget from real plugins by:
//   * overriding `sessionStorageProvider` with a mocktail fake, and
//   * overriding `tokenStoreProvider` with an in-memory stub so any provider
//     pulled in transitively (`authRepository`, etc.) doesn't reach a real
//     keystore.
//
// We mount `OnboardingScreen` inside a `MaterialApp` rather than
// `MaterialApp.router` so we don't have to drive the full router state
// machine just to verify the screen's local logic. The router-side
// integration is already covered by `test/core/router/app_router_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/design/theme.dart';
import 'package:radha_mobile/features/onboarding/onboarding_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

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

void main() {
  setUpAll(() {
    // mocktail needs a fallback for `String?` so `any()` matchers work on
    // `setPendingOnboardingSegment(String?)`.
    registerFallbackValue('');
  });

  Widget pumpHarness({required SessionStorage storage}) {
    // We mount the onboarding screen inside a tiny `MaterialApp.router` so
    // that the `context.go(AppRoute.authOtp)` call in `_finish()` resolves
    // against a real `GoRouter`. The OTP target is a placeholder `Sign in`
    // page — we never assert on it; it just needs to exist.
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: <RouteBase>[
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/auth/otp',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('OTP placeholder'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWith((ref) => _StubTokenStore()),
        sessionStorageProvider.overrideWith((ref) => storage),
      ],
      child: MaterialApp.router(
        theme: radhaLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  /// Default test viewport (800×600) is wider than tall, which squashes the
  /// segment grid into a tall scroller and pushes cards below the fold so
  /// `tester.tap(...)` lands on the offstage rect. Set a phone-shaped
  /// viewport (logical 400×900) so the whole grid fits without scrolling
  /// and reset it after each test.
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Default mock wiring — the onboarding screen reads the flag during
  /// `markComplete()` (via the controller's `build()`) so we have to stub
  /// every method it touches.
  void primeStorageHappyPath(_MockSessionStorage storage) {
    when(() => storage.readOnboardingComplete()).thenAnswer((_) async => false);
    when(() => storage.setOnboardingComplete(any())).thenAnswer((_) async {});
    when(
      () => storage.setPendingOnboardingSegment(any<String?>()),
    ).thenAnswer((_) async {});
  }

  group('OnboardingScreen', () {
    testWidgets('Page 1 renders the headline and a Continue CTA', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      // Brand wordmark on page 1.
      expect(find.text('RADHA'), findsOneWidget);
      // The supporting subline.
      expect(
        find.text('Retail Assistant for Data, Health & Audits.'),
        findsOneWidget,
      );
      // The CTA shows "Continue" on the first two pages.
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    });

    testWidgets('Tapping Continue advances to page 2 and then to page 3', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      // Page 1 → Page 2.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Page 2 — capabilities headline.
      expect(
        find.text('Built for the floor,\nnot the back office.'),
        findsOneWidget,
      );

      // Page 2 → Page 3.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Page 3 — segment selector headline + "Get started" CTA.
      expect(find.text('Who are you here as?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Get started'), findsOneWidget);
    });

    testWidgets('Page 3 grid shows 6 segment cards', (tester) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      // Advance to page 3.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // All six segment titles must be visible.
      const expectedTitles = <String>[
        'Personal',
        'Parent',
        'Business owner',
        'Pharmacy',
        'Institution',
        'Auditor (invited)',
      ];
      for (final title in expectedTitles) {
        expect(find.text(title), findsOneWidget, reason: 'missing: $title');
      }
    });

    testWidgets('Selecting Personal enables the Get started CTA', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Before selection — CTA exists but is disabled.
      final beforeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Get started'),
      );
      expect(beforeButton.onPressed, isNull);

      // Tap the Personal card.
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // After selection — CTA is enabled.
      final afterButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Get started'),
      );
      expect(afterButton.onPressed, isNotNull);
    });

    testWidgets('Tapping Get started persists the pending segment '
        'and marks onboarding complete', (tester) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Pick "Business owner" — the wire value should be 'business_owner'.
      await tester.tap(find.text('Business owner'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await tester.pumpAndSettle();

      verify(
        () => storage.setPendingOnboardingSegment('business_owner'),
      ).called(1);
      verify(() => storage.setOnboardingComplete(true)).called(1);
    });

    testWidgets('Selecting Personal persists wire value `personal` exactly', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final storage = _MockSessionStorage();
      primeStorageHappyPath(storage);

      await tester.pumpWidget(pumpHarness(storage: storage));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Get started'));
      await tester.pumpAndSettle();

      // Wire-value contract: matches the backend's snake_case Zod enum.
      verify(() => storage.setPendingOnboardingSegment('personal')).called(1);
    });
  });
}
