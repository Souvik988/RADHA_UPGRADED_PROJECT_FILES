// Smoke test — scan result loads product detail.
//
// The real `mobile_scanner` controller needs a camera, which doesn't exist
// under `flutter test`. To still cover the contract that R6 cares about
// — "scanning a known EAN renders that product's detail card" — this test
// drives the app pre-logged-in, navigates straight to `/scan/result/<ean>`,
// and asserts the product name, brand, and category render once the lookup
// resolves. The `GET /products/lookup/:ean` response is stubbed via
// `http_mock_adapter`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/main.dart';

import 'test_harness.dart';

/// Pre-baked authenticated session — short-circuits the OTP flow.
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerHarnessFallbackValues);

  testWidgets('scan result for a known EAN renders product detail', (
    tester,
  ) async {
    final harness = IntegrationTestHarness.build(session: _loggedInSession);
    addTearDown(harness.dispose);

    const ean = '8901234567890';

    // The /auth/me call kicked off by BootstrapController would normally
    // run; the harness replaces the bootstrap with a fake so this is
    // never invoked. Stub it defensively anyway in case the optimistic
    // refresh logic is ever re-enabled in tests.
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
        '/api/v1/products/lookup/$ean',
        (server) => server.reply(200, {
          'found': true,
          'source': 'database',
          'product': {
            'id': 'prod-1',
            'name': 'Britannia Marie Gold',
            'ean': ean,
            'brand': 'Britannia',
            'subCategory': 'Biscuits',
            'imageUrl': null,
          },
        }),
      );

    // We render the app rooted at `RadhaApp`, then push the deep-link
    // route directly. Going via the router avoids reaching for
    // `mobile_scanner` and `GoogleMlKit*` plugin code, neither of which
    // works under `flutter test`.
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RadhaApp()),
    );
    await tester.pumpAndSettle();

    // Drive the router straight to the scan-result deep link.
    container.read(appRouterProvider).go('/scan/result/$ean');
    await tester.pumpAndSettle();

    // Product detail header on the result card.
    expect(find.text('Scan Result'), findsOneWidget);

    // Name, brand, category — R6's product lookup contract.
    expect(find.text('Britannia Marie Gold'), findsOneWidget);
    expect(find.text('Britannia'), findsOneWidget);
    expect(find.text('Biscuits'), findsOneWidget);

    // EAN string is also rendered on the result card.
    expect(find.text('EAN: $ean'), findsOneWidget);
  });
}
