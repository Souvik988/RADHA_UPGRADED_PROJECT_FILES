import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/misc_dto.dart';
import 'package:radha_mobile/features/referrals/referrals_screen.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeRedeemReferralDto extends Fake implements RedeemReferralDto {}

Widget _host(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockApiClient api;

  setUpAll(() {
    registerFallbackValue(FakeRedeemReferralDto());
  });

  setUp(() {
    api = MockApiClient();
  });

  group('ReferralsScreen', () {
    testWidgets('renders referral code and stats from API', (tester) async {
      when(() => api.getReferralStats()).thenAnswer(
        (_) async => const ReferralStatsResponse(
          referralCode: 'RADHA-7K9X2P',
          inviteeCount: 4,
          rewardsEarned: 200,
        ),
      );

      await tester.pumpWidget(
        _host(
          const ReferralsScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      // Code rendered prominently.
      expect(find.text('RADHA-7K9X2P'), findsOneWidget);
      // Stats labels and values present.
      expect(find.text('Invitees'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Rewards earned'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      // Share button is reachable.
      expect(find.text('Share invite'), findsOneWidget);
    });

    testWidgets('shows error state when the stats request fails', (
      tester,
    ) async {
      when(() => api.getReferralStats()).thenThrow(Exception('boom'));

      await tester.pumpWidget(
        _host(
          const ReferralsScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load referrals.'), findsOneWidget);
    });

    testWidgets('Redeem button calls redeemReferral with the entered code', (
      tester,
    ) async {
      when(() => api.getReferralStats()).thenAnswer(
        (_) async => const ReferralStatsResponse(
          referralCode: 'RADHA-AAA111',
          inviteeCount: 0,
          rewardsEarned: 0,
        ),
      );
      when(() => api.redeemReferral(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        _host(
          const ReferralsScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      // Type a code into the redeem field.
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter a referral code'),
        'FRIEND42',
      );
      await tester.pump();

      // Tap the Redeem button.
      final redeemButton = find.widgetWithText(FilledButton, 'Redeem');
      await tester.ensureVisible(redeemButton);
      await tester.tap(redeemButton);
      await tester.pump();

      final captured = verify(() => api.redeemReferral(captureAny())).captured;
      expect(captured, hasLength(1));
      final body = captured.single as RedeemReferralDto;
      expect(body.code, 'FRIEND42');
    });

    testWidgets('Redeem with an empty code shows a validation error', (
      tester,
    ) async {
      when(() => api.getReferralStats()).thenAnswer(
        (_) async => const ReferralStatsResponse(
          referralCode: 'RADHA-BBB222',
          inviteeCount: 0,
          rewardsEarned: 0,
        ),
      );

      await tester.pumpWidget(
        _host(
          const ReferralsScreen(),
          overrides: [apiClientProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      final redeemButton = find.widgetWithText(FilledButton, 'Redeem');
      await tester.ensureVisible(redeemButton);
      await tester.tap(redeemButton);
      await tester.pump();

      verifyNever(() => api.redeemReferral(any()));
      expect(find.text('Enter a referral code'), findsWidgets);
    });
  });
}
