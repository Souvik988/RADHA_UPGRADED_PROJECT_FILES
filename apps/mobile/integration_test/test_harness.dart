// Shared integration-test harness.
//
// Builds a fully-mocked `RadhaApp` so each smoke test can assert the happy
// path of a single feature without spinning up a real backend, real secure
// storage, real `package_info_plus`, real `connectivity_plus`, or a real
// camera. The harness wires:
//
//   * `dioProvider`               → a [Dio] paired with a [DioAdapter] from
//                                    `http_mock_adapter` so each test scripts
//                                    its own backend responses.
//   * `tokenStoreProvider`        → an in-memory [TokenStore] that mirrors
//                                    whatever the auth interceptor persists.
//   * `sessionStorageProvider`    → a `mocktail` fake of [SessionStorage]
//                                    seeded with the requested initial
//                                    session and onboarding flag.
//   * `radhaDatabaseProvider`     → an in-memory Drift database so the
//                                    [SyncStatusBanner] and offline queue
//                                    work without a sqlite file.
//   * `syncBootstrapProvider`     → a no-op fake so the test never tries to
//                                    subscribe to `connectivity_plus`.
//   * `bootstrapControllerProvider` → a deterministic fake that resolves
//                                    immediately so the splash redirect
//                                    fires straight after the first frame.
//
// Each test case is responsible for:
//   1. calling `IntegrationTestHarness.build(...)` once,
//   2. registering its own `adapter.onPost / onGet / ...` stubs,
//   3. pumping `RadhaApp` with `harness.overrides`, and
//   4. tearing the harness down via `await harness.dispose()` in
//      `addTearDown`.
//
// We deliberately keep this file thin — the goal is "minimum scaffolding so
// the smoke tests read like a script". Reach for `mocktail.when(() => ...)`
// directly inside an individual test if you need a one-off stub.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/connectivity/connectivity_provider.dart';
import 'package:radha_mobile/core/network/dio_provider.dart';
import 'package:radha_mobile/core/network/token_provider.dart';
import 'package:radha_mobile/core/offline/db.dart';
import 'package:radha_mobile/core/offline/sync_service.dart';
import 'package:radha_mobile/features/splash/bootstrap_controller.dart';

/// Mocktail mock for [SessionStorage].
class FakeSessionStorage extends Mock implements SessionStorage {}

/// In-memory implementation of [TokenStore] used by the auth interceptor in
/// tests. Mirrors whatever the auth flow persists so a subsequent request
/// sees the freshly-written `Authorization` header.
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

/// Deterministic fake bootstrap controller. Resolves to a synthetic
/// [BootstrapResult] immediately so the splash redirect fires on the first
/// frame and the test doesn't depend on `PackageInfo.fromPlatform()`.
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

/// No-op replacement for [SyncBootstrap] used in tests. The real bootstrap
/// subscribes to `connectivity_plus`, which has no platform binding under
/// `flutter test` and would otherwise throw on the very first frame.
class NoopSyncBootstrap implements SyncBootstrap {
  @override
  Future<void> start() async {}

  @override
  Future<void> dispose() async {}
}

/// Container for the per-test mock state. Pass `harness.overrides` straight
/// into a [ProviderScope] and call `addTearDown(harness.dispose)`.
class IntegrationTestHarness {
  IntegrationTestHarness._({
    required this.dio,
    required this.adapter,
    required this.tokenStore,
    required this.storage,
    required this.db,
    required this.overrides,
  });

  /// The [Dio] instance the app talks through. Already wired to [adapter].
  final Dio dio;

  /// `http_mock_adapter` controller for stubbing backend responses.
  final DioAdapter adapter;

  /// In-memory token store backing the auth interceptor.
  final InMemoryTokenStore tokenStore;

  /// Mocktail mock for the session storage layer.
  final FakeSessionStorage storage;

  /// In-memory Drift database used by the sync queue.
  final RadhaDatabase db;

  /// The list of provider overrides to plug into the test [ProviderScope].
  final List<Override> overrides;

  /// Closes the in-memory database. Safe to call multiple times.
  Future<void> dispose() async {
    await db.close();
  }

  /// Builds the harness. Pass [session] to start the app pre-logged-in;
  /// pass `null` (the default) for a signed-out user.
  static IntegrationTestHarness build({
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

    return IntegrationTestHarness._(
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
        syncBootstrapProvider.overrideWith((_) => NoopSyncBootstrap()),
        bootstrapControllerProvider.overrideWith(FakeBootstrapController.new),
        // Always-online connectivity stream so the [ConnectivityBanner]
        // never renders the "Offline" strip during a smoke test, and the
        // sync service's offline-first probe sees us as reachable.
        connectivityProvider.overrideWith(
          (_) => Stream<List<ConnectivityResult>>.value(
            const <ConnectivityResult>[ConnectivityResult.wifi],
          ),
        ),
      ],
    );
  }
}

/// Registers the fallback values mocktail needs when verifying calls with
/// `any()` matchers against custom types. Call from `setUpAll` in each
/// test file.
void registerHarnessFallbackValues() {
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
