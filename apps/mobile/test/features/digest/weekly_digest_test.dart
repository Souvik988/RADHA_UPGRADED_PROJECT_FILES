// Widget tests for the Weekly Digest landing screen (FE-24).
//
// Mocks the typed `ApiClient` via `mocktail` and overrides the
// `apiClientProvider` so no real HTTP traffic is attempted. Each test
// pumps the screen as a `MaterialApp` and asserts on rendered
// localised text.
//
// Coverage:
//   * Loading state renders the shimmer skeleton (CircularProgressIndicator
//     is intentionally not used — we lean on `SkeletonLoader`).
//   * Empty digest (all counters zero) renders the empty CTA.
//   * Populated digest renders the headline, week range, scan count,
//     a top category bar, and a highlight bullet.
//   * Error state renders try-again when the API throws.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/design/widgets/skeleton_loader.dart';
import 'package:radha_mobile/features/digest/weekly_digest_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(ApiClient api, {String? weekIso}) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WeeklyDigestScreen(weekIso: weekIso),
    ),
  );
}

WeeklyDigestResponse _populated() => const WeeklyDigestResponse(
      weekIso: '2026-W21',
      weekStartDate: '2026-05-18',
      weekEndDate: '2026-05-24',
      scansCount: 12,
      savedProductsCount: 3,
      expiringSoonCount: 2,
      recallAlertsCount: 0,
      estimatedSavingsInr: 248,
      topCategories: [
        WeeklyDigestTopCategory(category: 'Snacks', count: 6),
        WeeklyDigestTopCategory(category: 'Beverages', count: 4),
      ],
      healthHighlights: [
        'You scanned three lower-sugar swaps this week.',
      ],
    );

WeeklyDigestResponse _empty() => const WeeklyDigestResponse();

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
  });

  group('WeeklyDigestScreen', () {
    testWidgets('shows the skeleton loader while the request is in flight', (
      tester,
    ) async {
      // A completer keeps the future pending — the screen should sit
      // in the loading state until we explicitly resolve it.
      final completer = Completer<WeeklyDigestResponse>();
      when(() => api.getWeeklyDigest()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(_buildApp(api));
      // First frame: the FutureProvider hasn't resolved yet.
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);

      // Resolve so the test can tear down cleanly.
      completer.complete(_empty());
      await tester.pumpAndSettle();
    });

    testWidgets('renders the empty CTA when the week has no activity', (
      tester,
    ) async {
      when(() => api.getWeeklyDigest()).thenAnswer((_) async => _empty());

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('No activity this week'), findsOneWidget);
      expect(
        find.textContaining('Start scanning to build your weekly story'),
        findsOneWidget,
      );
      // The empty state still surfaces the primary CTA so the user can
      // jump straight back into scanning.
      expect(find.text('Continue scanning'), findsOneWidget);
    });

    testWidgets(
      'renders headline, range, scan count, top category and highlight',
      (tester) async {
        when(() => api.getWeeklyDigest())
            .thenAnswer((_) async => _populated());

        // Use a larger surface so the entire ListView lays out without
        // having to scroll — the highlight bullet sits past the bento
        // grid and would otherwise live below the default 600px test
        // viewport.
        await tester.binding.setSurfaceSize(const Size(900, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildApp(api));
        await tester.pumpAndSettle();

        // Hero title (English locale).
        expect(find.text('Your week with RADHA'), findsAtLeastNWidgets(1));

        // Week range — `intl` uses non-breaking spaces in some places,
        // so match by substring rather than the full string.
        expect(find.textContaining('May 18'), findsOneWidget);
        expect(find.textContaining('May 24'), findsOneWidget);

        // Bento stats expose the raw scan count.
        expect(find.text('12'), findsAtLeastNWidgets(1));

        // Hero metric — savings preferred when > 0.
        expect(find.text('₹248 saved'), findsOneWidget);

        // Top category surfaces with its label and count.
        expect(find.text('Snacks'), findsOneWidget);
        expect(find.text('6'), findsAtLeastNWidgets(1));

        // Health highlight bullet is rendered. Scroll the list to make
        // sure the widget is in the visible viewport — it's near the
        // bottom of the digest layout.
        await tester.scrollUntilVisible(
          find.textContaining('lower-sugar swaps this week'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(
          find.textContaining('lower-sugar swaps this week'),
          findsOneWidget,
        );

        // Footer CTAs.
        expect(find.text('Continue scanning'), findsOneWidget);
        expect(find.text('Share my week'), findsOneWidget);
      },
    );

    testWidgets('renders try-again when the API throws an error', (
      tester,
    ) async {
      when(() => api.getWeeklyDigest()).thenThrow(Exception('boom'));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Could not load your weekly digest'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
