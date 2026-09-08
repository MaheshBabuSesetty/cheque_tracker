import 'package:cheque_tracker/core/utils/phone_country_codes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectPhoneCountryCode', () {
    test('plain local digits with no prefix are not detected as a full number', () {
      expect(detectPhoneCountryCode('501234567'), isNull);
    });

    test('detects a 3-digit code (UAE) and splits off the local number', () {
      final result = detectPhoneCountryCode('+971501234567');
      expect(result!.countryCode, '+971');
      expect(result.localNumber, '501234567');
    });

    test('detects a 2-digit code (India) without colliding with a 3-digit code', () {
      final result = detectPhoneCountryCode('+91 98765 43210');
      expect(result!.countryCode, '+91');
      expect(result.localNumber, '9876543210');
    });

    test('normalizes a "00" international dialing prefix the same as "+"', () {
      final result = detectPhoneCountryCode('00971501234567');
      expect(result!.countryCode, '+971');
      expect(result.localNumber, '501234567');
    });

    test('a leading "+" with no matching known code returns null', () {
      expect(detectPhoneCountryCode('+999501234567'), isNull);
    });
  });
}
