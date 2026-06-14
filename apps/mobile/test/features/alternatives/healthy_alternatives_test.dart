// Widget tests for the healthy alternatives screen (FE-22).
//
// Covers populated list and empty-state. Mocks the typed `ApiClient`
// via mocktail and overrides the global `apiClientProvider` so no real
// HTTP traffic is attempted.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/ai_dto.dart';
import 'package:radha_mobile/core/network/dto/product_lookup_dto.dart';
import 'package:radha_mobile/features/alternatives/healthy_alternatives_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(ApiClient api, {String ean = '8901234567890'}) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HealthyAlternativesScreen(ean: ean),
    ),
  );
}

ProductLookupResult _sourceProduct(
  String ean, {
  String name = 'Frosted Flakes',
}) {
  return ProductLookupResult(
    found: true,
    product: ProductLookupItem(
      id: 'src-1',
      name: name,
      ean: ean,
      brand: 'Mega Brand',
      subCategory: 'Cereals',
    ),
  );
}

HealthyAlternative _alt({
  required String ean,
  required String name,
  String brand = 'BrandX',
  int score = 88,
  num price = 199,
}) {
  return HealthyAlternative(
    ean: ean,
    name: name,
    brand: brand,
    imageUrl: '',
    healthScore: score,
    priceInr: price,
  );
}

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('HealthyAlternativesScreen', () {
    testWidgets('renders alternative cards with name, score, and price', (
      tester,
    ) async {
      const ean = '8901234567890';
      when(
        () => api.getProductLookup(
          ean,
          includeNutrition: any(named: 'includeNutrition'),
        ),
      ).thenAnswer((_) async => _sourceProduct(ean));
      when(() => api.getHealthierAlternatives(ean)).thenAnswer(
        (_) async => [
          _alt(ean: '101', name: 'Whole Grain Oats', score: 92, price: 189),
          _alt(ean: '102', name: 'Steel Cut Oats', score: 87, price: 220),
        ],
      );

      await tester.pumpWidget(_buildApp(api, ean: ean));
      await tester.pumpAndSettle();

      // Header title says "Better choices than [productName]".
      expect(find.text('Better choices than Frosted Flakes'), findsOneWidget);

      // Card content surfaces.
      expect(find.text('Whole Grain Oats'), findsOneWidget);
      expect(find.text('Steel Cut Oats'), findsOneWidget);
      expect(find.text('92/100'), findsOneWidget);
      expect(find.text('₹189'), findsOneWidget);

      // Both per-card CTAs render.
      expect(find.text('Add to shopping list'), findsAtLeastNWidgets(1));
      expect(find.text('View'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when the alternatives list is empty', (
      tester,
    ) async {
      const ean = '8901234567890';
      when(
        () => api.getProductLookup(
          ean,
          includeNutrition: any(named: 'includeNutrition'),
        ),
      ).thenAnswer((_) async => _sourceProduct(ean));
      when(
        () => api.getHealthierAlternatives(ean),
      ).thenAnswer((_) async => const <HealthyAlternative>[]);

      await tester.pumpWidget(_buildApp(api, ean: ean));
      await tester.pumpAndSettle();

      expect(find.text('No healthier alternatives yet'), findsOneWidget);
      expect(
        find.textContaining('No healthier alternatives found in the same'),
        findsOneWidget,
      );
    });

    testWidgets(
      'falls back to the generic title when source product fetch fails',
      (tester) async {
        const ean = '8901234567890';
        when(
          () => api.getProductLookup(
            ean,
            includeNutrition: any(named: 'includeNutrition'),
          ),
        ).thenThrow(Exception('boom'));
        when(
          () => api.getHealthierAlternatives(ean),
        ).thenAnswer((_) async => [_alt(ean: '101', name: 'Whole Grain Oats')]);

        await tester.pumpWidget(_buildApp(api, ean: ean));
        await tester.pumpAndSettle();

        expect(find.text('Better choices'), findsOneWidget);
        expect(find.text('Whole Grain Oats'), findsOneWidget);
      },
    );
  });
}
