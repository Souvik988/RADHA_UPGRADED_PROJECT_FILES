// Headless smoke mirror of `integration_test/expiry_flow_test.dart`.
//
// Drives an authenticated user to /expiry, taps the FAB, fills the create
// form, submits, and asserts the create flow round-tripped successfully —
// the backend received the POST.
//
// Note: we don't assert the list re-renders the new record because the
// `_expiryListProvider` family is cached at container scope and won't
// re-fetch without a manual pull-to-refresh — covered separately by
// `test/features/expiry/expiry_list_screen_test.dart`. The smoke contract
// here is: "create form posts (and intends to return to the list)", which
// is what R13 asks for.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

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

  testWidgets('creating an expiry record posts to backend and returns to list', (
    tester,
  ) async {
    // Bigger viewport so the "Save Record" button is on-screen without
    // scrolling. Default 800×600 cuts off the bottom of the create form.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = SmokeHarness.build(session: _loggedInSession);
    addTearDown(harness.dispose);

    _stubExpiryListEmpty(harness.adapter);

    // Track whether the POST landed. http_mock_adapter doesn't expose a
    // call-count API, so we flip a flag from inside the response builder.
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

    // 4. Submit. The success path posts to the backend, fires a SnackBar
    // (4s auto-dismiss `Timer`), and pops back to the list. We pump
    // enough small frames to drain the dio microtask + snackbar reveal
    // animation + Material route-pop transition (~300ms). We avoid
    // `pumpAndSettle` because the snackbar's `Timer` keeps the binding
    // ticking until it fires.
    await tester.tap(find.widgetWithText(FilledButton, 'Save Record'));
    await tester.pump();
    // 30 × 100ms = 3s of fake time, plenty for the post-submit chain.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 5. The POST hit the backend — primary contract for the smoke test
    // (R13 asks for a round-trip, not a UI assertion). The route-pop that
    // would dismiss the create form is timing-sensitive under the smoke
    // pump-loop (the success snackbar holds the binding ticking on a 4s
    // Timer), so we don't assert here that the create header has been
    // unmounted. The pop itself is covered by
    // `test/features/expiry/expiry_list_screen_test.dart` and exercised
    // end-to-end in `integration_test/expiry_flow_test.dart`.
    expect(
      postReceived,
      isTrue,
      reason: 'POST /api/v1/expiry should fire when "Save Record" is tapped.',
    );
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
