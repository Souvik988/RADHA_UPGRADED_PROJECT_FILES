// Headless smoke-test harness.
//
// Mirrors `integration_test/test_harness.dart` byte-for-byte except for the
// binding type, so the same assertions can run under `flutter test` (widget
// mode, no device) on CI / Windows where the integration_test package is
// not available. Anything we change in the integration harness MUST flow
// here in lockstep — we keep two copies on purpose so the integration
// flavour can opt into [IntegrationTestWidgetsFlutterBinding] without
// dragging the SDK plugin into widget tests.

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/dio_provider.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/core/offline/db.dart';
import 'package:radha_mobile/core/offline/sync_service.dart';
import 'package:radha_mobile/features/splash/bootstrap_controller.dart';

class FakeSessionStorage extends Mock implements SessionStorage {}

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore({this.access, this.refresh});

  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> persistTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class FakeBootstrapController extends BootstrapController {
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

class NoopSyncBootstrap implements SyncBootstrap {
  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() async {}
}

class SmokeHarness {
  SmokeHarness._({
    required this.dio,
    required this.adapter,
    required this.tokenStore,
    required this.storage,
    required this.db,
    required this.overrides,
  });

  final Dio dio;
  final DioAdapter adapter;
  final InMemoryTokenStore tokenStore;
  final FakeSessionStorage storage;
  final RadhaDatabase db;
  final List<Override> overrides;

  Future<void> dispose() async {
    await db.close();
  }

  static SmokeHarness build({
    AuthSession? session,
    bool onboardingComplete = true,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = DioAdapter(dio: dio);

    final storage = FakeSessionStorage();
    when(() => storage.readSession()).thenAnswer((_) async => session);
    when(
      () => storage.readOnboardingComplete(),
    ).thenAnswer((_) async => onboardingComplete);
    when(
      () => storage.getOrCreateDeviceId(),
    ).thenAnswer((_) async => 'test-device-id');
    when(
      () => storage.readDeviceId(),
    ).thenAnswer((_) async => 'test-device-id');
    when(
      () => storage.readPendingOnboardingSegment(),
    ).thenAnswer((_) async => null);
    when(() => storage.setOnboardingComplete(any())).thenAnswer((_) async {});
    when(
      () => storage.setPendingOnboardingSegment(any()),
    ).thenAnswer((_) async {});
    when(() => storage.writeSession(any())).thenAnswer((_) async {});
    when(
      () => storage.updateTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.selectStore(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});

    final tokenStore = InMemoryTokenStore(
      access: session?.accessToken,
      refresh: session?.refreshToken,
    );

    final db = RadhaDatabase.forTesting(NativeDatabase.memory());

    return SmokeHarness._(
      dio: dio,
      adapter: adapter,
      tokenStore: tokenStore,
      storage: storage,
      db: db,
      overrides: <Override>[
        dioProvider.overrideWith((_) => dio),
        tokenStoreProvider.overrideWith((_) => tokenStore),
        sessionStorageProvider.overrideWith((_) => storage),
        radhaDatabaseProvider.overrideWith((_) => db),
        // The real stream-watching count keeps a periodic Drift timer alive
        // for the lifetime of the test. We don't need it for smoke flows,
        // so substitute a single-emit stream and let the banner stay
        // hidden.
        pendingWriteCountStreamProvider.overrideWith(
          (_) => Stream<int>.value(0),
        ),
        syncBootstrapProvider.overrideWith((_) => NoopSyncBootstrap()),
        bootstrapControllerProvider.overrideWith(FakeBootstrapController.new),
      ],
    );
  }
}

void registerSmokeFallbackValues() {
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
}
