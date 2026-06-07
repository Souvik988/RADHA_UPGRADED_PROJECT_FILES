// Widget tests for the global snackbar host.
//
// We mount a minimal `MaterialApp` that wires the same
// `scaffoldMessengerKey` used in production into its `scaffoldMessengerKey`
// slot. After invoking the static facade, we pump frames and assert the
// resulting `SnackBar` rendered with the right palette + icon by reading
// the `SnackBar.backgroundColor` property directly off the widget — this
// is more robust than walking inner `Material` ancestors which Flutter's
// internals freely re-shape between releases.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/design/tokens.dart';
import 'package:radha_mobile/design/widgets/snackbar_host.dart';

Widget _harness() {
  return MaterialApp(
    scaffoldMessengerKey: scaffoldMessengerKey,
    home: const Scaffold(body: SizedBox.expand()),
  );
}

SnackBar _snackBar(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar));

void main() {
  group('SnackbarHost', () {
    testWidgets('success() shows an emerald snackbar with a check glyph', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      SnackbarHost.success('Saved successfully');

      // Pump to schedule the snack, then advance once for it to enter.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, RadhaColors.success);

      // Drain the auto-dismiss timer to satisfy flutter_test's pending-
      // timer assertion at tear-down.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('error() shows a rose snackbar with a warning glyph', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());

      SnackbarHost.error('Could not save expiry');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Could not save expiry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, RadhaColors.danger);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('info() shows a neutral surface snackbar', (tester) async {
      await tester.pumpWidget(_harness());

      SnackbarHost.info('Heads up');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Heads up'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, RadhaColors.paperRaised);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('show is a no-op when no messenger is mounted', (tester) async {
      // No widget pumped — the global key is unmounted. Calling the facade
      // must not throw.
      expect(() => SnackbarHost.success('x'), returnsNormally);
      expect(() => SnackbarHost.info('x'), returnsNormally);
      expect(() => SnackbarHost.error('x'), returnsNormally);
    });
  });
}
