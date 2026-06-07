// Widget tests for the Settings hub (FE-32 / FE-33).
//
// Verifies that:
//   * All four sections render their core copy.
//   * Toggling a notification switch flips the underlying provider state.
//   * Selecting a theme segment flips the [themeModeProvider].
//   * Selecting a text-size segment flips the [textScaleProvider].
//
// The secure-storage backed controllers degrade silently in tests because
// the platform binding for `flutter_secure_storage` isn't available — they
// keep an in-memory state, which is exactly what these tests exercise.
//
// We override the test viewport to a tall mobile-shaped surface so the
// entire ListView fits without scroll gymnastics, and use
// `scrollUntilVisible` for the rows that still land off-screen on
// short devices.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/features/settings/settings_preferences.dart';
import 'package:radha_mobile/features/settings/settings_screen.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';

/// Pumps the screen inside a generously-sized viewport so the whole
/// ListView fits in one frame for assertions.
Future<ProviderContainer> pumpSettings(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  late ProviderContainer container;
  // Tall mobile-shaped viewport so the entire sectioned ListView is on
  // screen at once. 1600 logical pixels comfortably fits all four
  // sections plus their controls.
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            localizationsDelegates: const <LocalizationsDelegate<Object>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          );
        },
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen', () {
    testWidgets('renders all four section headers', (tester) async {
      await pumpSettings(tester);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('DATA & PRIVACY'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('renders notification toggle rows', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Push notifications'), findsOneWidget);
      expect(find.text('Recall alerts'), findsOneWidget);
      expect(find.text('Weekly digest'), findsOneWidget);
    });

    testWidgets(
      'tapping push notifications switch flips the provider state',
      (tester) async {
        final container = await pumpSettings(tester);

        // Default state: push enabled = true.
        expect(
          container.read(notificationPrefsProvider).pushEnabled,
          isTrue,
        );

        // The first switch on the screen is "Push notifications".
        final switches = find.byType(Switch);
        expect(switches, findsNWidgets(3));
        await tester.tap(switches.first);
        await tester.pump();

        expect(
          container.read(notificationPrefsProvider).pushEnabled,
          isFalse,
        );
      },
    );

    testWidgets('tapping the theme "Dark" segment persists ThemeMode.dark', (
      tester,
    ) async {
      final container = await pumpSettings(tester);
      expect(container.read(themeModeProvider), ThemeMode.system);
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    testWidgets('tapping the text-size "Large" segment flips the provider', (
      tester,
    ) async {
      final container = await pumpSettings(tester);
      expect(
        container.read(textScaleProvider),
        TextScalePreference.standard,
      );
      await tester.tap(find.text('Large'));
      await tester.pump();
      expect(
        container.read(textScaleProvider),
        TextScalePreference.large,
      );
    });

    testWidgets('renders Data & privacy destructive rows', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Sign out from all devices'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('renders About section with Terms / Privacy / Support', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('Terms of service'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      // "Support" appears as a row label in the About section.
      expect(find.text('Support'), findsOneWidget);
    });
  });
}
