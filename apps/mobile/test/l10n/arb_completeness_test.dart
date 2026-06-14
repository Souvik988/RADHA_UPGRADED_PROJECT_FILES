import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards localization completeness: every locale must define exactly the same
/// message keys as the English template, and no value may be blank. This is the
/// "ARB-completeness test" — it fails loudly the moment a new string is added to
/// one locale (usually en) without being translated into the others, so the app
/// can never ship a screen that silently falls back to English for some users.
void main() {
  const arbDir = 'lib/l10n';
  const template = 'en';
  const locales = <String>['en', 'hi', 'ta', 'te', 'bn', 'mr'];

  // Plain (non-`expect`) loader so it can also run during group setup, where
  // `expect` would throw OutsideTestException.
  Map<String, dynamic> loadArb(String locale) {
    final file = File('$arbDir/app_$locale.arb');
    if (!file.existsSync()) {
      throw StateError('missing ARB file for "$locale" at ${file.path}');
    }
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  // Message keys = top-level keys that are not @-metadata (@key) or @@locale.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  group('ARB locale completeness', () {
    final templateKeys = messageKeys(loadArb(template));

    test('template ($template) has keys', () {
      expect(templateKeys, isNotEmpty);
    });

    for (final locale in locales.where((l) => l != template)) {
      test('$locale defines exactly the $template message keys', () {
        final keys = messageKeys(loadArb(locale));
        final missing = templateKeys.difference(keys).toList()..sort();
        final extra = keys.difference(templateKeys).toList()..sort();
        expect(
          missing,
          isEmpty,
          reason: '$locale is missing translations for: ${missing.join(', ')}',
        );
        expect(
          extra,
          isEmpty,
          reason: '$locale has keys not present in $template: ${extra.join(', ')}',
        );
      });
    }

    test('no locale has a blank message value', () {
      for (final locale in locales) {
        final arb = loadArb(locale);
        for (final entry in arb.entries) {
          if (entry.key.startsWith('@')) continue;
          final value = entry.value;
          expect(
            value is String && value.trim().isNotEmpty,
            isTrue,
            reason: 'blank/non-string value at $locale.${entry.key}',
          );
        }
      }
    });
  });
}
