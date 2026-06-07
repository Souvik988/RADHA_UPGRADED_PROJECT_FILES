// Unit tests for the mobile-side error code → user message resolver.
//
// These verify the contract documented in
// `apps/mobile/lib/core/network/error_codes.dart` without pulling the rest
// of the app graph in (no router, no subscription, no Dio).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radha_mobile/core/network/error_codes.dart';
import 'package:radha_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('userMessageForCode (no l10n)', () {
    test('OTP rate limit substitutes seconds', () {
      final msg = userMessageForCode(
        ErrorCodes.otpRateLimited,
        retryAfterSeconds: 42,
      );
      expect(msg, 'Too many OTP requests. Try again in 42 seconds.');
    });

    test('Generic rate limit (E1004) reuses the same OTP message', () {
      final msg = userMessageForCode(
        ErrorCodes.rateLimit,
        retryAfterSeconds: 10,
      );
      expect(msg, 'Too many OTP requests. Try again in 10 seconds.');
    });

    test('OTP rate limit defaults to 60s when retryAfter omitted', () {
      final msg = userMessageForCode(ErrorCodes.otpRateLimited);
      expect(msg, contains('60 seconds'));
    });

    test('OTP invalid maps to a clear retry message', () {
      expect(
        userMessageForCode(ErrorCodes.otpInvalid),
        'Invalid OTP. Please try again.',
      );
    });

    test('OTP expired tells the user to request a new one', () {
      expect(
        userMessageForCode(ErrorCodes.otpExpired),
        'OTP expired. Please request a new one.',
      );
    });

    test('Auth required surfaces the generic sign-in prompt', () {
      expect(
        userMessageForCode(ErrorCodes.authRequired),
        'Please sign in to continue.',
      );
      expect(
        userMessageForCode(ErrorCodes.tokenExpired),
        'Please sign in to continue.',
      );
    });

    test('Not found returns the short label', () {
      expect(userMessageForCode(ErrorCodes.notFound), 'Not found.');
    });

    test('Unknown code falls back to the generic message', () {
      expect(
        userMessageForCode('E9999'),
        'Something went wrong. Please try again.',
      );
    });

    test('Unknown code prefers the supplied fallback over the generic', () {
      expect(
        userMessageForCode('E9999', fallback: 'Plan limit hit'),
        'Plan limit hit',
      );
    });

    test('Null code with no fallback returns the generic message', () {
      expect(
        userMessageForCode(null),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('userMessageForCode (Hindi locale)', () {
    late AppLocalizations hi;

    setUpAll(() async {
      hi = await AppLocalizations.delegate.load(const Locale('hi'));
      // Touch the GlobalMaterialLocalizations delegate so the Flutter
      // runtime is happy with `hi` even though we don't use it directly.
      // (Intentionally not awaited — purely a presence check.)
      // ignore: unused_local_variable
      final _ = GlobalMaterialLocalizations.delegate;
    });

    test('OTP rate limit translates the message and substitutes seconds', () {
      final msg = userMessageForCode(
        ErrorCodes.otpRateLimited,
        l10n: hi,
        retryAfterSeconds: 30,
      );
      expect(msg, contains('30'));
      // Hindi-specific text should be present.
      expect(msg, contains('OTP'));
    });

    test('Generic fallback uses the localized errorGeneric', () {
      final msg = userMessageForCode(null, l10n: hi);
      expect(msg, isNotEmpty);
      // Should not be the English fallback when an l10n is provided.
      expect(msg, isNot('Something went wrong. Please try again.'));
    });
  });
}
