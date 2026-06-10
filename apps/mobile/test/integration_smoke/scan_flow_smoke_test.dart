// Headless smoke mirror of `integration_test/scan_flow_test.dart`.
//
// The real camera scanner can't run under `flutter test`, so we navigate
// directly to the scan-result deep link and assert the product detail card
// renders for a known EAN.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/main.dart';

import 'smoke_harness.dart';

const _loggedInSession = AuthSession(
  accessToken: 'access-xyz',
  refreshToken: 'refresh-xyz',
  userId: 'u-1',
  tenantId: 't-1',
  roles: ['staff'],
  stores: [StoreAccess(storeId: 's-1', storeName: 'Test Store', role: 'staff')],
  selectedStoreId: 's-1',
);

void main() {
  setUpAll(registerSmokeFallbackValues);

  testWidgets('scan result for a known EAN renders product detail', (
    tester,
  ) async {
    final harness = SmokeHarness.build(session: _loggedInSession);
    addTearDown(harness.dispose);

    const ean = '8901234567890';

    harness.adapter
      ..onGet(
        '/api/v1/auth/me',
        (server) => server.reply(200, {
          'user': {'id': 'u-1', 'tenantId': 't-1'},
          'roles': ['staff'],
          'storeAccess': [
            {'storeId': 's-1', 'storeName': 'Test Store', 'role': 'staff'},
          ],
        }),
      )
      ..onGet(
        '/api/v1/products/ean/$ean',
        (server) => server.reply(200, {
          'id': 'prod-1',
          'name': 'Britannia Marie Gold',
          'ean': ean,
          'brand': 'Britannia',
          'category': 'Biscuits',
          'imageUrl': null,
        }),
      );

    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RadhaApp()),
    );
    // Boots to /home (Mor mascot perpetual idle) — pump bounded frames
    // instead of `pumpAndSettle` to avoid an animation timeout.
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    container.read(appRouterProvider).go('/scan/result/$ean');
    // The scan-result screen may render Mor in some states; bounded pump.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Scan Result'), findsOneWidget);
    expect(find.text('Britannia Marie Gold'), findsOneWidget);
    expect(find.text('Britannia'), findsOneWidget);
    expect(find.text('Biscuits'), findsOneWidget);
    expect(find.text('EAN: $ean'), findsOneWidget);
  });
}
