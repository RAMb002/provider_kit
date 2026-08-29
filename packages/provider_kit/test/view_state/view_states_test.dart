import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('ViewState', () {
    // -------------------------------------------------------------------------
    // 1. Value Equality & HashCode Tests
    // -------------------------------------------------------------------------
    group('Equality & HashCode', () {
      test('InitialState equality', () {
        const state1 = InitialState<String>();
        const state2 = InitialState<String>();

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('LoadingState equality', () {
        const state1 = LoadingState<String>('Loading...', 0.5);
        const state2 = LoadingState<String>('Loading...', 0.5);
        const state3 = LoadingState<String>('Loading...', 0.8);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('EmptyState equality', () {
        const state1 = EmptyState<String>('No data');
        const state2 = EmptyState<String>('No data');
        const state3 = EmptyState<String>('Different message');

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('DataState equality', () {
        const state1 = DataState<String>('Hello');
        const state2 = DataState<String>('Hello');
        const state3 = DataState<String>('World');

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1, isNot(equals(state3)));
      });

      test('ErrorState equality', () {
        void retryCallback() {}
        final error = Exception('Failed');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'Error',
          code: 'failed',
        );

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

      test('different state types are not equal even with same inner value',
          () {
        const state1 = EmptyState<String>('test');
        const state2 = DataState<String>('test');

        expect(state1, isNot(equals(state2)));
      });
    });

    // -------------------------------------------------------------------------
    // 2. when() Pattern Matching
    // -------------------------------------------------------------------------
    group('when()', () {
      test('executes correct branch for InitialState', () {
        const ViewState<String> state = InitialState();
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (_) => 'data',
          emptyState: (_) => 'empty',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'initial');
      });

      test('executes correct branch and passes parameters for LoadingState',
          () {
        const ViewState<String> state = LoadingState('Fetching', 0.4);
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (msg, prog) => '$msg: $prog',
          dataState: (_) => 'data',
          emptyState: (_) => 'empty',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'Fetching: 0.4');
      });

      test('executes correct branch and passes parameters for DataState', () {
        const ViewState<String> state = DataState('Payload');
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (data) => data,
          emptyState: (_) => 'empty',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'Payload');
      });

      test('executes correct branch and passes parameters for EmptyState', () {
        const ViewState<String> state = EmptyState('Nothing here');
        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (_) => 'data',
          emptyState: (msg) => msg ?? '',
          errorState: (_, __, ___, ____) => 'error',
        );
        expect(result, 'Nothing here');
      });

      test('executes correct branch and passes all parameters for ErrorState',
          () {
        void dummyRetry() {}
        final error = Exception('Custom error');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'Failed',
          code: 'custom_error',
        );

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
          emptyState: (_) => 'empty',
          errorState: (errorInfo, error, stackTrace, onRetry) {
            expect(errorInfo, same(errorInfo));
            expect(error, same(error));
            expect(stackTrace, same(stackTrace));
            expect(onRetry, same(dummyRetry));

            return 'error_matched';
          },
        );
        expect(result, 'error_matched');
      });
    });

    // -------------------------------------------------------------------------
    // 3. map() Pattern Matching
    // -------------------------------------------------------------------------
    group('map()', () {
      test('maps each state to the corresponding callback', () {
        const ViewState<String> s1 = InitialState();
        const ViewState<String> s2 = LoadingState('loading');
        const ViewState<String> s3 = DataState('data');
        const ViewState<String> s4 = EmptyState('empty');
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'error',
          code: 'failure',
        );

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
        const ViewState<String> state = DataState('Success');
        final result = state.maybeWhen(
          orElse: () => 'fallback',
          dataState: (data) => 'matched: $data',
        );
        expect(result, 'matched: Success');
      });

      test('executes the provided callback for each state', () {
        const ViewState<String> initialState = InitialState();
        const ViewState<String> loadingState = LoadingState(
          'Loading',
          0.5,
        );
        const ViewState<String> emptyState = EmptyState('No data');

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
            emptyState: (message) => message ?? '',
          ),
          'No data',
        );
      });

      test('passes correct message and onRetry parameters for ErrorState', () {
        void dummyRetry() {}
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'Fail',
          code: 'failure',
        );

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
        const ViewState<String> state = InitialState();
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

        final result = state.maybeWhen(
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');
      });
    });

    // -------------------------------------------------------------------------
    // 5. whenOrNull() Matching & Null Behavior
    // -------------------------------------------------------------------------
    group('whenOrNull()', () {
      test('executes the matching callback and returns its result', () {
        const ViewState<String> state = DataState('Payload');

        final result = state.whenOrNull(
          dataState: (data) => 'matched: $data',
        );

        expect(result, 'matched: Payload');
      });

      test('passes the correct parameters for ErrorState', () {
        void dummyRetry() {}
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'Failed',
          code: 'failure',
        );

        final ViewState<String> state = ErrorState(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: dummyRetry,
        );

        final result = state.whenOrNull(
          errorState: (receivedErrorInfo, receivedError, receivedStackTrace,
              receivedOnRetry) {
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
        const ViewState<String> state = LoadingState('Loading');

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
        const ViewState<String> state = LoadingState();
        final result = state.maybeMap(
          orElse: () => 'fallback',
          loadingState: (s) => 'loading',
        );
        expect(result, 'loading');
      });

      test('falls back to orElse when state callback is null', () {
        const ViewState<String> state = EmptyState();
        final result = state.maybeMap(
          orElse: () => 'fallback',
          dataState: (_) => 'data',
        );
        expect(result, 'fallback');
      });
      test('executes initialState callback when provided', () {
        const ViewState<String> state = InitialState();

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

        final result = state.maybeMap(
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');
      });

      test('passes the complete state object to the matching callback', () {
        const ViewState<String> state = DataState('Payload');

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
        const ViewState<String> state = DataState('Payload');

        final result = state.mapOrNull(
          dataState: (state) => 'matched: ${state.data}',
        );

        expect(result, 'matched: Payload');
      });

      test('passes the complete ErrorState to the matching callback', () {
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
          message: 'Failed',
          code: 'failure',
        );

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
        const ViewState<String> state = EmptyState('No data');

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
        const ViewState<String> state = InitialState();

        expect(state.isInitial, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('LoadingState has the correct flags', () {
        const ViewState<String> state = LoadingState();

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isTrue);
        expect(state.isData, isFalse);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('DataState has the correct flags', () {
        const ViewState<String> state = DataState('data');

        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isData, isTrue);
        expect(state.isEmpty, isFalse);
        expect(state.isError, isFalse);
      });

      test('EmptyState has the correct flags', () {
        const ViewState<String> state = EmptyState();

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
        const state = LoadingState<String>('Loading...', 0.5);

        expect(
          state.toString(),
          'LoadingState { message: Loading..., progress: 0.5 }',
        );
      });

      test('EmptyState', () {
        const state = EmptyState<String>('No data');

        expect(
          state.toString(),
          'EmptyState { message: No data }',
        );
      });

      test('DataState', () {
        const state = DataState<String>('Hello');

        expect(
          state.toString(),
          'DataState { data: Hello }',
        );
      });

      test('ErrorState', () {
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        const errorInfo = ErrorInfo(
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
  });
}
