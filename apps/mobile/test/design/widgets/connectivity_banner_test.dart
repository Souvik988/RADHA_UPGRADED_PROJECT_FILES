// Widget tests for the global connectivity banner.
//
// We override `connectivityProvider` directly with a synthetic stream so
// the widget exercises the same code path it would in production without
// reaching for the real `connectivity_plus` plugin (which requires a
// platform binding the `flutter_test` runner doesn't provide).

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/connectivity/connectivity_provider.dart';
import 'package:radha_mobile/design/widgets/connectivity_banner.dart';

Widget _harness({required List<ConnectivityResult> initial}) {
  return ProviderScope(
    overrides: [
      connectivityProvider.overrideWith(
        // `Stream.value` settles the StreamProvider into AsyncData on the
        // first frame after a single `pump`.
        (ref) => Stream<List<ConnectivityResult>>.value(initial),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: ConnectivityBanner())),
  );
}

void main() {
  group('ConnectivityBanner', () {
    testWidgets('renders nothing when online', (tester) async {
      await tester.pumpWidget(
        _harness(initial: const [ConnectivityResult.wifi]),
      );
      await tester.pump();

      expect(find.text(ConnectivityBanner.offlineMessage), findsNothing);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    testWidgets('renders Offline message when disconnected', (tester) async {
      await tester.pumpWidget(
        _harness(initial: const [ConnectivityResult.none]),
      );
      await tester.pump();

      expect(find.text(ConnectivityBanner.offlineMessage), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('treats an empty results list as offline', (tester) async {
      await tester.pumpWidget(_harness(initial: const <ConnectivityResult>[]));
      await tester.pump();

      expect(find.text(ConnectivityBanner.offlineMessage), findsOneWidget);
    });
  });
}
