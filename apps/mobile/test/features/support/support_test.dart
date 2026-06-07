// Widget tests for the Support / Feedback screen (FE-37).
//
// Verifies:
//   * Bug-description validation (empty submission shows the inline error).
//   * Description and FAQ headers render.
//   * FAQ tile expansion reveals the answer body.
//
// The screen is long; we pump inside a tall viewport so all sections fit
// in one frame. For taps we scroll the target into view first.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/features/support/support_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

Future<void> _pumpSupport(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  // Tall mobile-shaped viewport so all sections fit on screen.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SupportScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupportScreen', () {
    testWidgets('renders Contact, Report a bug, and FAQ sections', (
      tester,
    ) async {
      await _pumpSupport(tester);
      expect(find.text('Contact us'), findsOneWidget);
      expect(find.text('Report a bug'), findsOneWidget);
      expect(find.text('Frequently asked questions'), findsOneWidget);
    });

    testWidgets('submitting empty bug form surfaces the inline validator', (
      tester,
    ) async {
      await _pumpSupport(tester);

      // Tap the Send report CTA without entering anything. Use the button
      // finder so we hit the FilledButton, not the inner Text.
      final sendBtn = find.widgetWithText(FilledButton, 'Send report');
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pump();

      // Validator surfaces the localized error.
      expect(find.text('Please describe what happened.'), findsOneWidget);
    });

    testWidgets('FAQ tile expansion reveals the answer body', (tester) async {
      await _pumpSupport(tester);

      // Confirm the answer is hidden before expansion.
      expect(
        find.textContaining('point your camera at the barcode'),
        findsNothing,
      );

      await tester.tap(find.text('How do I scan a barcode?'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('point your camera at the barcode'),
        findsOneWidget,
      );
    });

    testWidgets('Email and Call rows render with their hint copy', (
      tester,
    ) async {
      await _pumpSupport(tester);
      expect(find.text('Email us'), findsOneWidget);
      expect(find.text('support@radha.app'), findsOneWidget);
      expect(find.text('Call support'), findsOneWidget);
    });
  });
}
