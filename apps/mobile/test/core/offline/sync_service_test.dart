// Tests for the offline-first SyncService.
//
// Strategy:
//   * Drift runs against `NativeDatabase.memory()` so each test gets a
//     fresh in-memory SQLite — no platform plugin, no temp files.
//   * `Dio` is wired to `DioAdapter` (from http_mock_adapter) so we can
//     script success / failure responses per-endpoint.
//   * Connectivity is faked via the `OfflineProbe` callback — a simple
//     `() => Future.value(bool)` we mutate per test.
//   * A frozen clock is injected so backoff math is deterministic.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:radha_mobile/core/offline/db.dart';
import 'package:radha_mobile/core/offline/sync_service.dart';

void main() {
  // Drift's memory database does not need a binding, but the test runner
  // still benefits from a deterministic widget-test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late RadhaDatabase db;
  late Dio dio;
  late DioAdapter adapter;
  late bool isOffline;
  late List<String> notifications;
  late SyncService service;
  late DateTime fakeNow;

  setUp(() {
    db = RadhaDatabase.forTesting(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    adapter = DioAdapter(dio: dio);
    isOffline = false;
    notifications = <String>[];
    fakeNow = DateTime.utc(2025, 1, 1, 12, 0, 0);
    service = SyncService(
      db: db,
      dio: dio,
      notifier: (msg, {context}) => notifications.add(msg),
      offlineProbe: () async => isOffline,
      clock: () => fakeNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('enqueue', () {
    test('returns a synced result with parsed value on 2xx', () async {
      adapter.onPost(
        '/api/v1/expiry',
        (server) => server.reply(200, {'id': 'exp-1', 'name': 'Yogurt'}),
        data: {'productId': 'p-1'},
      );

      final result = await service.enqueue<Map<String, dynamic>>(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        body: {'productId': 'p-1'},
        parser: (json) => json,
      );

      expect(result.synced, isTrue);
      expect(result.queued, isFalse);
      expect(result.value, isA<Map<String, dynamic>>());
      expect(result.value!['id'], 'exp-1');
      expect(await db.getAllPendingWrites(), isEmpty);
    });

    test('persists to pending_writes when the device is offline', () async {
      isOffline = true;

      final result = await service.enqueue<void>(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        body: {'productId': 'p-2'},
      );

      expect(result.synced, isFalse);
      expect(result.queued, isTrue);
      expect(result.queueRowId, isNotNull);

      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      expect(rows.single.endpoint, '/api/v1/expiry');
      expect(rows.single.method, 'POST');
      expect(rows.single.bodyJson, contains('p-2'));
      expect(rows.single.retryCount, 0);
    });

    test('persists to pending_writes on a network error', () async {
      adapter.onPost(
        '/api/v1/expiry',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/expiry'),
            type: DioExceptionType.connectionError,
            error: const SocketException('host unreachable'),
          ),
        ),
        data: {'productId': 'p-3'},
      );

      final result = await service.enqueue<void>(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        body: {'productId': 'p-3'},
      );

      expect(result.synced, isFalse);
      expect(result.queued, isTrue);
      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      expect(rows.single.lastError, isNotNull);
    });

    test('persists to pending_writes on a 5xx response', () async {
      adapter.onPost(
        '/api/v1/expiry',
        (server) => server.reply(503, {'message': 'temporarily down'}),
        data: {'productId': 'p-4'},
      );

      final result = await service.enqueue<void>(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        body: {'productId': 'p-4'},
      );

      expect(result.queued, isTrue);
      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      expect(rows.single.lastError, contains('503'));
    });
  });

  group('processQueue', () {
    test('removes successfully synced writes', () async {
      // Seed two pending rows.
      await db.enqueueWrite(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        bodyJson: '{"productId":"p-1"}',
        createdAt: fakeNow,
      );
      await db.enqueueWrite(
        endpoint: '/api/v1/tasks',
        method: 'POST',
        bodyJson: '{"title":"audit"}',
        createdAt: fakeNow,
      );

      adapter
        ..onPost(
          '/api/v1/expiry',
          (server) => server.reply(201, {'id': 'exp-1'}),
          data: {'productId': 'p-1'},
        )
        ..onPost(
          '/api/v1/tasks',
          (server) => server.reply(201, {'id': 'task-1'}),
          data: {'title': 'audit'},
        );

      await service.processQueue();

      expect(await db.getAllPendingWrites(), isEmpty);
    });

    test('bumps retry counter and schedules backoff on 5xx', () async {
      final id = await db.enqueueWrite(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        bodyJson: '{"productId":"p-1"}',
        createdAt: fakeNow,
      );

      adapter.onPost(
        '/api/v1/expiry',
        (server) => server.reply(503, {'error': 'down'}),
        data: {'productId': 'p-1'},
      );

      await service.processQueue();

      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      final row = rows.firstWhere((r) => r.id == id);
      expect(row.retryCount, 1);
      // First retry runs at +1s.
      expect(
        row.nextRetryAt,
        fakeNow.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
      );
      expect(row.lastError, contains('503'));
    });

    test('exponential backoff capped at 60s after 6 retries', () async {
      // Seed rows already at retry counts 1..6 to exercise each step.
      // Clock is frozen at fakeNow for deterministic math.
      final ids = <int>[];
      for (var i = 1; i <= 6; i++) {
        ids.add(
          await db
              .into(db.pendingWrites)
              .insert(
                PendingWritesCompanion.insert(
                  endpoint: '/api/v1/expiry',
                  method: 'POST',
                  bodyJson: '{"i":$i}',
                  createdAt: fakeNow.millisecondsSinceEpoch,
                  retryCount: Value(i - 1),
                  // Make every row eligible right now.
                  nextRetryAt: const Value(null),
                ),
              ),
        );
      }
      adapter.onPost('/api/v1/expiry', (server) => server.reply(503, {}));

      await service.processQueue();

      final remaining = await db.getAllPendingWrites();
      // The 6th retry exhausts the budget and is dropped.
      expect(remaining, hasLength(5));

      // Walk the remaining rows in (i, retryCount) order. retryCount = i.
      // Backoff for retry n = min(60s, 2^(n-1) s):
      //   1 -> 1s, 2 -> 2s, 3 -> 4s, 4 -> 8s, 5 -> 16s
      const expected = <int, int>{1: 1, 2: 2, 3: 4, 4: 8, 5: 16};
      for (final row in remaining) {
        final delaySec = expected[row.retryCount];
        expect(
          delaySec,
          isNotNull,
          reason: 'unexpected retryCount ${row.retryCount}',
        );
        expect(
          row.nextRetryAt,
          fakeNow.add(Duration(seconds: delaySec!)).millisecondsSinceEpoch,
        );
      }

      // The dropped row triggered a notification.
      expect(notifications, isNotEmpty);
      expect(notifications.first, contains('after 6 attempts'));
    });

    test('skips rows whose backoff window has not elapsed', () async {
      final futureWatermark = fakeNow.add(const Duration(seconds: 30));
      await db.enqueueWrite(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        bodyJson: '{}',
        createdAt: fakeNow,
        nextRetryAt: futureWatermark,
        retryCount: 1,
      );

      // No mock registered — if we hit Dio, the test fails with an error.
      await service.processQueue();

      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      expect(
        rows.single.nextRetryAt,
        futureWatermark.millisecondsSinceEpoch,
        reason: 'row should be untouched until its watermark passes',
      );
    });

    test('returns immediately when offline', () async {
      isOffline = true;
      await db.enqueueWrite(
        endpoint: '/api/v1/expiry',
        method: 'POST',
        bodyJson: '{}',
        createdAt: fakeNow,
      );

      await service.processQueue();

      // The row is left alone — nothing to record because we never tried.
      final rows = await db.getAllPendingWrites();
      expect(rows, hasLength(1));
      expect(rows.single.retryCount, 0);
    });
  });

  group('evictExpiredProductCache', () {
    test('drops rows older than the TTL', () async {
      final old = fakeNow.subtract(const Duration(hours: 25));
      final fresh = fakeNow.subtract(const Duration(hours: 1));

      await db.cacheProduct(
        ean: '111',
        payloadJson: '{"id":"a"}',
        fetchedAt: old,
      );
      await db.cacheProduct(
        ean: '222',
        payloadJson: '{"id":"b"}',
        fetchedAt: fresh,
      );

      final removed = await service.evictExpiredProductCache();

      expect(removed, 1);
      expect(await db.getCachedProduct('111'), isNull);
      expect(await db.getCachedProduct('222'), isNotNull);
    });
  });
}
