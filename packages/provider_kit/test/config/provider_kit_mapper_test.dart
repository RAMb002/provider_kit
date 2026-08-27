import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ProviderKit', () {
    group('custom error mapper', () {
      test('uses the mapper and passes the original error and stack trace', () {
        final originalError = Exception('Original error');
        final originalStackTrace = StackTrace.current;

        Object? receivedError;
        StackTrace? receivedStackTrace;

        ProviderKit.configure(
          errorInfoMapper: (error, stackTrace) {
            receivedError = error;
            receivedStackTrace = stackTrace;

            return const ErrorInfo(
              message: 'Unable to sign in.',
              code: 'invalid_credentials',
            );
          },
        );

        final info = ProviderKit.resolveErrorInfo(
          originalError,
          originalStackTrace,
        );

        expect(receivedError, same(originalError));
        expect(receivedStackTrace, same(originalStackTrace));

        expect(info.message, 'Unable to sign in.');
        expect(info.code, 'invalid_credentials');
      });
    });
  });
}