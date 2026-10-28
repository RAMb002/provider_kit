// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ViewState', () {
    // -------------------------------------------------------------------------
    // 1. Value Equality & HashCode Tests
    // -------------------------------------------------------------------------
    group('Equality & HashCode', () {
      test('InitialState equality', () {
        final state1 = InitialState<String>();
        final state2 = InitialState<String>();

        expect(identical(state1, state2), isFalse);
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('LoadingState equality', () {
        final state1 = LoadingState<String>('Loading...', 0.5);
        final state2 = LoadingState<String>('Loading...', 0.5);
        final state3 = LoadingState<String>('Loading...', 0.8);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('EmptyState equality', () {
        final state1 = EmptyState<String>('No data');
        final state2 = EmptyState<String>('No data');
        final state3 = EmptyState<String>('Different message');

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('DataState equality', () {
        final state1 = DataState<String>('Hello');
        final state2 = DataState<String>('Hello');
        final state3 = DataState<String>('World');

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('ErrorState equality', () {
        void retryCallback() {}
        final error = Exception('Failed');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(message: 'Error', code: 'failed');

        final state1 = ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: retryCallback,
        );
        final state2 = ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: retryCallback,
        );
        final state3 = ErrorState<String>(
          Exception('Other'),
          stackTrace,
          errorInfo: errorInfo,
          onRetry: retryCallback,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test(
        'different state types are not equal even with same inner value',
        () {
          final state1 = EmptyState<String>('test');
          final state2 = DataState<String>('test');

          expect(state1, isNot(equals(state2)));
        },
      );
    });

    test('different generic types are not equal', () {
      expect(InitialState<int>(), isNot(equals(InitialState<String>())));

      expect(
        LoadingState<int>('Loading'),
        isNot(equals(LoadingState<String>('Loading'))),
      );

      expect(
        EmptyState<int>('Empty'),
        isNot(equals(EmptyState<String>('Empty'))),
      );

      expect(
        DataState<Object>('Hello'),
        isNot(equals(DataState<String>('Hello'))),
      );

      final error = StateError('failure');
      final stackTrace = StackTrace.current;

      expect(
        ErrorState<int>(error, stackTrace),
        isNot(equals(ErrorState<String>(error, stackTrace))),
      );
    });

    // -------------------------------------------------------------------------
    // 2. when() Pattern Matching
    // -------------------------------------------------------------------------
    group('when()', () {
      test('executes correct branch for InitialState', () {
        final ViewState<String> state = InitialState();
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (_) => 'data',
          emptyState: (_, __) => 'empty',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'initial');
      });

      test(
        'executes correct branch and passes parameters for LoadingState',
        () {
          final ViewState<String> state = LoadingState('Fetching', 0.4);
          final result = state.when(
            initialState: () => 'initial',
            loadingState: (msg, prog) => '$msg: $prog',
            dataState: (_) => 'data',
            emptyState: (_, __) => 'empty',
            errorState: (_, __, ___, ____) => 'error',
          );
          expect(result, 'Fetching: 0.4');
        },
      );

      test('executes correct branch and passes parameters for DataState', () {
        final ViewState<String> state = DataState('Payload');
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (data) => data,
          emptyState: (_, __) => 'empty',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'Payload');
      });

      test(
        'executes correct branch and passes message and onRefresh for EmptyState',
        () {
          bool refreshed = false;

          void onRefresh() {
            refreshed = true;
          }

          final ViewState<String> state = EmptyState<String>(
            'Nothing here',
            onRefresh,
          );

          final result = state.when(
            initialState: () => 'initial',
            loadingState: (_, __) => 'loading',
            dataState: (_) => 'data',
            emptyState: (message, callback) {
              expect(message, 'Nothing here');
              expect(callback, same(onRefresh));

              callback?.call();

              return 'empty_matched';
            },
            errorState: (_, __, ___, ____) => 'error',
          );

          expect(result, 'empty_matched');
          expect(refreshed, isTrue);
        },
      );
      test(
        'executes correct branch and passes all parameters for ErrorState',
        () {
          void dummyRetry() {}
          final error = Exception('Custom error');
          final stackTrace = StackTrace.current;

          final errorInfo = ErrorInfo(message: 'Failed', code: 'custom_error');

          final ViewState<String> state = ErrorState<String>(
            error,
            stackTrace,
            errorInfo: errorInfo,
            onRetry: dummyRetry,
          );

          final result = state.when(
            initialState: () => 'initial',
            loadingState: (_, __) => 'loading',
            dataState: (_) => 'data',
            emptyState: (_, __) => 'empty',
            errorState: (errorInfo, error, stackTrace, onRetry) {
              expect(errorInfo, same(errorInfo));
              expect(error, same(error));
              expect(stackTrace, same(stackTrace));
              expect(onRetry, same(dummyRetry));

              return 'error_matched';
            },
          );
          expect(result, 'error_matched');
        },
      );
    });

    // -------------------------------------------------------------------------
    // 3. map() Pattern Matching
    // -------------------------------------------------------------------------
    group('map()', () {
      test('maps each state to the corresponding callback', () {
        final ViewState<String> s1 = InitialState();
        final ViewState<String> s2 = LoadingState('loading');
        final ViewState<String> s3 = DataState('data');
        final ViewState<String> s4 = EmptyState('empty');
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(message: 'error', code: 'failure');

        final ViewState<String> s5 = ErrorState(
          error,
          stackTrace,
          errorInfo: errorInfo,
        );

        String mapper(ViewState<String> state) {
          return state.map(
            initialState: (s) => 'initial',
            loadingState: (s) => s.message!,
            dataState: (s) => s.data,
            emptyState: (s) => s.message!,
            errorState: (s) => s.errorInfo.message,
          );
        }

        expect(mapper(s1), 'initial');
        expect(mapper(s2), 'loading');
        expect(mapper(s3), 'data');
        expect(mapper(s4), 'empty');
        expect(mapper(s5), 'error');
      });
    });

    // -------------------------------------------------------------------------
    // 4. maybeWhen() Fallback & Error Handling
    // -------------------------------------------------------------------------
    group('maybeWhen()', () {
      test('executes specific callback when provided', () {
        final ViewState<String> state = DataState('Success');
        final result = state.maybeWhen(
          orElse: () => 'fallback',
          dataState: (data) => 'matched: $data',
        );
        expect(result, 'matched: Success');
      });

      test(
        'uses orElse for LoadingState when loadingState callback is absent',
        () {
          final ViewState<String> state = LoadingState('Loading', 0.5);

          final result = state.maybeWhen(
            dataState: (_) => 'data',
            orElse: () => 'fallback',
          );

          expect(result, 'fallback');
        },
      );

      test('executes the provided callback for each state', () {
        final ViewState<String> initialState = InitialState();
        final ViewState<String> loadingState = LoadingState('Loading', 0.5);
        final ViewState<String> emptyState = EmptyState('No data');

        expect(
          initialState.maybeWhen(
            orElse: () => 'fallback',
            initialState: () => 'initial',
          ),
          'initial',
        );

        expect(
          loadingState.maybeWhen(
            orElse: () => 'fallback',
            loadingState: (message, progress) => '$message: $progress',
          ),
          'Loading: 0.5',
        );

        expect(
          emptyState.maybeWhen(
            orElse: () => 'fallback',
            emptyState: (message, __) => message ?? '',
          ),
          'No data',
        );
      });

      test('passes correct message and onRetry parameters for ErrorState', () {
        void dummyRetry() {}
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(message: 'Fail', code: 'failure');

        final ViewState<String> state = ErrorState(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: dummyRetry,
        );
        final result = state.maybeWhen(
          orElse: () => 'fallback',
          errorState: (errorInfo, error, stackTrace, onRetry) {
            expect(errorInfo, same(errorInfo));
            expect(error, same(error));
            expect(stackTrace, same(stackTrace));
            expect(onRetry, same(dummyRetry));
            return 'error_ok';
          },
        );
        expect(result, 'error_ok');
      });

      test('falls back to orElse when state callback is null', () {
        final ViewState<String> state = InitialState();
        final result = state.maybeWhen(
          orElse: () => 'fallback',
          dataState: (_) => 'data',
        );
        expect(result, 'fallback');
      });

      test(
        'falls back to orElse for ErrorState when errorState callback is absent',
        () {
          final ViewState<String> state = ErrorState<String>(
            StateError('error'),
            StackTrace.current,
          );

          final result = state.maybeWhen(orElse: () => 'fallback');

          expect(result, 'fallback');
        },
      );
    });

    // -------------------------------------------------------------------------
    // 5. whenOrNull() Matching & Null Behavior
    // -------------------------------------------------------------------------
    group('whenOrNull()', () {
      test('executes the matching callback and returns its result', () {
        final ViewState<String> state = DataState('Payload');

        final result = state.whenOrNull(dataState: (data) => 'matched: $data');

        expect(result, 'matched: Payload');
      });

      test('passes message and progress for LoadingState', () {
        final ViewState<String> state = LoadingState('Loading', 0.5);

        final result = state.whenOrNull(
          loadingState: (message, progress) => '$message: $progress',
        );

        expect(result, 'Loading: 0.5');
      });

      test('passes the correct parameters for ErrorState', () {
        void dummyRetry() {}
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(message: 'Failed', code: 'failure');

        final ViewState<String> state = ErrorState(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: dummyRetry,
        );

        final result = state.whenOrNull(
          errorState:
              (
                receivedErrorInfo,
                receivedError,
                receivedStackTrace,
                receivedOnRetry,
              ) {
                expect(receivedErrorInfo, same(errorInfo));
                expect(receivedError, same(error));
                expect(receivedStackTrace, same(stackTrace));
                expect(receivedOnRetry, same(dummyRetry));

                return 'error_matched';
              },
        );

        expect(result, 'error_matched');
      });

      test('returns null when no callback matches the current state', () {
        final ViewState<String> state = LoadingState('Loading');

        final result = state.whenOrNull(
          dataState: (_) => 'data',
          errorState: (_, __, ___, ____) => 'error',
        );

        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 6. maybeMap() Fallback Behavior
    // -------------------------------------------------------------------------
    group('maybeMap()', () {
      test('executes specific callback when provided', () {
        final ViewState<String> state = LoadingState();
        final result = state.maybeMap(
          orElse: () => 'fallback',
          loadingState: (s) => 'loading',
        );
        expect(result, 'loading');
      });

      test('falls back to orElse when state callback is null', () {
        final ViewState<String> state = EmptyState();
        final result = state.maybeMap(
          orElse: () => 'fallback',
          dataState: (_) => 'data',
        );
        expect(result, 'fallback');
      });
      test('executes initialState callback when provided', () {
        final ViewState<String> state = InitialState();

        final result = state.maybeMap(
          orElse: () => 'fallback',
          initialState: (state) => 'initial',
        );

        expect(result, 'initial');
      });

      test(
        'falls back to orElse for ErrorState when errorState mapper is absent',
        () {
          final ViewState<String> state = ErrorState<String>(
            StateError('error'),
            StackTrace.current,
          );

          final result = state.maybeMap(orElse: () => 'fallback');

          expect(result, 'fallback');
        },
      );

      test('passes the complete state object to the matching callback', () {
        final ViewState<String> state = DataState('Payload');

        final result = state.maybeMap(
          orElse: () => 'fallback',
          dataState: (dataState) => dataState.data,
        );

        expect(result, 'Payload');
      });
    });

    // -------------------------------------------------------------------------
    // 7. mapOrNull() Matching & Null Behavior
    // -------------------------------------------------------------------------
    group('mapOrNull()', () {
      test('executes the matching callback and returns its result', () {
        final ViewState<String> state = DataState('Payload');

        final result = state.mapOrNull(
          dataState: (state) => 'matched: ${state.data}',
        );

        expect(result, 'matched: Payload');
      });

      test('passes the complete ErrorState to the matching callback', () {
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(message: 'Failed', code: 'failure');

        final ViewState<String> state = ErrorState(
          error,
          stackTrace,
          errorInfo: errorInfo,
        );

        final result = state.mapOrNull(
          errorState: (errorState) {
            expect(errorState, same(state));
            expect(errorState.errorInfo, same(errorInfo));
            expect(errorState.error, same(error));
            expect(errorState.stackTrace, same(stackTrace));

            return errorState.errorInfo.message;
          },
        );

        expect(result, 'Failed');
      });

      test('returns null when no callback matches the current state', () {
        final ViewState<String> state = EmptyState('No data');

        final result = state.mapOrNull(
          dataState: (_) => 'data',
          errorState: (_) => 'error',
        );

        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 8. State Type Getters
    // -------------------------------------------------------------------------
    group('state type getters', () {
      test('InitialState has the correct flags', () {
        final ViewState<String> state = InitialState();

        expect(state.isInitial, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('LoadingState has the correct flags', () {
        final ViewState<String> state = LoadingState();

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isTrue);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('DataState has the correct flags', () {
        final ViewState<String> state = DataState('data');

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isData, isTrue);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('EmptyState has the correct flags', () {
        final ViewState<String> state = EmptyState();

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isTrue);
        expect(state.isError, isFalse);
      });

      test('ErrorState has the correct flags', () {
        final ViewState<String> state = ErrorState(
          StateError('failure'),
          StackTrace.current,
        );

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isTrue);
      });
    });
    group('toString()', () {
      test('LoadingState', () {
        final state = LoadingState<String>('Loading...', 0.5);

        expect(
          state.toString(),
          'LoadingState { message: Loading..., progress: 0.5 }',
        );
      });

      test('EmptyState', () {
        final state = EmptyState<String>('No data');

        expect(
          state.toString(),
          'EmptyState { message: No data, onRefresh: false }',
        );
      });

      test('DataState', () {
        final state = DataState<String>('Hello');

        expect(state.toString(), 'DataState { data: Hello }');
      });

      test('ErrorState', () {
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final errorInfo = ErrorInfo(
          message: 'Something went wrong',
          code: 'failure',
        );

        final state = ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
        );

        expect(
          state.toString(),
          'ErrorState { '
          'errorInfo: $errorInfo, '
          'error: $error, '
          'stackTrace: $stackTrace, '
          'onRetry: false'
          ' }',
        );
      });
    });

    // -------------------------------------------------------------------------
    // 9. Data Accessors
    // -------------------------------------------------------------------------
    group('data accessors', () {
      test('data returns the payload for DataState', () {
        final ViewState<String> state = DataState('Hello');

        expect(state.data, 'Hello');
      });

      test('dataOrNull returns the payload for DataState', () {
        final ViewState<String> state = DataState('Hello');

        expect(state.dataOrNull, 'Hello');
      });

      test('dataOrNull returns null for InitialState', () {
        final ViewState<String> state = InitialState();

        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull returns null for LoadingState', () {
        final ViewState<String> state = LoadingState('Loading');

        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull returns null for EmptyState', () {
        final ViewState<String> state = EmptyState('No data');

        expect(state.dataOrNull, isNull);
      });

      test('dataOrNull returns null for ErrorState', () {
        final ViewState<String> state = ErrorState<String>(
          StateError('failure'),
          StackTrace.current,
        );

        expect(state.dataOrNull, isNull);
      });

      test('data throws StateError for InitialState', () {
        final ViewState<String> state = InitialState();

        expect(
          () => state.data,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(
                'Data is only available when the current state is a DataState',
              ),
            ),
          ),
        );
      });

      test('data throws StateError for LoadingState', () {
        final ViewState<String> state = LoadingState('Loading');

        expect(
          () => state.data,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(
                'Data is only available when the current state is a DataState',
              ),
            ),
          ),
        );
      });

      test('data throws StateError for EmptyState', () {
        final ViewState<String> state = EmptyState('No data');

        expect(
          () => state.data,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(
                'Data is only available when the current state is a DataState',
              ),
            ),
          ),
        );
      });

      test('data throws StateError for ErrorState', () {
        final ViewState<String> state = ErrorState<String>(
          StateError('failure'),
          StackTrace.current,
        );

        expect(
          () => state.data,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(
                'Data is only available when the current state is a DataState',
              ),
            ),
          ),
        );
      });

      test('data and dataOrNull stay consistent for DataState', () {
        final ViewState<int> state = DataState(42);

        expect(state.dataOrNull, state.data);
        expect(state.data, 42);
        expect(state.dataOrNull, 42);
      });

      test('dataOrNull is safe to use without checking the state type', () {
        final List<ViewState<String>> states = [
          InitialState<String>(),
          LoadingState<String>('Loading'),
          EmptyState<String>('Empty'),
          DataState<String>('Data'),
        ];

        expect(states.map((state) => state.dataOrNull).toList(), [
          null,
          null,
          null,
          'Data',
        ]);
      });
    });
  });
}
