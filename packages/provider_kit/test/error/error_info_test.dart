import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ErrorInfo', () {
    test('stores message and code', () {
      const info = ErrorInfo(
        message: 'Something went wrong.',
        code: 'unknown_error',
      );

      expect(info.message, 'Something went wrong.');
      expect(info.code, 'unknown_error');
    });

    test('code defaults to null', () {
      const info = ErrorInfo(
        message: 'Something went wrong.',
      );

      expect(info.code, isNull);
    });

    test('equal values are equal', () {
      const first = ErrorInfo(
        message: 'Something went wrong.',
        code: 'unknown_error',
      );

      const second = ErrorInfo(
        message: 'Something went wrong.',
        code: 'unknown_error',
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });

    test('different values are not equal', () {
      const first = ErrorInfo(
        message: 'Something went wrong.',
        code: 'unknown_error',
      );

      const second = ErrorInfo(
        message: 'Authentication failed.',
        code: 'auth_error',
      );

      expect(first, isNot(equals(second)));
    });

    test('toString returns a useful representation', () {
      const info = ErrorInfo(
        message: 'Something went wrong.',
        code: 'unknown_error',
      );

      expect(
        info.toString(),
        'ErrorInfo(message: Something went wrong., code: unknown_error)',
      );
    });
  });
}
