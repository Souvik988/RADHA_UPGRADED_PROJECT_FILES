import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/auth/auth_controller.dart';
import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/expiry_dto.dart';
import 'package:radha_mobile/core/network/dto/inventory_dto.dart';
import 'package:radha_mobile/core/network/dto/task_dto.dart';
import 'package:radha_mobile/design/widgets/skeleton_loader.dart';
import 'package:radha_mobile/features/home/home_screen.dart';
import 'package:radha_mobile/features/home/providers/home_summary_providers.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class _MockApiClient extends Mock implements ApiClient {}

final _testSession = AuthSession(
  accessToken: 'test-token',
  refreshToken: 'test-refresh',
  userId: 'user-123',
  tenantId: 'tenant-1',
  roles: ['manager'],
  stores: [
    const StoreAccess(
      storeId: 'store-1',
      storeName: 'Main Street Store',
      role: 'manager',
    ),
  ],
  selectedStoreId: 'store-1',
);

Widget _buildHarness({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HomeScreen()),
    ),
  );
}

void main() {
  late _MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = _MockApiClient();
  });

  List<Override> defaultOverrides({
    int nearExpiry = 3,
    int openTasks = 5,
    int lowStock = 2,
  }) {
    when(
      () => mockApiClient.getExpiryRecords(
        status: 'yellow,red',
        storeId: 'store-1',
        limit: 200,
      ),
    ).thenAnswer(
      (_) async => List.generate(
        nearExpiry,
        (i) => ExpiryResponse(
          id: 'exp-$i',
          productId: 'product-$i',
          expiryDate: '2099-12-31',
          status: 'yellow',
        ),
      ),
    );
    when(() => mockApiClient.getTasks(status: 'open', limit: 1)).thenAnswer(
      (_) async => PaginatedTasks(items: const [], total: openTasks),
    );
    // lowStockCountProvider now fetches a bounded inventory page and counts
    // items at/below threshold, so stub the page with `lowStock` such items.
    when(() => mockApiClient.getInventory(limit: 200)).thenAnswer(
      (_) async => PaginatedInventory(
        items: List.generate(
          lowStock,
          (i) => InventoryItemResponse(
            id: 'inv-$i',
            productId: 'p-$i',
            quantity: 0,
            lowStockThreshold: 5,
          ),
        ),
        total: lowStock,
      ),
    );

    return [
      apiClientProvider.overrideWithValue(mockApiClient),
      authControllerProvider.overrideWith(() => _FakeAuthController()),
    ];
  }

  group('HomeScreen', () {
    testWidgets('Renders personalized greeting with store name', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(overrides: defaultOverrides()));
      await tester.pump();

      // Greeting text contains the first part of userId
      expect(find.textContaining('user'), findsOneWidget);
      // Store name chip
      expect(find.text('Main Street Store'), findsOneWidget);
    });

    testWidgets('Shows 4 quick action cards with correct labels', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(overrides: defaultOverrides()));
      await tester.pump();

      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Add Expiry'), findsOneWidget);
      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
    });

    testWidgets('Shows summary counts when providers resolve', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          overrides: defaultOverrides(
            nearExpiry: 7,
            openTasks: 12,
            lowStock: 4,
          ),
        ),
      );
      // Let futures resolve
      await tester.pump();
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Near expiry'), findsOneWidget);
      expect(find.text('Open tasks'), findsOneWidget);
      expect(find.text('Low stock'), findsOneWidget);
    });

    testWidgets('Shows skeleton loaders while loading', (tester) async {
      // Override providers with a Completer that never completes, keeping
      // the AsyncValue in loading state without pending timers.
      final overrides = [
        apiClientProvider.overrideWithValue(mockApiClient),
        authControllerProvider.overrideWith(() => _FakeAuthController()),
        nearExpiryCountProvider.overrideWith((ref) => Completer<int>().future),
        openTasksCountProvider.overrideWith((ref) => Completer<int>().future),
        lowStockCountProvider.overrideWith((ref) => Completer<int>().future),
      ];

      await tester.pumpWidget(_buildHarness(overrides: overrides));
      await tester.pump();

      // SkeletonLoader widgets should be present (3 tiles loading)
      expect(find.byType(SkeletonLoader), findsWidgets);
      // The count values should NOT be present
      expect(find.text('0'), findsNothing);
    });
  });
}

/// Fake auth controller that immediately resolves to the test session.
class _FakeAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => _testSession;
}
