// Headless smoke mirror of `integration_test/auth_flow_test.dart`.
//
// Drives the cold-start → OTP → home flow under `flutter test` (widget
// mode) so we can verify the harness wiring works without a connected
// device. The integration_test/ counterpart asserts the same behaviour
// against [IntegrationTestWidgetsFlutterBinding].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import 'package:radha_mobile/main.dart';

import 'smoke_harness.dart';

void main() {
  setUpAll(registerSmokeFallbackValues);

  testWidgets('OTP request → verify → land on /home', (tester) async {
    final harness = SmokeHarness.build(session: null);
    addTearDown(harness.dispose);

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

    _stubHomeSummaryEndpoints(harness.adapter);

    await tester.pumpWidget(
      ProviderScope(overrides: harness.overrides, child: const RadhaApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9999912345');
    await tester.pump();

    final sendButton = find.widgetWithText(FilledButton, 'Send OTP');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('Verify OTP'), findsOneWidget);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Quick actions'), findsOneWidget);

    verify(
      () => harness.storage.writeSession(any()),
    ).called(greaterThanOrEqualTo(1));
  });
}

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
