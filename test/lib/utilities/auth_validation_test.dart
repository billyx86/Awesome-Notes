import 'package:awesomenotes/utilities/auth_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateAuthFields', () {
    test('accepts a non-empty email and password', () {
      expect(
        validateAuthFields('user@example.com', 'password1'),
        isNull,
      );
    });

    test('rejects an empty email', () {
      final result = validateAuthFields('', 'password1');
      expect(result, isNotNull);
      expect(result, contains('email'));
    });

    test('rejects a whitespace-only email', () {
      final result = validateAuthFields('   ', 'password1');
      expect(result, isNotNull);
      expect(result, contains('email'));
    });

    test('rejects an empty password', () {
      final result = validateAuthFields('user@example.com', '');
      expect(result, isNotNull);
      expect(result, contains('password'));
    });

    test('rejects when both fields are empty, reporting the email first', () {
      final result = validateAuthFields('', '');
      expect(result, isNotNull);
      expect(result, contains('email'));
    });
  });
}
