// Widget tests for the conflict banner overlay (FE-34).
//
// We override `syncConflictsProvider` directly with a fixed list — this
// keeps the tests hermetic (no Drift / sqlite needed) and lets us script
// the count precisely.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/features/sync/conflict_banner.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

SyncConflict _conflict({required int id, ConflictResourceKind? kind}) {
  return SyncConflict(
    queueRowId: id,
    endpoint: '/api/v1/tasks',
    method: 'POST',
    kind: kind ?? ConflictResourceKind.task,
    retryCount: 5,
    localChange: const <String, Object?>{'title': 'Restock cooler'},
    lastError: 'HTTP 409',
  );
}

Widget _buildApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ConflictBannerOverlay(
        child: Scaffold(
          appBar: AppBar(title: const Text('Host')),
          body: const Center(child: Text('body')),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConflictBannerOverlay', () {
    testWidgets('hides when no conflicts are present', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            syncConflictsProvider.overrideWith((ref) async => const []),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // Banner copy isn't rendered.
      expect(
        find.textContaining('conflicts need your attention'),
        findsNothing,
      );
      expect(find.text('Resolve'), findsNothing);
    });

    testWidgets('renders the banner when count > 0 with plural copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            syncConflictsProvider.overrideWith(
              (ref) async => [_conflict(id: 1), _conflict(id: 2)],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2 conflicts need your attention'),
        findsOneWidget,
      );
      expect(find.text('Resolve'), findsOneWidget);
    });

    testWidgets('renders singular copy when count == 1', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            syncConflictsProvider.overrideWith(
              (ref) async => [_conflict(id: 1)],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 conflict needs your attention'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the dismiss icon hides the banner', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            syncConflictsProvider.overrideWith(
              (ref) async => [_conflict(id: 1), _conflict(id: 2)],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resolve'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      // Wait for the AnimatedSwitcher to play.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Resolve'), findsNothing);
    });
  });
}
