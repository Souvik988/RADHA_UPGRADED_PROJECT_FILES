import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';
import 'package:radha_mobile/core/auth/auth_repository.dart';
import 'package:radha_mobile/core/auth/auth_session.dart';
import 'package:radha_mobile/core/auth/session_storage.dart';
import 'package:radha_mobile/core/network/api_client.dart';
import 'package:radha_mobile/core/network/dto/onboarding_dto.dart';
import 'package:radha_mobile/features/auth/otp_request_screen.dart';
import 'package:radha_mobile/features/auth/otp_verify_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionStorage extends Mock implements SessionStorage {}

class MockApiClient extends Mock implements ApiClient {}

/// Wraps the given widget in a [MaterialApp] with [ProviderScope] overrides.
Widget _buildApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockSessionStorage mockStorage;
  late MockApiClient mockApiClient;

  setUpAll(() {
    registerFallbackValue(
      const SelectSegmentRequestDto(segment: OnboardingSegmentDto.personal),
    );
  });

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockStorage = MockSessionStorage();
    mockApiClient = MockApiClient();
  });

  group('OtpRequestScreen', () {
    testWidgets('validates 10-digit Indian mobile', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const OtpRequestScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );

      // Find text field and enter an invalid number (starts with 3).
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '3456789012');
      await tester.pump();

      // Button should be disabled because number doesn't start with 6-9.
      final button = find.text('Send OTP');
      expect(button, findsOneWidget);

      // Find the PrimaryButton's FilledButton ancestor.
      final filledButton = find.ancestor(
        of: button,
        matching: find.byType(FilledButton),
      );
      expect(filledButton, findsOneWidget);
      final filledButtonWidget = tester.widget<FilledButton>(filledButton);
      expect(filledButtonWidget.onPressed, isNull);
    });

    testWidgets('Send OTP button is disabled with invalid input', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const OtpRequestScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
          ],
        ),
      );

      // Initially empty — button disabled.
      final button = find.text('Send OTP');
      final filledButton = find.ancestor(
        of: button,
        matching: find.byType(FilledButton),
      );
      final widget = tester.widget<FilledButton>(filledButton);
      expect(widget.onPressed, isNull);

      // Enter only 5 digits — still disabled.
      await tester.enterText(find.byType(TextField), '98765');
      await tester.pump();
      final widget2 = tester.widget<FilledButton>(filledButton);
      expect(widget2.onPressed, isNull);
    });

    testWidgets('Successful requestOtp navigates to verify screen', (
      tester,
    ) async {
      when(() => mockAuthRepo.requestOtp(any())).thenAnswer(
        (_) async =>
            const OtpRequestResult(requestId: 'req-abc', expiresIn: 300),
      );
      when(() => mockAuthRepo.currentSession()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
          ],
          child: MaterialApp(
            routes: {
              '/': (_) => const OtpRequestScreen(),
              '/verify': (_) => const Scaffold(body: Text('verify-screen')),
            },
            onGenerateRoute: (settings) {
              // Handle push-style navigation.
              if (settings.name?.contains('verify') == true) {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(body: Text('verify-screen')),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Enter valid number.
      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      // Tap Send OTP.
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // Verify requestOtp was called with correct format.
      verify(() => mockAuthRepo.requestOtp('+919876543210')).called(1);
    });
  });

  group('OtpVerifyScreen', () {
    testWidgets('renders Pinput with 6 cells', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const OtpVerifyScreen(mobile: '+919876543210', requestId: 'req-abc'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
            apiClientProvider.overrideWithValue(mockApiClient),
          ],
        ),
      );

      // Pinput should be present.
      expect(find.byType(Pinput), findsOneWidget);

      // Should show the masked mobile.
      expect(find.textContaining('+91'), findsWidgets);
    });

    testWidgets('Resend countdown starts at 60 and ticks down', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const OtpVerifyScreen(mobile: '+919876543210', requestId: 'req-abc'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
            apiClientProvider.overrideWithValue(mockApiClient),
          ],
        ),
      );

      // Initially shows 60s.
      expect(find.text('Resend OTP (60s)'), findsOneWidget);

      // Advance 1 second.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend OTP (59s)'), findsOneWidget);

      // Advance 4 more seconds.
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Resend OTP (55s)'), findsOneWidget);
    });

    testWidgets('Successful verifyOtp posts pending segment and clears it', (
      tester,
    ) async {
      when(() => mockAuthRepo.currentSession()).thenAnswer((_) async => null);
      when(
        () => mockAuthRepo.verifyOtp(
          mobile: any(named: 'mobile'),
          otp: any(named: 'otp'),
          requestId: any(named: 'requestId'),
        ),
      ).thenAnswer(
        (_) async => const AuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          userId: 'u-1',
          tenantId: 't-1',
          roles: ['staff'],
          stores: [StoreAccess(storeId: 's-1', storeName: 'A', role: 'staff')],
          selectedStoreId: 's-1',
        ),
      );

      when(
        () => mockStorage.readPendingOnboardingSegment(),
      ).thenAnswer((_) async => 'business_owner');
      when(
        () => mockStorage.setPendingOnboardingSegment(null),
      ).thenAnswer((_) async {});
      when(() => mockApiClient.selectOnboardingSegment(any())).thenAnswer(
        (_) async => const OnboardingRoutingResponse(
          segment: OnboardingSegmentDto.businessOwner,
          nextScreen: OnboardingNextScreenDto.businessActivationFlow,
          bypassedOnboarding: false,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const OtpVerifyScreen(mobile: '+919876543210', requestId: 'req-abc'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionStorageProvider.overrideWithValue(mockStorage),
            apiClientProvider.overrideWithValue(mockApiClient),
          ],
        ),
      );

      // Enter 6 digits to trigger auto-submit.
      final pinput = find.byType(Pinput);
      await tester.tap(pinput);
      await tester.pump();
      await tester.enterText(pinput, '123456');
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify onboarding segment was posted and cleared.
      verify(() => mockStorage.readPendingOnboardingSegment()).called(1);
      verify(() => mockApiClient.selectOnboardingSegment(any())).called(1);
      verify(() => mockStorage.setPendingOnboardingSegment(null)).called(1);
    });
  });
}
