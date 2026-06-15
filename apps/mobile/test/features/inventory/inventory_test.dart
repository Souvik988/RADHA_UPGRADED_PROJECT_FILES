import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/inventory_dto.dart';
import 'package:radha_mobile/features/inventory/inventory_list_screen.dart';
import 'package:radha_mobile/features/inventory/low_stock_alerts_screen.dart';
import 'package:radha_mobile/features/inventory/stock_movement_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeStockAdjustmentDto extends Fake implements StockAdjustmentDto {}

/// Builds a `MaterialApp` host with the supplied [child] and Riverpod
/// overrides. Routes from the real router are intentionally not wired —
/// each test exercises a single screen in isolation.
Widget _buildApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(FakeStockAdjustmentDto());
  });

  setUp(() {
    mockApi = MockApiClient();
  });

  group('InventoryListScreen', () {
    testWidgets('renders product items returned by the backend', (
      tester,
    ) async {
      when(
        () => mockApi.getInventory(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedInventory(
          items: [
            InventoryItemResponse(
              id: 'inv-1',
              productId: 'product-abc',
              quantity: 50,
              lowStockThreshold: 10,
            ),
            InventoryItemResponse(
              id: 'inv-2',
              productId: 'product-xyz',
              quantity: 3,
              lowStockThreshold: 5,
            ),
          ],
          total: 2,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const InventoryListScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('product-abc'), findsWidgets);
      expect(find.textContaining('product-xyz'), findsWidgets);
      // The second item is below threshold (3 < 5) → low-stock badge shows.
      expect(find.text('Low Stock'), findsOneWidget);
    });
  });

  group('StockMovementScreen', () {
    testWidgets('stock out rejects negative resulting quantity client-side', (
      tester,
    ) async {
      // The product currently has 5 on hand; we'll try to remove 10.
      when(
        () => mockApi.getInventory(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedInventory(
          items: [
            InventoryItemResponse(
              id: 'inv-1',
              productId: 'prod-1',
              quantity: 5,
              lowStockThreshold: 2,
            ),
          ],
          total: 1,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const StockMovementScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Stock Out tab.
      await tester.tap(find.text('Stock Out'));
      await tester.pumpAndSettle();

      // Fill product + quantity using the keys to avoid index brittleness.
      await tester.enterText(
        find.byKey(const ValueKey('field-product')),
        'prod-1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-quantity')),
        '10',
      );

      // Pick a reason. Scroll the dropdown into view first or the tap is
      // routed at an off-screen offset.
      final reasonField = find.byKey(const ValueKey('field-reason'));
      await tester.ensureVisible(reasonField);
      await tester.pumpAndSettle();
      await tester.tap(reasonField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damage').last);
      await tester.pumpAndSettle();

      // Submit. The submit button is below the fold so make sure it's
      // visible before tapping.
      final submit = find.byKey(const ValueKey('submit-stock-movement'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // R17.3 guard: the inline error must surface and adjustStock must NOT
      // have been called.
      expect(find.text('Insufficient stock for this movement'), findsOneWidget);
      verifyNever(() => mockApi.adjustStock(any()));
    });

    testWidgets('stock out passes guard when on-hand >= requested quantity', (
      tester,
    ) async {
      when(
        () => mockApi.getInventory(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedInventory(
          items: [
            InventoryItemResponse(
              id: 'inv-1',
              productId: 'prod-1',
              quantity: 20,
            ),
          ],
          total: 1,
        ),
      );
      when(() => mockApi.adjustStock(any())).thenAnswer(
        (_) async => const InventoryItemResponse(
          id: 'inv-1',
          productId: 'prod-1',
          quantity: 15,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const StockMovementScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stock Out'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('field-product')),
        'prod-1',
      );
      await tester.enterText(find.byKey(const ValueKey('field-quantity')), '5');

      // The validator-only path: there is no inline insufficient-stock
      // error and the adjust call was issued.
      final reasonField = find.byKey(const ValueKey('field-reason'));
      await tester.ensureVisible(reasonField);
      await tester.pumpAndSettle();
      await tester.tap(reasonField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damage').last);
      await tester.pumpAndSettle();

      final submit = find.byKey(const ValueKey('submit-stock-movement'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();

      expect(find.text('Insufficient stock for this movement'), findsNothing);
      verify(() => mockApi.adjustStock(any())).called(1);
    });
  });

  group('LowStockAlertsScreen', () {
    testWidgets('shows items at or below threshold and hides healthy ones', (
      tester,
    ) async {
      when(
        () => mockApi.getInventory(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedInventory(
          items: [
            InventoryItemResponse(
              id: 'inv-1',
              productId: 'low-item',
              quantity: 2,
              lowStockThreshold: 10,
            ),
            InventoryItemResponse(
              id: 'inv-2',
              productId: 'healthy-item',
              quantity: 50,
              lowStockThreshold: 10,
            ),
          ],
          total: 2,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const LowStockAlertsScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('low-item'), findsWidgets);
      expect(find.textContaining('healthy-item'), findsNothing);
      expect(find.text('Restock'), findsOneWidget);
    });

    testWidgets('shows the healthy state when no alerts are active', (
      tester,
    ) async {
      when(
        () => mockApi.getInventory(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedInventory(
          items: [
            InventoryItemResponse(
              id: 'inv-1',
              productId: 'good-item',
              quantity: 50,
              lowStockThreshold: 10,
            ),
          ],
          total: 1,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const LowStockAlertsScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All stock levels are healthy'), findsOneWidget);
    });
  });
}
