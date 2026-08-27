import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ProviderKit', () {
    group('default error mapper', () {
      test('uses error.toString() when no mapper is configured', () {
        final error = Exception('Something went wrong.');
        final stackTrace = StackTrace.current;

        final info = ProviderKit.resolveErrorInfo(
          error,
          stackTrace,
        );

        expect(info.message, error.toString());
        expect(info.code, isNull);
      });

      test('uses the default mapper when configured without a mapper', () {
        ProviderKit.configure();

        final error = Exception('Something went wrong.');
        final stackTrace = StackTrace.current;

        final info = ProviderKit.resolveErrorInfo(
          error,
          stackTrace,
        );

        expect(info.message, error.toString());
        expect(info.code, isNull);
      });
    });
  });
}