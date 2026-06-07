// Widget tests for the shopping list surface (Task 18 / BE-55).
//
// Covers:
//   * Renders items returned by GET /shopping-list.
//   * Tapping a checkbox PATCHes the item with `checked: true`.
//   * Tapping the delete icon DELETEs the item.
//   * The "Add" bottom sheet POSTs a new item.
//   * Empty state surfaces when the list comes back empty.
//
// Mocks the typed `ApiClient` via mocktail and overrides the global
// `apiClientProvider` so no real HTTP traffic is attempted.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/features/shopping_list/shopping_list_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

class _FakeShoppingListItemDto extends Fake implements ShoppingListItemDto {}

class _FakeUpdateShoppingListItemDto extends Fake
    implements UpdateShoppingListItemDto {}

Widget _buildApp(ApiClient api) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: const MaterialApp(home: ShoppingListScreen()),
  );
}

ShoppingListItemResponse _item({
  required String id,
  required String name,
  bool checked = false,
  int? quantity,
}) {
  return ShoppingListItemResponse(
    id: id,
    name: name,
    checked: checked,
    quantity: quantity,
  );
}

void main() {
  late MockApiClient api;

  setUpAll(() {
    registerFallbackValue(_FakeShoppingListItemDto());
    registerFallbackValue(_FakeUpdateShoppingListItemDto());
  });

  setUp(() {
    api = MockApiClient();
  });

  group('ShoppingListScreen', () {
    testWidgets('Renders shopping list items', (tester) async {
      when(() => api.getShoppingList()).thenAnswer(
        (_) async => ShoppingListResponse(
          items: [
            _item(id: 'i-1', name: 'Whole wheat bread', quantity: 2),
            _item(id: 'i-2', name: 'Greek yogurt'),
          ],
        ),
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Whole wheat bread'), findsOneWidget);
      expect(find.text('Greek yogurt'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
    });

    testWidgets(
      'Tapping checkbox calls updateShoppingListItem with checked=true',
      (tester) async {
        when(() => api.getShoppingList()).thenAnswer(
          (_) async => ShoppingListResponse(
            items: [_item(id: 'i-1', name: 'Almond milk')],
          ),
        );
        when(() => api.updateShoppingListItem(any(), any())).thenAnswer(
          (_) async => _item(id: 'i-1', name: 'Almond milk', checked: true),
        );

        await tester.pumpWidget(_buildApp(api));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        final captured = verify(
          () => api.updateShoppingListItem('i-1', captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        final body = captured.single as UpdateShoppingListItemDto;
        expect(body.checked, isTrue);
      },
    );

    testWidgets('Tapping delete icon calls deleteShoppingListItem', (
      tester,
    ) async {
      when(() => api.getShoppingList()).thenAnswer(
        (_) async => ShoppingListResponse(
          items: [_item(id: 'i-1', name: 'Olive oil')],
        ),
      );
      when(() => api.deleteShoppingListItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      verify(() => api.deleteShoppingListItem('i-1')).called(1);
    });

    testWidgets('Add item bottom sheet calls addShoppingListItem', (
      tester,
    ) async {
      when(
        () => api.getShoppingList(),
      ).thenAnswer((_) async => const ShoppingListResponse(items: []));
      when(() => api.addShoppingListItem(any())).thenAnswer(
        (_) async => _item(id: 'i-99', name: 'Brown rice', quantity: 1),
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      // Open the sheet via the FAB.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Item name'),
        'Brown rice',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity (optional)'),
        '1',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add to list'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => api.addShoppingListItem(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final body = captured.single as ShoppingListItemDto;
      expect(body.name, 'Brown rice');
      expect(body.quantity, 1);
    });

    testWidgets('Empty state shows when list is empty', (tester) async {
      when(
        () => api.getShoppingList(),
      ).thenAnswer((_) async => const ShoppingListResponse(items: []));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Your shopping list is empty'), findsOneWidget);
    });
  });
}
