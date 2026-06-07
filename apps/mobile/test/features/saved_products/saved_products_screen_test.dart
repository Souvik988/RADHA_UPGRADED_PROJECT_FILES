// Smoke widget tests for the saved products screen (FE-16).
//
// Mocks the typed `ApiClient` via mocktail and overrides the global
// `apiClientProvider` so no real HTTP traffic is attempted.
//
// Coverage:
//   * Renders both products returned by `getSavedProducts()`.
//   * Surfaces the localised error message when the API client throws
//     a `DioException` whose payload error has `code='internal'`.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/api_exception.dart';
import 'package:radha_mobile/core/network/dto/saved_product_dto.dart';
import 'package:radha_mobile/features/saved_products/saved_products_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class _MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(ApiClient api) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SavedProductsScreen(),
    ),
  );
}

SavedProductDto _row({
  required String id,
  required String productName,
  String? barcode,
}) {
  return SavedProductDto(
    id: id,
    userId: '00000000-0000-0000-0000-000000000001',
    productName: productName,
    productId: null,
    barcode: barcode,
    expiresAt: null,
    markedConsumedAt: null,
    notes: null,
    createdAt: '2026-05-20T08:30:00Z',
    updatedAt: '2026-05-20T08:30:00Z',
  );
}

void main() {
  late _MockApiClient api;

  setUp(() {
    api = _MockApiClient();
  });

  group('SavedProductsScreen', () {
    testWidgets('renders product names from getSavedProducts()', (
      tester,
    ) async {
      when(
        () => api.getSavedProducts(
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => ListSavedProductsResponse(
          items: [
            _row(
              id: '11111111-1111-1111-1111-111111111111',
              productName: 'Whole Grain Oats',
              barcode: '8901234567890',
            ),
            _row(
              id: '22222222-2222-2222-2222-222222222222',
              productName: 'Greek Yogurt',
            ),
          ],
        ),
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Whole Grain Oats'), findsOneWidget);
      expect(find.text('Greek Yogurt'), findsOneWidget);
    });

    testWidgets(
      'renders the error widget when the API throws a DioException',
      (tester) async {
        // The Dio error path: ErrorInterceptor maps server payloads to
        // typed ApiException subclasses and re-emits them inside
        // DioException.error. Anything Dio throws after that bubbles
        // through Retrofit as a DioException with the typed exception
        // attached.
        final request = RequestOptions(path: '/api/v1/saved-products');
        when(
          () => api.getSavedProducts(
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            error: const ApiException(
              statusCode: 500,
              code: 'internal',
              message: 'Internal server error',
            ),
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 500,
              data: const {'code': 'internal', 'message': 'Internal'},
            ),
          ),
        );

        await tester.pumpWidget(_buildApp(api));
        await tester.pumpAndSettle();

        expect(find.text('Could not load saved products'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
      },
    );
  });
}
