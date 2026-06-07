import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:radha_mobile/core/i18n/locale_controller.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [localeStorageProvider.overrideWithValue(storage)],
    );
  }

  group('LocaleController', () {
    test('default locale is English', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(localeControllerProvider), const Locale('en'));
    });

    test('hydrates locale from secure storage on construction', () async {
      when(
        () => storage.read(key: kUserLanguageKey),
      ).thenAnswer((_) async => 'hi');

      final container = makeContainer();
      addTearDown(container.dispose);

      // Touch the provider so the controller builds.
      expect(container.read(localeControllerProvider), const Locale('en'));
      // The async hydration completes after the first microtask.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(localeControllerProvider), const Locale('hi'));
    });

    test('setLocaleByCode updates state and persists', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(localeControllerProvider.notifier)
          .setLocaleByCode('ta');

      expect(container.read(localeControllerProvider), const Locale('ta'));
      verify(() => storage.write(key: kUserLanguageKey, value: 'ta')).called(1);
    });

    test('setLocaleByCode rejects unsupported codes silently', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(localeControllerProvider.notifier)
          .setLocaleByCode('zz');

      expect(container.read(localeControllerProvider), const Locale('en'));
      verifyNever(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('setLocale convenience uses the language code', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(localeControllerProvider.notifier)
          .setLocale(const Locale('mr'));

      expect(container.read(localeControllerProvider), const Locale('mr'));
      verify(() => storage.write(key: kUserLanguageKey, value: 'mr')).called(1);
    });
  });

  group('resolveSupportedLocale', () {
    test('returns the matching locale for supported codes', () {
      expect(resolveSupportedLocale('hi'), const Locale('hi'));
      expect(resolveSupportedLocale('bn'), const Locale('bn'));
      expect(resolveSupportedLocale('en'), const Locale('en'));
    });

    test('falls back to English for unsupported, null, or empty input', () {
      expect(resolveSupportedLocale(null), kDefaultLocale);
      expect(resolveSupportedLocale(''), kDefaultLocale);
      expect(resolveSupportedLocale('fr'), kDefaultLocale);
    });
  });

  group('isSupportedLanguageCode', () {
    test('accepts the six bundled languages', () {
      for (final locale in kSupportedLocales) {
        expect(
          isSupportedLanguageCode(locale.languageCode),
          isTrue,
          reason: '${locale.languageCode} should be supported',
        );
      }
    });

    test('rejects unsupported codes', () {
      expect(isSupportedLanguageCode('fr'), isFalse);
      expect(isSupportedLanguageCode(''), isFalse);
      expect(isSupportedLanguageCode('EN'), isFalse); // case sensitive
    });
  });
}
