// Widget tests for the splash screen visual.
//
// Scope intentionally narrow — route assertions live in
// `test/core/router/app_router_test.dart` which already covers the redirect
// path off `/splash`. Here we only verify that the splash widget itself:
//
//   * renders the RADHA wordmark,
//   * shows a `LinearProgressIndicator`, and
//   * pumps and settles without throwing once the bootstrap controller
//     resolves.
//
// We isolate the widget from real plugin code by:
//   * overriding `sessionStorageProvider` with a mocktail fake, and
//   * overriding `tokenStoreProvider` with an in-memory stub so the auth
//     controller (built transitively by the bootstrap) doesn't try to
//     reach a real keystore.
//
// We also swap the bootstrap controller for a deterministic fake so the
// test doesn't depend on `PackageInfo.fromPlatform()` (which requires a
// platform channel).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/features/splash/bootstrap_controller.dart';
import 'package:radha_mobile/features/splash/splash_screen.dart';

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

/// Fake bootstrap controller that resolves to a deterministic
/// [BootstrapResult] without touching `PackageInfo.fromPlatform()` or
/// secure storage. Drives the same `AsyncNotifier<BootstrapResult>` API the
/// real controller does. Resolves in the next microtask (no `Timer`) so the
/// flutter_test framework's pending-timer assertion doesn't fire.
class _FakeBootstrapController extends BootstrapController {
  @override
  Future<BootstrapResult> build() async {
    return BootstrapResult(
      packageInfo: PackageInfo(
        appName: 'RADHA',
        packageName: 'com.radha.mobile',
        version: '1.0.0',
        buildNumber: '1',
      ),
      deviceId: 'test-device-id',
      hasSession: false,
    );
  }
}

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

  Widget pumpHarness({required SessionStorage storage}) {
    return ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWith((ref) => _StubTokenStore()),
        sessionStorageProvider.overrideWith((ref) => storage),
        bootstrapControllerProvider.overrideWith(_FakeBootstrapController.new),
      ],
      child: const MaterialApp(home: SplashScreen()),
    );
  }

  group('SplashScreen', () {
    testWidgets('renders the RADHA wordmark and a progress indicator', (
      tester,
    ) async {
      final storage = _MockSessionStorage();
      when(() => storage.readSession()).thenAnswer((_) async => null);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => false);
      when(
        () => storage.getOrCreateDeviceId(),
      ).thenAnswer((_) async => 'test-device-id');

      await tester.pumpWidget(pumpHarness(storage: storage));

      // Initial frame — the wordmark and the (indeterminate) progress
      // indicator must be visible immediately.
      expect(find.text('RADHA'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Drain the microtask queue so the fake bootstrap resolves. We don't
      // call `pumpAndSettle()` because the splash hosts a continuously
      // looping pulse animation that never settles by design.
      await tester.pump();
      await tester.pump();

      expect(find.text('RADHA'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the version footer once bootstrap resolves', (
      tester,
    ) async {
      final storage = _MockSessionStorage();
      when(() => storage.readSession()).thenAnswer((_) async => null);
      when(
        () => storage.readOnboardingComplete(),
      ).thenAnswer((_) async => false);
      when(
        () => storage.getOrCreateDeviceId(),
      ).thenAnswer((_) async => 'test-device-id');

      await tester.pumpWidget(pumpHarness(storage: storage));
      // Two pumps: one to drain the microtask, one to rebuild on the new
      // `AsyncData(BootstrapResult)`.
      await tester.pump();
      await tester.pump();

      // The fake bootstrap returned version `1.0.0`.
      expect(find.text('v1.0.0'), findsOneWidget);
    });
  });
}
