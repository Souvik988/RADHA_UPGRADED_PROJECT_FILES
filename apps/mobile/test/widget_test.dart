// Smoke test for the RADHA app shell.
//
// Verifies that `RadhaApp` builds and the router renders its initial route
// without throwing. The auth controller and onboarding controller are kept
// isolated from real platform channels (secure storage, http) by overriding
// `sessionStorageProvider` and `tokenStoreProvider` with hermetic stubs.
// The bootstrap controller is also overridden so the test doesn't depend on
// `PackageInfo.fromPlatform()` and doesn't leave the splash-floor timer
// pending when the test tears down.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/features/splash/bootstrap_controller.dart';
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

/// Hermetic stand-in for [BootstrapController]. Avoids the 600 ms
/// `Future.delayed` floor so flutter_test's pending-timer assertion passes.
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

  testWidgets('RadhaApp boots without throwing', (WidgetTester tester) async {
    final storage = _MockSessionStorage();
    when(() => storage.readSession()).thenAnswer((_) async => null);
    when(() => storage.readOnboardingComplete()).thenAnswer((_) async => false);
    when(() => storage.readAccessToken()).thenAnswer((_) async => null);
    when(
      () => storage.getOrCreateDeviceId(),
    ).thenAnswer((_) async => 'test-device-id');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWith((ref) => _StubTokenStore()),
          sessionStorageProvider.overrideWith((ref) => storage),
          bootstrapControllerProvider.overrideWith(
            _FakeBootstrapController.new,
          ),
        ],
        child: const RadhaApp(),
      ),
    );

    // Pump a few times to let the auth + onboarding + bootstrap controllers
    // resolve and the router redirect off `/splash`. We deliberately avoid
    // `pumpAndSettle()` because the splash widget hosts a continuously
    // looping decorative animation that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
