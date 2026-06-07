import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Global test harness configuration, auto-loaded by `flutter test` for every
/// test in this package (Flutter looks for `flutter_test_config.dart` at the
/// `test/` root and wraps the whole suite in [testExecutable]).
///
/// We force the framework's reduced-motion flag ON for the entire suite. The
/// RADHA design system honours `MediaQuery.disableAnimations` everywhere —
/// most importantly [MorCompanion]'s perpetual "breathing" idle, which uses
/// `AnimationController.repeat()`. A `repeat()` animation never settles, so
/// without this flag any widget test that calls `pumpAndSettle()` on a screen
/// that renders Mor (now nearly every empty/error state) hangs until it times
/// out.
///
/// Enabling reduced-motion makes those animations collapse to a single static
/// frame — exactly the production behaviour on a device with "remove
/// animations" turned on — so the tests exercise a real, supported code path
/// and `pumpAndSettle()` completes deterministically. Production behaviour is
/// unaffected: this only sets a flag inside the test binding.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  await testMain();
}
