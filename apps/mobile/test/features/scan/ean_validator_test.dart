import 'package:flutter_test/flutter_test.dart';
import 'package:radha_mobile/features/scan/utils/ean_validator.dart';

void main() {
  group('isValidEan', () {
    test('validates correct EAN-13', () {
      // 5901234123457 is a standard EAN-13 test code
      expect(isValidEan('5901234123457'), isTrue);
      expect(isValidEan('4006381333931'), isTrue);
    });

    test('validates correct EAN-8', () {
      expect(isValidEan('96385074'), isTrue);
      expect(isValidEan('65833254'), isTrue);
    });

    test('validates correct UPC-A (12 digits)', () {
      expect(isValidEan('012345678905'), isTrue);
      expect(isValidEan('123456789012'), isTrue);
    });

    test('rejects invalid checksum EAN-13', () {
      // Last digit changed
      expect(isValidEan('5901234123456'), isFalse);
      expect(isValidEan('5901234123458'), isFalse);
    });

    test('rejects invalid checksum EAN-8', () {
      expect(isValidEan('96385075'), isFalse);
    });

    test('rejects invalid checksum UPC-A', () {
      expect(isValidEan('012345678906'), isFalse);
    });

    test('rejects non-numeric strings', () {
      expect(isValidEan('abcdefghijklm'), isFalse);
      expect(isValidEan('590123412345a'), isFalse);
      expect(isValidEan(''), isFalse);
    });

    test('rejects wrong length codes', () {
      expect(isValidEan('12345'), isFalse);
      expect(isValidEan('1234567890'), isFalse);
      expect(isValidEan('12345678901234'), isFalse);
    });
  });

  group('getEanType', () {
    test('returns ean13 for valid 13-digit code', () {
      expect(getEanType('5901234123457'), EanType.ean13);
    });

    test('returns ean8 for valid 8-digit code', () {
      expect(getEanType('96385074'), EanType.ean8);
    });

    test('returns upcA for valid 12-digit code', () {
      expect(getEanType('012345678905'), EanType.upcA);
    });

    test('returns null for invalid codes', () {
      expect(getEanType('1234567890'), isNull);
      expect(getEanType('invalid'), isNull);
      expect(getEanType(''), isNull);
    });
  });
}
