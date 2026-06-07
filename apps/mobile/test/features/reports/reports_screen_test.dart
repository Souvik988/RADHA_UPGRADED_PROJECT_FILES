// Widget tests for the Reports & Exports screen (FE-30).
//
// Mocks the typed `ApiClient` via `mocktail` and overrides
// `apiClientProvider` so no real HTTP traffic is attempted. Each
// test pumps the screen as a `MaterialApp` and asserts on rendered
// localised text.
//
// Coverage:
//   * The three tabs render with their localised labels.
//   * The Available tab surfaces the four quick-export tiles.
//   * The History tab shows its empty CTA when the API returns no
//     reports.
//   * Tapping a quick-export tile opens the generate bottom sheet.
//   * Switching to the Scheduled tab renders the schedule rows when
//     the API returns data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/reports_dto.dart';
import 'package:radha_mobile/features/reports/reports_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

class MockApiClient extends Mock implements ApiClient {}

Widget _buildApp(ApiClient api) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ReportsScreen(),
    ),
  );
}

void main() {
  late MockApiClient api;

  setUp(() {
    api = MockApiClient();
    // Default empty answers so the FutureProviders settle without throwing
    // in tests that don't care about list contents.
    when(() => api.getReports(limit: any(named: 'limit')))
        .thenAnswer((_) async => const <ReportSummary>[]);
    when(() => api.getScheduledReports())
        .thenAnswer((_) async => const <ScheduledReport>[]);
  });

  group('ReportsScreen', () {
    testWidgets('renders all three tab labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('Available tab shows the 4 quick-export tiles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Quick exports'), findsOneWidget);
      expect(find.text('Inventory snapshot'), findsOneWidget);
      expect(find.text('Expiring items'), findsOneWidget);
      expect(find.text('Sales summary'), findsOneWidget);
      expect(find.text('Audit log'), findsOneWidget);
    });

    testWidgets('History tab renders empty state when API returns no reports', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      // Switch to the History tab.
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No exports yet'), findsOneWidget);
      expect(
        find.textContaining(
          'Generate a report from the Available tab',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Scheduled tab renders empty state when no schedules exist', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scheduled'));
      await tester.pumpAndSettle();

      expect(find.text('No scheduled reports'), findsOneWidget);
      expect(
        find.textContaining('Tap New schedule'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping a quick-export tile opens the generate bottom sheet',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildApp(api));
        await tester.pumpAndSettle();

        // Tap the inventory snapshot tile. The bottom sheet should
        // expose the Generate primary CTA and a date-range row.
        await tester.tap(find.text('Inventory snapshot'));
        await tester.pumpAndSettle();

        expect(find.text('Generate'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      },
    );

    testWidgets('Scheduled tab renders rows when the API returns data', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => api.getScheduledReports()).thenAnswer(
        (_) async => <ScheduledReport>[
          ScheduledReport(
            id: '00000000-0000-0000-0000-000000000001',
            title: 'Daily expiry digest',
            type: 'expiry-summary',
            frequency: 'daily',
            status: 'active',
            hourOfDay: 9,
            lastRunAt: DateTime.utc(2026, 5, 18, 9),
            nextRunAt: DateTime.utc(2026, 5, 19, 9),
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scheduled'));
      await tester.pumpAndSettle();

      expect(find.text('Daily expiry digest'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.byTooltip('Schedule actions'), findsOneWidget);
    });
  });
}
