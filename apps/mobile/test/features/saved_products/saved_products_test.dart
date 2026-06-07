// Legacy widget test for the saved products screen (FE-16).
//
// This file pre-dates the BE-XX `GET /api/v1/saved-products` route and
// covered the placeholder empty state. The screen now consumes a real
// API call backed by `SavedProductDto`; the canonical smoke test lives
// in `saved_products_screen_test.dart`. We keep this file so the older
// override-based contract is still exercised: when the Riverpod
// provider is overridden with a populated list, the screen renders the
// product cards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/network/dto/saved_product_dto.dart';
import 'package:radha_mobile/features/saved_products/saved_products_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

Widget _buildApp({List<SavedProductDto>? overrideItems}) {
  return ProviderScope(
    overrides: [
      if (overrideItems != null)
        savedProductsProvider.overrideWith((ref) async => overrideItems),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SavedProductsScreen(),
    ),
  );
}

void main() {
  group('SavedProductsScreen (provider override)', () {
    testWidgets(
      'shows the empty state when the provider returns no items',
      (tester) async {
        await tester.pumpWidget(_buildApp(overrideItems: const []));
        await tester.pumpAndSettle();

        expect(find.text('Saved products'), findsAtLeastNWidgets(1));
        expect(
          find.textContaining(
            'Save products from the scan result screen to see them here.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders saved-product cards when the provider yields data',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            overrideItems: const [
              SavedProductDto(
                id: '11111111-1111-1111-1111-111111111111',
                userId: '22222222-2222-2222-2222-222222222222',
                productName: 'Whole Grain Oats',
                productId: null,
                barcode: '8901234567890',
                expiresAt: null,
                markedConsumedAt: null,
                notes: null,
                createdAt: '2026-05-20T08:30:00Z',
                updatedAt: '2026-05-20T08:30:00Z',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Whole Grain Oats'), findsOneWidget);
      },
    );
  });
}
