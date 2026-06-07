// Widget tests for the OHS Dashboard screen (FE-26).
//
// The screen reads from `ohsSnapshotProvider` which derives an
// [OhsSnapshot] from the live `/dashboard/summary` response. Tests
// override the provider with seeded snapshots so every visual state
// (loading, error, empty, populated) renders deterministically.
//
// Coverage:
//   * Score-banding helper picks emerald / amber / rose for the
//     three guarded ranges.
//   * Populated snapshot renders the headline + dimension cards.
//   * Empty snapshot renders the empty CTA.
//   * Action items list surfaces the contextual rows when counters
//     are non-zero.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/network/dto/reports_dto.dart';
import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/features/ohs_dashboard/ohs_dashboard_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

Widget _buildApp({
  AsyncValue<OhsSnapshot>? snapshot,
}) {
  return ProviderScope(
    overrides: [
      if (snapshot != null)
        ohsSnapshotProvider.overrideWith((ref) async {
          if (snapshot is AsyncError<OhsSnapshot>) {
            throw snapshot.error;
          }
          return (snapshot as AsyncData<OhsSnapshot>).value;
        }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OhsDashboardScreen(),
    ),
  );
}

OhsSnapshot _populated({
  int score = 84,
  int expiry = 12,
  int lowStock = 5,
  int? wow = 3,
}) {
  return OhsSnapshot(
    ohsScore: score,
    breakdown: const <OhsBreakdown>[
      OhsBreakdown(category: 'compliance', score: 90),
      OhsBreakdown(category: 'inventoryHygiene', score: 78),
      OhsBreakdown(category: 'auditCompletion', score: 84),
    ],
    scansThisWeek: 142,
    expiryAlertsActive: expiry,
    lowStockCount: lowStock,
    weekOverWeekDelta: wow,
    trend: const <OhsTrendBar>[
      OhsTrendBar(date: '2026-05-18', score: 60),
      OhsTrendBar(date: '2026-05-19', score: 70),
      OhsTrendBar(date: '2026-05-20', score: 80),
      OhsTrendBar(date: '2026-05-21', score: 90),
      OhsTrendBar(date: '2026-05-22', score: 85),
      OhsTrendBar(date: '2026-05-23', score: 75),
      OhsTrendBar(date: '2026-05-24', score: 88),
    ],
  );
}

void main() {
  group('ohsColorForScore', () {
    test('80+ maps to brand emerald', () {
      expect(ohsColorForScore(80), RadhaColors.primary);
      expect(ohsColorForScore(100), RadhaColors.primary);
    });
    test('40-59 maps to amber warning', () {
      expect(ohsColorForScore(40), RadhaColors.warning);
      expect(ohsColorForScore(59), RadhaColors.warning);
    });
    test('below 40 maps to rose danger', () {
      expect(ohsColorForScore(0), RadhaColors.danger);
      expect(ohsColorForScore(39), RadhaColors.danger);
    });
  });

  group('OhsDashboardScreen', () {
    testWidgets(
      'renders headline score, breakdown labels and trend section',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 2200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(snapshot: AsyncData(_populated())),
        );
        await tester.pumpAndSettle();

        // Hero: caption + score + delta.
        expect(find.text('OHS SCORE'), findsOneWidget);
        expect(find.text('84'), findsAtLeastNWidgets(1));
        expect(find.textContaining('+3 from last week'), findsOneWidget);

        // Breakdown bento.
        expect(find.text('Compliance'), findsOneWidget);
        expect(find.text('Inventory hygiene'), findsOneWidget);
        expect(find.text('Audit completion'), findsOneWidget);

        // Action items header + at least one contextual row.
        expect(find.text('Action items'), findsOneWidget);
        expect(
          find.textContaining('expiry alerts need a review'),
          findsOneWidget,
        );

        // Trend section header.
        expect(find.text('Trend'), findsOneWidget);

        // Footer CTA routes to /reports.
        expect(find.text('View detailed reports'), findsOneWidget);
      },
    );

    testWidgets('empty snapshot renders the start-scanning CTA', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const empty = OhsSnapshot(
        ohsScore: 0,
        breakdown: <OhsBreakdown>[
          OhsBreakdown(category: 'compliance', score: 0),
          OhsBreakdown(category: 'inventoryHygiene', score: 0),
          OhsBreakdown(category: 'auditCompletion', score: 0),
        ],
        scansThisWeek: 0,
        expiryAlertsActive: 0,
        lowStockCount: 0,
        weekOverWeekDelta: null,
        trend: <OhsTrendBar>[],
      );

      await tester.pumpWidget(_buildApp(snapshot: const AsyncData(empty)));
      await tester.pumpAndSettle();

      expect(find.text('Build your operational health score'), findsOneWidget);
      expect(
        find.textContaining('Start scanning to build your OHS score.'),
        findsOneWidget,
      );
    });

    testWidgets('action items collapse to encouragement when counters are 0', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Score is 84 so isEmpty is false, but expiry/low-stock are zero.
      // The "Review open tasks" row is always present, so we should see
      // exactly the tasks row and no expiry / low-stock callouts.
      await tester.pumpWidget(
        _buildApp(
          snapshot: AsyncData(
            _populated(expiry: 0, lowStock: 0, wow: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review open tasks for your store'), findsOneWidget);
      expect(
        find.textContaining('expiry alerts need a review'),
        findsNothing,
      );
      expect(
        find.textContaining('low-stock alerts are unresolved'),
        findsNothing,
      );
    });
  });
}
