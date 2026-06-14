import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/core/network/dto/product_dto.dart';
import 'package:radha_mobile/features/product/product_detail_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;

  setUp(() {
    mockClient = MockApiClient();
  });

  Widget buildSubject(String ean) {
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(mockClient)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProductDetailScreen(ean: ean),
      ),
    );
  }

  group('ProductDetailScreen', () {
    testWidgets('renders product name, brand, and category', (tester) async {
      when(() => mockClient.getProductByEan('1234567890123')).thenAnswer(
        (_) async => const ProductResponse(
          id: 'prod-1',
          name: 'Organic Oats',
          ean: '1234567890123',
          brand: 'HealthyBrand',
          category: 'Cereals',
          imageUrl: null,
        ),
      );

      await tester.pumpWidget(buildSubject('1234567890123'));
      await tester.pumpAndSettle();

      expect(find.text('Organic Oats'), findsOneWidget);
      expect(find.text('HealthyBrand'), findsOneWidget);
      expect(find.text('Cereals'), findsOneWidget);
    });

    testWidgets('shows honest assessment-pending health state', (tester) async {
      when(() => mockClient.getProductByEan('1234567890123')).thenAnswer(
        (_) async => const ProductResponse(
          id: 'prod-1',
          name: 'Organic Oats',
          ean: '1234567890123',
          brand: 'HealthyBrand',
          category: 'Cereals',
          imageUrl: null,
        ),
      );

      await tester.pumpWidget(buildSubject('1234567890123'));
      await tester.pumpAndSettle();

      // Honest-data: the V1 ProductResponse carries no health score, so the
      // section must show an "Assessment pending" state — never a fabricated
      // "Moderate" label. (The HealthLabelChip is only used later, with real
      // backend scores, in the healthy-alternatives section.)
      expect(find.text('Health Assessment'), findsOneWidget);
      expect(find.text('Assessment pending'), findsOneWidget);
      expect(find.text('Moderate'), findsNothing);
    });

    testWidgets('explain ingredients button opens bottom sheet', (
      tester,
    ) async {
      when(() => mockClient.getProductByEan('1234567890123')).thenAnswer(
        (_) async => const ProductResponse(
          id: 'prod-1',
          name: 'Organic Oats',
          ean: '1234567890123',
          brand: 'HealthyBrand',
          category: 'Cereals',
          imageUrl: null,
        ),
      );

      when(() => mockClient.explainIngredients(any())).thenAnswer(
        (_) async => const IngredientExplainerResponse(
          explanation: 'These oats are whole grain and minimally processed.',
        ),
      );

      await tester.pumpWidget(buildSubject('1234567890123'));
      await tester.pumpAndSettle();

      // Tap the "Explain ingredients" button
      final explainButton = find.text('Explain ingredients');
      expect(explainButton, findsOneWidget);
      await tester.tap(explainButton);
      await tester.pumpAndSettle();

      // Bottom sheet should appear with the title
      expect(find.text('Ingredient Explanation'), findsOneWidget);
    });
  });
}
