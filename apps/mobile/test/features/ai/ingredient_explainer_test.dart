// Widget tests for the ingredient explainer screen (FE-19).
//
// Covers loading, error, and data shapes. Mocks the typed `ApiClient`
// via mocktail and overrides the global `apiClientProvider` so no real
// HTTP traffic is attempted.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/api_exception.dart';
import 'package:radha_mobile/core/network/dto/ai_dto.dart';
import 'package:radha_mobile/features/ai/ingredient_explainer_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(ApiClient api, {String slug = 'palm-oil'}) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IngredientExplainerScreen(slug: slug),
    ),
  );
}

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('IngredientExplainerScreen', () {
    testWidgets('shows AppBar title derived from slug while data loads', (
      tester,
    ) async {
      // Hold the future open so the loading frame is observable.
      final completer = Completer<IngredientExplanation>();
      when(
        () => api.getIngredientExplanation(
          any(),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(api));
      await tester.pump();

      // AppBar title is derived from the slug before data lands.
      expect(find.text('Palm Oil'), findsOneWidget);

      // Drain to avoid pending-timer warnings.
      completer.complete(
        const IngredientExplanation(
          slug: 'palm-oil',
          title: 'Palm Oil',
          summary: 'A vegetable oil derived from the fruit of oil palms.',
          bullets: [],
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('renders title, summary, and bullets when data arrives', (
      tester,
    ) async {
      when(
        () => api.getIngredientExplanation(
          any(),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer(
        (_) async => const IngredientExplanation(
          slug: 'palm-oil',
          title: 'Palm Oil',
          summary:
              'Palm oil is a vegetable oil derived from the fruit of oil palms.',
          bullets: [
            'High in saturated fat — keep portions small.',
            'Linked to deforestation; look for RSPO-certified suppliers.',
          ],
          healthFlags: ['low-confidence'],
        ),
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      // Title and summary both render.
      expect(find.text('Palm Oil'), findsAtLeastNWidgets(1));
      expect(
        find.textContaining('vegetable oil derived from'),
        findsOneWidget,
      );

      // Bullets surface verbatim.
      expect(
        find.text('High in saturated fat — keep portions small.'),
        findsOneWidget,
      );
      expect(find.text('Health considerations'), findsOneWidget);

      // Health-flag chip surfaces the low-confidence flag, humanised.
      expect(find.text('Low confidence'), findsOneWidget);
    });

    testWidgets('shows error state with try-again CTA on ApiException', (
      tester,
    ) async {
      when(
        () => api.getIngredientExplanation(
          any(),
          locale: any(named: 'locale'),
        ),
      ).thenThrow(
        const ApiException(
          statusCode: 500,
          code: 'E1001',
          message: 'Internal server error',
        ),
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Could not load explanation'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
