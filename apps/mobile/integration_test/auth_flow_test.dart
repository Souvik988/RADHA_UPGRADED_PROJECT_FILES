// Smoke test — OTP request → verify → home land.
//
// Drives the app from cold-start, types a mobile number, taps "Send OTP",
// enters the 6-digit code into the Pinput on the verify screen, and asserts
// that the router lands the user on the home dashboard.
//
// Backend is mocked end-to-end via `http_mock_adapter`; the camera, secure
// storage, package_info, and connectivity_plus plugins are all replaced by
// fakes inside the shared [IntegrationTestHarness]. No live server, no real
// device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import 'package:radha_mobile/main.dart';

import 'test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerHarnessFallbackValues);

  testWidgets('OTP request → verify → land on /home', (tester) async {
    final harness = IntegrationTestHarness.build(
      session: null,
      onboardingComplete: true,
    );
    addTearDown(harness.dispose);

    // Stub the auth endpoints the screens will hit.
    harness.adapter
      ..onPost(
        '/api/v1/auth/otp/request',
        (server) => server.reply(200, {'requestId': 'req-1', 'expiresIn': 300}),
        data: {'mobile': '+919999912345'},
      )
      ..onPost(
        '/api/v1/auth/otp/verify',
        (server) => server.reply(200, {
          'accessToken': 'access-xyz',
          'refreshToken': 'refresh-xyz',
          'user': {'id': 'u-1', 'tenantId': 't-1'},
        }),
        data: {
          'mobile': '+919999912345',
          'otp': '123456',
          'requestId': 'req-1',
        },
      )
      ..onGet(
        '/api/v1/auth/me',
        (server) => server.reply(200, {
          'user': {'id': 'u-1', 'tenantId': 't-1'},
          'roles': ['staff'],
          'storeAccess': [
            {'storeId': 's-1', 'storeName': 'Test Store', 'role': 'staff'},
          ],
        }),
      );

    // Home dashboard hits these summary endpoints once the user lands.
    _stubHomeSummaryEndpoints(harness.adapter);

    await tester.pumpWidget(
      ProviderScope(overrides: harness.overrides, child: const RadhaApp()),
    );
    await tester.pumpAndSettle();

    // 1. Land on the OTP request screen.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 2. Enter the mobile number and tap "Send OTP".
    await tester.enterText(find.byType(TextField), '9999912345');
    await tester.pump();

    final sendButton = find.widgetWithText(FilledButton, 'Send OTP');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // 3. Verify screen now visible — Pinput rendered.
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('Verify OTP'), findsOneWidget);

    // 4. Type the 6-digit OTP.
    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();

    // The verify screen waits 500ms after a successful verify before falling
    // back to a manual `context.go(/home)`. Pump well past that window so the
    // router refresh + redirect have a chance to settle.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5. Asserting the home dashboard rendered. The bento grid header
    //    "Quick actions" is a static string only the home screen renders.
    expect(find.text('Quick actions'), findsOneWidget);

    // 6. Sanity: the auth endpoints were actually invoked.
    verify(
      () => harness.storage.writeSession(any()),
    ).called(greaterThanOrEqualTo(1));
  });
}

/// Stubs the three counts the home dashboard fans out on first build so
/// the futures resolve cleanly instead of leaving `AsyncError` overlays.
void _stubHomeSummaryEndpoints(DioAdapter adapter) {
  adapter
    ..onGet(
      '/api/v1/expiry',
      (server) => server.reply(200, {
        'items': <Map<String, dynamic>>[],
        'total': 0,
        'cursor': null,
      }),
      queryParameters: {'limit': 1, 'status': 'near_expiry'},
    )
    ..onGet(
      '/api/v1/tasks',
      (server) => server.reply(200, {
        'items': <Map<String, dynamic>>[],
        'total': 0,
        'cursor': null,
      }),
      queryParameters: {'limit': 1, 'status': 'open'},
    )
    ..onGet(
      '/api/v1/inventory',
      (server) => server.reply(200, {
        'items': <Map<String, dynamic>>[],
        'total': 0,
        'cursor': null,
      }),
      queryParameters: {'limit': 1},
    );
}
