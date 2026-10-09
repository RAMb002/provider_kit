import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

void main() {
  group('MultiViewState aggregation', () {
    testWidgets('uses Error > Initial > Loading > Empty > Data priority', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );
      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );
      final provider3 = TestViewStateNotifier<String>(
        const DataState<String>('three'),
      );
      final provider4 = TestViewStateNotifier<String>(
        const DataState<String>('four'),
      );

      final builtStates = <String>[];
      final listenedStates = <String>[];

      int buildCount = 0;
      int listenerCount = 0;

      await tester.pumpWidget(
        _buildConsumer(
          providers: () => [
            provider1.watch,
            provider2.watch,
            provider3.watch,
            provider4.watch,
          ],
          onBuild: () => buildCount++,
          onListen: () => listenerCount++,
          onInitialBuilder: (_) {
            builtStates.add('initial');
            return const SizedBox();
          },
          onLoadingBuilder: (message, progress, _) {
            builtStates.add('loading:$message:$progress');
            return const SizedBox();
          },
          onEmptyBuilder: (message, _) {
            builtStates.add('empty:$message');
            return const SizedBox();
          },
          onErrorBuilder: (errorInfo, _, __, ___, ____) {
            builtStates.add('error:${errorInfo.message}');
            return const SizedBox();
          },
          onDataBuilder: (_) {
            builtStates.add('data');
            return const SizedBox();
          },
          onInitialListener: () {
            listenedStates.add('initial');
          },
          onLoadingListener: (message, progress) {
            listenedStates.add('loading:$message:$progress');
          },
          onEmptyListener: (message) {
            listenedStates.add('empty:$message');
          },
          onErrorListener: (errorInfo, _, __, ___) {
            listenedStates.add('error:${errorInfo.message}');
          },
          onDataListener: (_) {
            listenedStates.add('data');
          },
        ),
      );

      expect(buildCount, 1);
      expect(listenerCount, 0);
      expect(builtStates.last, 'data');
      expect(listenedStates, isEmpty);

      // Data + Data + Data + Empty -> Empty.
      provider1.emit(const EmptyState<String>('empty'));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);
      expect(builtStates.last, 'empty:empty');
      expect(listenedStates.last, 'empty:empty');

      // Data + Loading + Data + Empty -> Loading.
      provider2.emit(const LoadingState<String>('loading', 0.5));
      await tester.pump();

      expect(buildCount, 3);
      expect(listenerCount, 2);
      expect(builtStates.last, 'loading:loading:0.5');
      expect(listenedStates.last, 'loading:loading:0.5');

      // Data + Loading + Initial + Empty -> Initial.
      provider3.emit(const InitialState<String>());
      await tester.pump();

      expect(buildCount, 4);
      expect(listenerCount, 3);
      expect(builtStates.last, 'initial');
      expect(listenedStates.last, 'initial');

      // Data + Loading + Initial + Error -> Error.
      // Error is on the last watched provider, proving priority is not based
      // on provider position.
      provider4.emit(
        ErrorState<String>(
          StateError('error'),
          StackTrace.current,
          errorInfo: const ErrorInfo(message: 'error'),
        ),
      );
      await tester.pump();

      expect(buildCount, 5);
      expect(listenerCount, 4);
      expect(builtStates.last, 'error:error');
      expect(listenedStates.last, 'error:error');

      // Remove Error -> Initial still wins.
      provider4.emit(const DataState<String>('four'));
      await tester.pump();

      expect(buildCount, 6);
      expect(listenerCount, 5);
      expect(builtStates.last, 'initial');
      expect(listenedStates.last, 'initial');

      // Remove Initial -> Loading still wins.
      provider3.emit(const DataState<String>('three'));
      await tester.pump();

      expect(buildCount, 7);
      expect(listenerCount, 6);
      expect(builtStates.last, 'loading:loading:0.5');
      expect(listenedStates.last, 'loading:loading:0.5');

      // Remove Loading -> Empty still wins.
      provider2.emit(const DataState<String>('two'));
      await tester.pump();

      expect(buildCount, 8);
      expect(listenerCount, 7);
      expect(builtStates.last, 'empty:empty');
      expect(listenedStates.last, 'empty:empty');

      // Remove Empty -> Data.
      provider1.emit(const DataState<String>('one'));
      await tester.pump();

      expect(buildCount, 9);
      expect(listenerCount, 8);
      expect(builtStates.last, 'data');
      expect(listenedStates.last, 'data');
    });

    testWidgets(
      'uses the first Loading provider message and averages Loading progress',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('one'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const LoadingState<String>('Load B', 0.8),
        );
        final provider3 = TestViewStateNotifier<String>(
          const LoadingState<String>('Load C', 0.4),
        );
        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

        String? builtMessage;
        double? builtProgress;

        String? listenedMessage;
        double? listenedProgress;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [
              provider1.watch,
              provider2.watch,
              provider3.watch,
              provider4.watch,
            ],
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onLoadingBuilder: (message, progress, _) {
              builtMessage = message;
              builtProgress = progress;
              return const SizedBox();
            },
            onLoadingListener: (message, progress) {
              listenedMessage = message;
              listenedProgress = progress;
            },
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);
        expect(builtMessage, 'Load B');
        expect(builtProgress, closeTo(0.6, 0.000001));

        // provider2 remains the first Loading provider.
        // provider3 changes the aggregate progress from 0.6 to 0.7.
        provider3.emit(const LoadingState<String>('Load C changed', 0.6));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);
        expect(builtMessage, 'Load B');
        expect(builtProgress, closeTo(0.7, 0.000001));
        expect(listenedMessage, 'Load B');
        expect(listenedProgress, closeTo(0.7, 0.000001));

        // The previous first Loading provider becomes Data.
        // provider3 becomes the first Loading provider.
        provider2.emit(const DataState<String>('two'));
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);
        expect(builtMessage, 'Load C changed');
        expect(builtProgress, closeTo(0.6, 0.000001));
        expect(listenedMessage, 'Load C changed');
        expect(listenedProgress, closeTo(0.6, 0.000001));
      },
    );

    testWidgets(
      'uses the first Empty provider message and updates when the first Empty provider is removed',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('one'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const EmptyState<String>('Empty A'),
        );
        final provider3 = TestViewStateNotifier<String>(
          const EmptyState<String>('Empty B'),
        );
        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

        String? builtMessage;
        String? listenedMessage;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [
              provider1.watch,
              provider2.watch,
              provider3.watch,
              provider4.watch,
            ],
            callListenerOnInit: true,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onEmptyBuilder: (message, _) {
              builtMessage = message;
              return const SizedBox();
            },
            onEmptyListener: (message) {
              listenedMessage = message;
            },
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);
        expect(builtMessage, 'Empty A');
        expect(listenedMessage, 'Empty A');

        // The first Empty provider becomes Data.
        // provider3 becomes the first Empty provider.
        provider2.emit(const DataState<String>('two'));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 2);
        expect(builtMessage, 'Empty B');
        expect(listenedMessage, 'Empty B');
      },
    );

    testWidgets(
      'uses the first Error provider details and retries every retryable Error provider',
      (tester) async {
        final firstError = StateError('first');
        final firstStackTrace = StackTrace.current;

        final secondError = StateError('second');
        final secondStackTrace = StackTrace.current;

        int firstRetryCalls = 0;
        int secondRetryCalls = 0;

        final provider1 = TestViewStateNotifier<String>(
          ErrorState<String>(
            firstError,
            firstStackTrace,
            errorInfo: const ErrorInfo(message: 'First error'),
            onRetry: () => firstRetryCalls++,
          ),
        );

        final provider2 = TestViewStateNotifier<String>(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: const ErrorInfo(message: 'Second error'),
            onRetry: () => secondRetryCalls++,
          ),
        );

        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );

        final provider4 = TestViewStateNotifier<String>(
          const EmptyState<String>('empty'),
        );

        ErrorInfo? builtErrorInfo;
        Object? builtError;
        StackTrace? builtStackTrace;
        VoidCallback? builtOnRetry;

        ErrorInfo? listenedErrorInfo;
        Object? listenedError;
        StackTrace? listenedStackTrace;
        VoidCallback? listenedOnRetry;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [
              provider1.watch,
              provider2.watch,
              provider3.watch,
              provider4.watch,
            ],
            callListenerOnInit: true,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onErrorBuilder: (errorInfo, error, stackTrace, onRetry, __) {
              builtErrorInfo = errorInfo;
              builtError = error;
              builtStackTrace = stackTrace;
              builtOnRetry = onRetry;
              return const SizedBox();
            },
            onErrorListener: (errorInfo, error, stackTrace, onRetry) {
              listenedErrorInfo = errorInfo;
              listenedError = error;
              listenedStackTrace = stackTrace;
              listenedOnRetry = onRetry;
            },
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);

        expect(builtErrorInfo!.message, 'First error');
        expect(builtError, same(firstError));
        expect(builtStackTrace, same(firstStackTrace));
        expect(builtOnRetry, isNotNull);

        expect(listenedErrorInfo!.message, 'First error');
        expect(listenedError, same(firstError));
        expect(listenedStackTrace, same(firstStackTrace));
        expect(listenedOnRetry, isNotNull);

        builtOnRetry!();

        expect(firstRetryCalls, 1);
        expect(secondRetryCalls, 1);

        listenedOnRetry!();

        expect(firstRetryCalls, 2);
        expect(secondRetryCalls, 2);
      },
    );

    testWidgets(
      'averages available Loading progress and returns null when no progress is available',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('one'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('two'),
        );
        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );
        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

        double? builtProgress;
        double? listenedProgress;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [
              provider1.watch,
              provider2.watch,
              provider3.watch,
              provider4.watch,
            ],
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onLoadingBuilder: (_, progress, __) {
              builtProgress = progress;
              return const SizedBox();
            },
            onLoadingListener: (_, progress) {
              listenedProgress = progress;
            },
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);

        provider1.emit(const LoadingState<String>('A', 0.2));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);
        expect(builtProgress, closeTo(0.2, 0.000001));
        expect(listenedProgress, closeTo(0.2, 0.000001));

        provider3.emit(const LoadingState<String>('C', 0.8));
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);
        expect(builtProgress, closeTo(0.5, 0.000001));
        expect(listenedProgress, closeTo(0.5, 0.000001));

        // A Loading provider without progress does not affect the aggregate.
        provider2.emit(const LoadingState<String>('B'));
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);

        // Removing the only progress value leaves provider3 as the
        // only Loading provider with available progress.
        provider1.emit(const LoadingState<String>('A'));
        await tester.pump();

        expect(buildCount, 4);
        expect(listenerCount, 3);
        expect(builtProgress, closeTo(0.8, 0.000001));
        expect(listenedProgress, closeTo(0.8, 0.000001));

        // No Loading provider has a progress value.
        provider3.emit(const LoadingState<String>('C'));
        await tester.pump();

        expect(buildCount, 5);
        expect(listenerCount, 4);
        expect(builtProgress, isNull);
        expect(listenedProgress, isNull);
      },
    );
    testWidgets(
      'passes the combined provider value unchanged to the data builder and listener',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('first'),
        );

        final provider2 = TestViewStateNotifier<int>(const DataState<int>(42));

        ({ViewState<String> first, ViewState<int> second})? builtState;
        ({ViewState<String> first, ViewState<int> second})? listenedState;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer<({ViewState<String> first, ViewState<int> second})>(
            providers: () => (first: provider1.watch, second: provider2.watch),
            callListenerOnInit: true,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onDataBuilder: (state) {
              builtState = state;
              return const SizedBox();
            },
            onDataListener: (state) {
              listenedState = state;
            },
          ),
        );

        await tester.pump();

        const expected = (
          first: DataState<String>('first'),
          second: DataState<int>(42),
        );

        expect(buildCount, 1);
        expect(listenerCount, 1);

        expect(builtState, expected);
        expect(listenedState, expected);
      },
    );

    testWidgets(
      'uses AsyncViewStateNotifier refresh when an ErrorState has no retry callback',
      (tester) async {
        final asyncProvider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        asyncProvider.state = ErrorState<String>(
          StateError('async error'),
          StackTrace.current,
          errorInfo: const ErrorInfo(message: 'Async error'),
        );

        VoidCallback? builderRetry;
        VoidCallback? listenerRetry;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => asyncProvider.watch,
            callListenerOnInit: true,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onErrorBuilder: (_, __, ___, onRetry, ____) {
              builderRetry = onRetry;
              return const SizedBox();
            },
            onErrorListener: (_, __, ___, onRetry) {
              listenerRetry = onRetry;
            },
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);
        expect(builderRetry, isNotNull);
        expect(listenerRetry, isNotNull);

        // Builder retry.
        builderRetry!();

        expect(asyncProvider.refreshCalls, 1);

        // Refresh moves the provider out of ErrorState.
        await tester.pumpAndSettle();

        // Re-enter ErrorState so the listener retry can be exercised
        // independently.
        asyncProvider.state = ErrorState<String>(
          StateError('async error'),
          StackTrace.current,
          errorInfo: const ErrorInfo(message: 'Async error'),
        );

        await tester.pump();

        expect(listenerRetry, isNotNull);

        // Listener retry.
        listenerRetry!();

        expect(asyncProvider.refreshCalls, 2);
      },
    );
    testWidgets(
      'provides no retry callback when no watched Error provider is retryable',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          ErrorState<String>(
            StateError('error'),
            StackTrace.current,
            errorInfo: const ErrorInfo(message: 'Error'),
          ),
        );

        VoidCallback? builderRetry;
        VoidCallback? listenerRetry;

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => provider.watch,
            callListenerOnInit: true,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            onErrorBuilder: (_, __, ___, onRetry, _____) {
              builderRetry = onRetry;
              return const SizedBox();
            },
            onErrorListener: (_, __, ___, onRetry) {
              listenerRetry = onRetry;
            },
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);
        expect(builderRetry, isNull);
        expect(listenerRetry, isNull);
      },
    );
  });
}

Widget _buildConsumer<T>({
  required MultiStateProviders<T> providers,
  required VoidCallback onBuild,
  required VoidCallback onListen,
  InitialStateBuilder? onInitialBuilder,
  LoadingStateBuilder? onLoadingBuilder,
  EmptyStateBuilder? onEmptyBuilder,
  ErrorStateBuilder? onErrorBuilder,
  DataStateBuilder<T>? onDataBuilder,
  InitialStateListener? onInitialListener,
  LoadingStateListener? onLoadingListener,
  EmptyStateListener? onEmptyListener,
  ErrorStateListener? onErrorListener,
  DataStateListener<T>? onDataListener,
  bool callListenerOnInit = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: ViewStateConsumer<T>.multi(
      providers: providers,
      callListenerOnInit: callListenerOnInit,
      initialBuilder: (isSliver) {
        onBuild();
        return onInitialBuilder?.call(isSliver) ?? const SizedBox();
      },
      loadingBuilder: (message, progress, isSliver) {
        onBuild();
        return onLoadingBuilder?.call(message, progress, isSliver) ??
            const SizedBox();
      },
      emptyBuilder: (message, isSliver) {
        onBuild();
        return onEmptyBuilder?.call(message, isSliver) ?? const SizedBox();
      },
      errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
        onBuild();
        return onErrorBuilder?.call(
              errorInfo,
              error,
              stackTrace,
              onRetry,
              isSliver,
            ) ??
            const SizedBox();
      },
      dataBuilder: (state) {
        onBuild();
        return onDataBuilder?.call(state) ?? const SizedBox();
      },
      initialStateListener: () {
        onListen();
        onInitialListener?.call();
      },
      loadingStateListener: (message, progress) {
        onListen();
        onLoadingListener?.call(message, progress);
      },
      emptyStateListener: (message) {
        onListen();
        onEmptyListener?.call(message);
      },
      errorStateListener: (errorInfo, error, stackTrace, onRetry) {
        onListen();
        onErrorListener?.call(errorInfo, error, stackTrace, onRetry);
      },
      dataStateListener: (state) {
        onListen();
        onDataListener?.call(state);
      },
    ),
  );
}
