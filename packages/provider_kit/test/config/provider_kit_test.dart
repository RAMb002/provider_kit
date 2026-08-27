import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

final class _TestObserver extends NotifierObserver {
  const _TestObserver();
}

void main() {
  setUp(() {
    ProviderKit.resetForTesting();
  });

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

    group('custom error mapper', () {
      test('uses the configured mapper', () {
        ProviderKit.configure(
          errorInfoMapper: (error, stackTrace) {
            return const ErrorInfo(
              message: 'Unable to sign in.',
              code: 'invalid_credentials',
            );
          },
        );

        final info = ProviderKit.resolveErrorInfo(
          Exception('original error'),
          StackTrace.current,
        );

        expect(info.message, 'Unable to sign in.');
        expect(info.code, 'invalid_credentials');
      });

      test('passes the original error and stack trace to the mapper', () {
        final originalError = Exception('Original error');
        final originalStackTrace = StackTrace.current;

        Object? receivedError;
        StackTrace? receivedStackTrace;

        ProviderKit.configure(
          errorInfoMapper: (error, stackTrace) {
            receivedError = error;
            receivedStackTrace = stackTrace;

            return const ErrorInfo(
              message: 'Mapped error.',
            );
          },
        );

        final info = ProviderKit.resolveErrorInfo(
          originalError,
          originalStackTrace,
        );

        expect(receivedError, same(originalError));
        expect(receivedStackTrace, same(originalStackTrace));
        expect(info.message, 'Mapped error.');
      });
    });

    group('observer configuration', () {
      test('accepts a custom observer', () {
        const observer = _TestObserver();

        expect(
          () => ProviderKit.configure(
            observer: observer,
          ),
          returnsNormally,
        );
      });

      test('accepts mapper and observer together', () {
        const observer = _TestObserver();

        expect(
          () => ProviderKit.configure(
            errorInfoMapper: (error, stackTrace) {
              return const ErrorInfo(
                message: 'Mapped error.',
                code: 'mapped_error',
              );
            },
            observer: observer,
          ),
          returnsNormally,
        );

        final info = ProviderKit.resolveErrorInfo(
          Exception('original error'),
          StackTrace.current,
        );

        expect(info.message, 'Mapped error.');
        expect(info.code, 'mapped_error');
      });
    });

    group('configuration', () {
      test('can be configured once', () {
        expect(
          () => ProviderKit.configure(),
          returnsNormally,
        );
      });

      test('throws StateError when configured more than once', () {
        ProviderKit.configure();

        expect(
          () => ProviderKit.configure(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'ProviderKit has already been configured.',
            ),
          ),
        );
      });
    });

    group('resetForTesting', () {
      test('resets configuration state', () {
        ProviderKit.configure();

        ProviderKit.resetForTesting();

        expect(
          () => ProviderKit.configure(),
          returnsNormally,
        );
      });

      test('restores the default error mapper', () {
        ProviderKit.configure(
          errorInfoMapper: (error, stackTrace) {
            return const ErrorInfo(
              message: 'Custom error.',
              code: 'custom_error',
            );
          },
        );

        ProviderKit.resetForTesting();

        final error = Exception('Original error');

        final info = ProviderKit.resolveErrorInfo(
          error,
          StackTrace.current,
        );

        expect(info.message, error.toString());
        expect(info.code, isNull);
      });
    });
  });
}