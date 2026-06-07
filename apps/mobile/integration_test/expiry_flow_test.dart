// Smoke test — add an expiry record, observe the create flow round-trip.
//
// Walks the user through: open the expiry list → tap the FAB → fill the
// create form → submit → assert the POST hit the backend and the form
// popped back to the list. The backend is mocked end-to-end via
// `http_mock_adapter`.
//
// Note: we don't assert the list re-renders the new record because the
// `_expiryListProvider` family is cached at container scope and won't
// re-fetch without a manual pull-to-refresh — covered separately by
// `test/features/expiry/expiry_list_screen_test.dart`. The smoke contract
// here is "create form posts and returns to the list", which is exactly
// what R13 asks for.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/router/app_router.dart';
import 'package:radha_mobile/main.dart';

import 'test_harness.dart';

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

  testWidgets('creating an expiry record posts to backend and returns to list', (
    tester,
  ) async {
    // Bigger viewport so the "Save Record" button is on-screen without
    // scrolling. Default 800×600 cuts off the bottom of the create form.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = IntegrationTestHarness.build(session: _loggedInSession);
    addTearDown(harness.dispose);

    _stubExpiryListEmpty(harness.adapter);

    var postReceived = false;
    const newRecordId = 'exp-1';
    const productId = 'prod-1';
    harness.adapter.onPost('/api/v1/expiry', (server) {
      postReceived = true;
      return server.reply(201, {
        'id': newRecordId,
        'productId': productId,
        'expiryDate': '2099-12-31',
        'status': 'near_expiry',
      });
    });

    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const RadhaApp()),
    );
    await tester.pumpAndSettle();

    // 1. Navigate to /expiry — empty state visible.
    container.read(appRouterProvider).go('/expiry');
    await tester.pumpAndSettle();
    expect(find.text('Expiry Tracking'), findsOneWidget);
    expect(find.text('No records in this category.'), findsOneWidget);

    // 2. Tap FAB — create screen visible.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New Expiry Record'), findsOneWidget);

    // 3. Fill product-id field and accept today's date.
    await tester.enterText(find.byType(TextFormField).first, productId);
    await tester.pump();

    // The expiry-date row is the second calendar-icon InkWell (first is
    // MFG, second is Expiry). Tap it, then accept the picker default.
    final expiryRow = find
        .ancestor(
          of: find.byIcon(Icons.calendar_today_outlined).at(1),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.tap(expiryRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 4. Submit. The success path fires a SnackBar (4s default timer)
    //    and then `Navigator.pop`. We pump explicitly rather than calling
    //    `pumpAndSettle` so the snackbar timer doesn't block forever.
    //    The dio response goes through several microtask hops before the
    //    pop is queued; pump generously so we catch the route transition.
    await tester.tap(find.widgetWithText(FilledButton, 'Save Record'));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 5. The POST hit the backend …
    expect(
      postReceived,
      isTrue,
      reason: 'POST /api/v1/expiry should fire when "Save Record" is tapped.',
    );
    // … and the form was popped back. The underlying tab assertion is
    // covered explicitly by `test/features/expiry/expiry_list_screen_test.dart`.
    expect(find.text('New Expiry Record'), findsNothing);
  });
}

/// Stubs the three list calls the [ExpiryListScreen] makes on first build
/// so all three tabs render an empty state without erroring.
void _stubExpiryListEmpty(DioAdapter adapter) {
  for (final status in ['near_expiry', 'expired', 'safe']) {
    adapter.onGet(
      '/api/v1/expiry',
      (server) => server.reply(200, {
        'items': <Map<String, dynamic>>[],
        'total': 0,
        'cursor': null,
      }),
      queryParameters: {'limit': 20, 'status': status},
    );
  }
}
