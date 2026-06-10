import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/catalog_dto.dart';
import 'package:radha_mobile/core/network/dto/product_lookup_dto.dart';
import 'package:radha_mobile/features/catalog/catalog_search_screen.dart';
import 'package:radha_mobile/features/catalog/featured_rail.dart';
import 'package:radha_mobile/features/catalog/product_browse_screen.dart';
import 'package:radha_mobile/features/catalog/product_detail_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _app(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    // Empty server catalog → the bundled launch catalog stands alone (the
    // offline-first path). Also covers "DB not yet seeded".
    when(
      () => mockApi.getCatalogCategories(),
    ).thenAnswer((_) async => <CatalogCategory>[]);
    when(
      () => mockApi.getCatalogProducts(
        category: any(named: 'category'),
        q: any(named: 'q'),
        sort: any(named: 'sort'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const CatalogBrowsePage(items: [], nextCursor: null),
    );
  });

  group('ProductBrowseScreen', () {
    testWidgets('renders the bundled launch catalog for a category offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ProductBrowseScreen(categoryId: 'biscuits'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biscuits & Snacks'), findsOneWidget);
      // A curated product from the launch catalog shows even with an empty DB.
      expect(find.text('Parle-G Glucose Biscuits'), findsOneWidget);
    });

    testWidgets('shows the sort control + veg filter', (tester) async {
      await tester.pumpWidget(
        _app(
          const ProductBrowseScreen(categoryId: 'dairy'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Healthiest'), findsOneWidget);
      expect(find.text('A–Z'), findsOneWidget);
      expect(find.text('Veg'), findsOneWidget);
    });
  });

  group('CatalogProductDetailScreen', () {
    testWidgets('renders free content + locked Plus sections (honest)', (
      tester,
    ) async {
      // No subscription → not entitled → premium sections render locked.
      when(() => mockApi.getSubscription()).thenThrow(Exception('no plan'));

      await tester.pumpWidget(
        _app(
          // Slug route (no EAN yet) → curated identity + honest pending states.
          const CatalogProductDetailScreen(routeKey: 'parle-g-biscuits'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      // Header identity renders immediately (above the fold).
      expect(find.text('Parle-G Glucose Biscuits'), findsOneWidget);

      // The "would you buy" engagement block and the gated Plus deep-dive sit
      // lower in the scrollable detail body — scroll them into view before
      // asserting (the test viewport is shorter than the full screen).
      final wouldYouBuy = find.text('Would you buy this product?');
      await tester.scrollUntilVisible(
        wouldYouBuy,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(wouldYouBuy, findsOneWidget);

      // The premium deep-dive is gated, not fabricated.
      final unlock = find.textContaining('Unlock with');
      await tester.scrollUntilVisible(
        unlock.first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(unlock, findsWidgets);
    });

    testWidgets('renders REAL nutrients when the lookup resolves (free tier)', (
      tester,
    ) async {
      when(() => mockApi.getSubscription()).thenThrow(Exception('no plan'));
      // `britannia-white-bread` carries a resolved EAN, so the detail performs
      // a real lookup — which we stub with genuine per-100g nutrition.
      when(
        () => mockApi.getProductLookup(
          any(),
          includeNutrition: any(named: 'includeNutrition'),
        ),
      ).thenAnswer(
        (_) async => const ProductLookupResult(
          found: true,
          product: ProductLookupItem(
            id: 'p1',
            ean: '8901063342354',
            name: 'Britannia White Bread',
            nutrition: ProductNutrition(
              calories: 250,
              protein: 9,
              carbohydrates: 48,
              sugars: 5,
              fat: 3,
              sodium: 0.5,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        _app(
          const CatalogProductDetailScreen(routeKey: 'britannia-white-bread'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      // Real nutrient panel renders (never fabricated — only because the
      // lookup returned values).
      final keyNutrients = find.text('Key nutrients');
      await tester.scrollUntilVisible(
        keyNutrients,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(keyNutrients, findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
    });

    testWidgets('shows honest "scan to unlock" when a resolved EAN has no '
        'nutrition yet', (tester) async {
      when(() => mockApi.getSubscription()).thenThrow(Exception('no plan'));
      // EAN resolves but the catalog has no nutrition for it yet → honest
      // scan-driver state, never zero-faked values.
      when(
        () => mockApi.getProductLookup(
          any(),
          includeNutrition: any(named: 'includeNutrition'),
        ),
      ).thenAnswer((_) async => const ProductLookupResult(found: false));

      await tester.pumpWidget(
        _app(
          const CatalogProductDetailScreen(routeKey: 'britannia-white-bread'),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      final scan = find.text('Scan to unlock');
      await tester.scrollUntilVisible(
        scan,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(scan, findsOneWidget);
    });
  });

  group('FeaturedProductsRail', () {
    testWidgets('renders curated launch products when the catalog is empty', (
      tester,
    ) async {
      // Empty server catalog (from setUp) → the rail falls back to the curated
      // launch spread, so the consumer home is populated offline / day one.
      await tester.pumpWidget(
        _app(
          const Scaffold(body: FeaturedProductsRail()),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Featured products'), findsOneWidget);
      expect(find.text('Parle-G Glucose Biscuits'), findsOneWidget);
    });
  });

  group('CatalogSearchScreen', () {
    testWidgets('prompts, then filters the launch catalog by query (offline)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const CatalogSearchScreen(),
          overrides: [apiClientProvider.overrideWithValue(mockApi)],
        ),
      );
      await tester.pumpAndSettle();

      // Type-to-search prompt before any input.
      expect(find.text('Find a product'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'amul');
      // Past the 300ms input debounce, then let results resolve.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Curated launch matches show even with an empty server catalog.
      expect(find.text('Amul Butter'), findsOneWidget);
      // A non-matching product is filtered out.
      expect(find.text('Parle-G Glucose Biscuits'), findsNothing);
    });
  });
}
