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
        final exception = Exception('Failed');
        final stackTrace = StackTrace.current;

        final state1 = ErrorState<String>(
          'Error',
          exception,
          stackTrace,
          retryCallback,
        );
        final state2 = ErrorState<String>(
          'Error',
          exception,
          stackTrace,
          retryCallback,
        );
        const state3 = ErrorState<String>('Error');

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
        final exception = Exception('Custom error');
        final stackTrace = StackTrace.current;

        final ViewState<String> state = ErrorState<String>(
          'Failed',
          exception,
          stackTrace,
          dummyRetry,
        );

        final result = state.when(
          initialState: () => 'initial',
          loadingState: (_, __) => 'loading',
          dataState: (_) => 'data',
          emptyState: (_) => 'empty',
          errorState: (msg, retry, exc, st) {
            expect(msg, 'Failed');
            expect(retry, dummyRetry);
            expect(exc, exception);
            expect(st, stackTrace);
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
      test('maps every state to strongly typed subclass instance', () {
        const ViewState<String> s1 = InitialState();
        const ViewState<String> s2 = LoadingState('loading');
        const ViewState<String> s3 = DataState('data');
        const ViewState<String> s4 = EmptyState('empty');
        const ViewState<String> s5 = ErrorState('error');

        String mapper(ViewState<String> state) {
          return state.map(
            initialState: (s) => 'initial',
            loadingState: (s) => s.message!,
            dataState: (s) => s.data,
            emptyState: (s) => s.message!,
            errorState: (s) => s.message!,
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

      test('passes correct message and onRetry parameters for ErrorState', () {
        void dummyRetry() {}
        final ViewState<String> state =
            ErrorState('Fail', null, null, dummyRetry);

        final result = state.maybeWhen(
          orElse: () => 'fallback',
          errorState: (msg, retry) {
            expect(msg, 'Fail');
            expect(retry, dummyRetry);
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
    });

    // -------------------------------------------------------------------------
    // 5. maybeMap() Fallback Behavior
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
    });
  });
}
