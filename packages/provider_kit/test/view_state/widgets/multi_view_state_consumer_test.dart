import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

Widget _withDefaultProvider(Widget child) {
  return ViewStateWidgetsProvider(
    initialStateBuilder: (_) => const SizedBox(key: _defaultInitialKey),
    loadingStateBuilder: (_, __, ___) =>
        const SizedBox(key: _defaultLoadingKey),
    emptyStateBuilder: (_, __) => const SizedBox(key: _defaultEmptyKey),
    errorStateBuilder: (_, __, ___, ____, _____) =>
        const SizedBox(key: _defaultErrorKey),
    child: child,
  );
}

void main() {
  group('MultiViewStateConsumer', () {
    Widget buildConsumer<T>({
      required MultiStateProviders<T> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<T>? dataStateListener,
      RebuildWhen<T>? rebuildWhen,
      ListenWhen<T>? listenWhen,
      bool callListenerOnInit = false,
      bool isSliver = false,
      bool withDefaultProvider = true,
    }) {
      final consumer = MultiViewStateConsumer(
        providers: providers,
        initialBuilder: initialBuilder,
        loadingBuilder: loadingBuilder,
        emptyBuilder: emptyBuilder,
        errorBuilder: errorBuilder,
        dataBuilder: dataBuilder,
        initialStateListener: initialStateListener,
        loadingStateListener: loadingStateListener,
        emptyStateListener: emptyStateListener,
        errorStateListener: errorStateListener,
        dataStateListener: dataStateListener,
        rebuildWhen: rebuildWhen,
        listenWhen: listenWhen,
        callListenerOnInit: callListenerOnInit,
        isSliver: isSliver,
      );

      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: consumer,
      );

      if (withDefaultProvider) {
        widget = _withDefaultProvider(widget);
      }

      return widget;
    }

    // -----------------------------------------------------------------------
    // 1. Basic Rendering
    // -----------------------------------------------------------------------

    testWidgets('renders builder output', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      bool built = false;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          dataBuilder: (state) {
            built = true;

            expect(state.value.data, 'data');

            return const SizedBox();
          },
        ),
      );

      expect(built, isTrue);
    });

    // -----------------------------------------------------------------------
    // 2. Priority Logic
    // -----------------------------------------------------------------------

    testWidgets('priority chain: Error > Initial > Loading > Empty > Data', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      int errorBuilt = 0;
      int initialBuilt = 0;
      int loadingBuilt = 0;
      int emptyBuilt = 0;
      int dataBuilt = 0;

      int errorListenerCalls = 0;
      int initialListenerCalls = 0;
      int loadingListenerCalls = 0;
      int emptyListenerCalls = 0;
      int dataListenerCalls = 0;

      ({ViewState<String> first, ViewState<String> second})? latestData;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (_, __, ___, ____, _____) {
            errorBuilt++;
            return const SizedBox();
          },
          initialBuilder: (_) {
            initialBuilt++;
            return const SizedBox();
          },
          loadingBuilder: (_, __, ___) {
            loadingBuilt++;
            return const SizedBox();
          },
          emptyBuilder: (_, __) {
            emptyBuilt++;
            return const SizedBox();
          },
          dataBuilder: (state) {
            dataBuilt++;

            // DataState.data is intentionally used without any casts.
            latestData = state;
            expect(state.first.data, isA<String>());
            expect(state.second.data, isA<String>());

            return const SizedBox();
          },
          errorStateListener: (_, __, ___, ____) {
            errorListenerCalls++;
          },
          initialStateListener: () {
            initialListenerCalls++;
          },
          loadingStateListener: (_, __) {
            loadingListenerCalls++;
          },
          emptyStateListener: (_) {
            emptyListenerCalls++;
          },
          dataStateListener: (state) {
            dataListenerCalls++;

            // This must only execute when every provider is DataState.
            expect(state.first.data, isA<String>());
            expect(state.second.data, isA<String>());
          },
        ),
      );

      // Data + Data.
      expect(dataBuilt, 1);
      expect(dataListenerCalls, 0);
      expect(latestData!.first.data, 'data1');
      expect(latestData!.second.data, 'data2');

      // Data + Data -> Empty + Data.
      provider1.emit(const EmptyState('empty'));
      await tester.pump();

      expect(emptyBuilt, 1);
      expect(emptyListenerCalls, 1);
      expect(dataListenerCalls, 0);

      // Empty + Data -> Loading + Data.
      provider1.emit(const LoadingState('load'));
      await tester.pump();

      expect(loadingBuilt, 1);
      expect(emptyBuilt, 1);
      expect(loadingListenerCalls, 1);
      expect(emptyListenerCalls, 1);

      // Loading + Data -> Initial + Data.
      provider1.emit(const InitialState());
      await tester.pump();

      expect(initialBuilt, 1);
      expect(loadingBuilt, 1);
      expect(initialListenerCalls, 1);
      expect(loadingListenerCalls, 1);
      expect(emptyListenerCalls, 1);

      // Initial + Data -> Error + Data.
      provider1.emit(
        ErrorState<String>(StateError('Error'), StackTrace.current),
      );
      await tester.pump();

      expect(errorBuilt, 1);
      expect(initialBuilt, 1);
      expect(errorListenerCalls, 1);
      expect(initialListenerCalls, 1);
      expect(loadingListenerCalls, 1);
      expect(emptyListenerCalls, 1);
      expect(dataListenerCalls, 0);

      // Error + Data -> Data + Data.
      provider1.emit(const DataState('data1-new'));
      await tester.pump();

      expect(dataBuilt, 2);
      expect(errorBuilt, 1);
      expect(latestData!.first.data, 'data1-new');
      expect(latestData!.second.data, 'data2');
      expect(dataListenerCalls, 1);
    });

    testWidgets('higher priority state wins across different providers', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));

      String? currentState;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (_, __, ___, ____, _____) {
            currentState = 'error';
            return const SizedBox();
          },
          initialBuilder: (_) {
            currentState = 'initial';
            return const SizedBox();
          },
          loadingBuilder: (_, __, ___) {
            currentState = 'loading';
            return const SizedBox();
          },
          emptyBuilder: (_, __) {
            currentState = 'empty';
            return const SizedBox();
          },
          dataBuilder: (state) {
            // This callback must only be reached for all-DataState input.
            currentState = '${state.first.data}:${state.second.data}';
            return const SizedBox();
          },
        ),
      );

      expect(currentState, 'one:two');

      // Data + Loading -> Loading.
      provider2.emit(const LoadingState('loading'));
      await tester.pump();
      expect(currentState, 'loading');

      // Initial + Loading -> Initial.
      provider1.emit(const InitialState());
      await tester.pump();
      expect(currentState, 'initial');

      // Initial + Error -> Error.
      provider2.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );
      await tester.pump();
      expect(currentState, 'error');

      // Empty + Error -> Error.
      provider1.emit(const EmptyState('empty'));
      await tester.pump();
      expect(currentState, 'error');

      // Empty + Data -> Empty.
      provider2.emit(const DataState('two-new'));
      await tester.pump();
      expect(currentState, 'empty');

      // Data + Data -> Data.
      provider1.emit(const DataState('one-new'));
      await tester.pump();
      expect(currentState, 'one-new:two-new');
    });

    testWidgets(
      'dataBuilder and dataStateListener run only when every provider is DataState',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));

        int dataBuilderCalls = 0;
        int dataListenerCalls = 0;

        String? builderFirst;
        String? builderSecond;
        String? listenerFirst;
        String? listenerSecond;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (first: provider1.watch, second: provider2.watch),
            initialBuilder: (_) => const SizedBox(),
            loadingBuilder: (_, __, ___) => const SizedBox(),
            emptyBuilder: (_, __) => const SizedBox(),
            errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            dataBuilder: (state) {
              dataBuilderCalls++;
              builderFirst = state.first.data;
              builderSecond = state.second.data;

              return const SizedBox();
            },
            dataStateListener: (state) {
              dataListenerCalls++;

              listenerFirst = state.first.data;
              listenerSecond = state.second.data;
            },
          ),
        );

        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);
        expect(builderFirst, 'one');
        expect(builderSecond, 'two');

        // Data + Loading -> no data builder/listener.
        provider2.emit(const LoadingState('loading'));
        await tester.pump();

        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);

        // Data + Initial -> no data builder/listener.
        provider2.emit(const InitialState());
        await tester.pump();

        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);

        // Data + Empty -> no data builder/listener.
        provider2.emit(const EmptyState('empty'));
        await tester.pump();

        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);

        // Data + Error -> no data builder/listener.
        provider2.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);

        // Return to Data + Data.
        provider2.emit(const DataState('two-new'));
        await tester.pump();

        expect(dataBuilderCalls, 2);
        expect(dataListenerCalls, 1);
        expect(builderFirst, 'one');
        expect(builderSecond, 'two-new');
        expect(listenerFirst, 'one');
        expect(listenerSecond, 'two-new');

        // Change one DataState again. Both callbacks should receive the new
        // combined data values.
        provider1.emit(const DataState('one-new'));
        await tester.pump();

        expect(dataBuilderCalls, 3);
        expect(dataListenerCalls, 2);
        expect(builderFirst, 'one-new');
        expect(builderSecond, 'two-new');
        expect(listenerFirst, 'one-new');
        expect(listenerSecond, 'two-new');
      },
    );

    // -----------------------------------------------------------------------
    // 3. Builder Parameters
    // -----------------------------------------------------------------------

    testWidgets('errorBuilder receives correct parameters', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('dummy'));

      final error = StateError('Error');
      final stackTrace = StackTrace.current;

      final provider2 = TestViewStateNotifier<String>(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: const ErrorInfo(message: 'Error'),
        ),
      );

      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
            capturedErrorInfo = errorInfo;
            capturedOnRetry = onRetry;
            capturedError = error;
            capturedStackTrace = stackTrace;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedErrorInfo, isNotNull);
      expect(capturedErrorInfo!.message, 'Error');
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
      expect(capturedOnRetry, isNull);
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('loadingBuilder receives message and combined progress', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState('Load A', 0.3),
      );

      final provider2 = TestViewStateNotifier<String>(
        const LoadingState('Load B', 0.7),
      );

      String? capturedMessage;
      double? capturedProgress;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          loadingBuilder: (message, progress, isSliver) {
            capturedMessage = message;
            capturedProgress = progress;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.5);
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('emptyBuilder receives message', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const EmptyState('Empty A'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const EmptyState('Empty B'),
      );

      String? capturedMessage;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          emptyBuilder: (message, isSliver) {
            capturedMessage = message;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedMessage, 'Empty A');
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('dataBuilder receives the exact combined value', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));

      String? capturedFirst;
      String? capturedSecond;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (state) {
            capturedFirst = state.first.data;
            capturedSecond = state.second.data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedFirst, 'one');
      expect(capturedSecond, 'two');

      provider1.emit(const DataState('one-new'));
      await tester.pump();

      expect(capturedFirst, 'one-new');
      expect(capturedSecond, 'two');
    });

    // -----------------------------------------------------------------------
    // 4. Listener Parameters
    // -----------------------------------------------------------------------

    testWidgets('errorStateListener receives correct parameters', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('dummy'));

      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider1.watch),
          errorStateListener: (errorInfo, error, stackTrace, onRetry) {
            capturedErrorInfo = errorInfo;
            capturedOnRetry = onRetry;
            capturedError = error;
            capturedStackTrace = stackTrace;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider1.emit(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: const ErrorInfo(message: 'Test error'),
        ),
      );

      await tester.pump();

      expect(capturedErrorInfo, isNotNull);
      expect(capturedErrorInfo!.message, 'Test error');
      expect(capturedOnRetry, isNull);
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
    });

    testWidgets('loadingStateListener receives message and combined progress', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));

      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          loadingStateListener: (message, progress) {
            capturedMessage = message;
            capturedProgress = progress;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider1.emit(const LoadingState('Load A', 0.3));
      await tester.pump();

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.3);

      capturedMessage = null;
      capturedProgress = null;

      provider2.emit(const LoadingState('Load B', 0.7));
      await tester.pump();

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.5);

      capturedMessage = null;
      capturedProgress = null;

      provider1.emit(const LoadingState('Load A', 0.5));
      await tester.pump();

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.6);
    });

    testWidgets('emptyStateListener receives message from first EmptyState', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));

      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          emptyStateListener: (message) {
            capturedMessage = message;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider1.emit(const EmptyState('Empty A'));
      await tester.pump();

      expect(capturedMessage, 'Empty A');

      capturedMessage = null;

      provider2.emit(const EmptyState('Empty B'));
      await tester.pump();

      expect(capturedMessage, 'Empty A');
    });

    testWidgets('dataStateListener receives the exact combined value', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));

      final provider2 = TestViewStateNotifier<String>(const DataState('two'));

      String? capturedFirst;
      String? capturedSecond;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataStateListener: (state) {
            capturedFirst = state.first.data;
            capturedSecond = state.second.data;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      // The initial DataState must not invoke the listener by default.
      expect(capturedFirst, isNull);
      expect(capturedSecond, isNull);

      provider2.emit(const DataState('two-new'));
      await tester.pump();

      expect(capturedFirst, 'one');
      expect(capturedSecond, 'two-new');
    });

    // -----------------------------------------------------------------------
    // 5. Retry Handling
    // -----------------------------------------------------------------------

    testWidgets('does not provide onRetry when no provider is in ErrorState', (
      tester,
    ) async {
      final provider1 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data1',
      );

      final provider2 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data2',
      );

      await tester.pumpAndSettle();

      VoidCallback? capturedBuilderRetry;
      VoidCallback? capturedListenerRetry;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (_, ___, __, onRetry, ____) {
            capturedBuilderRetry = onRetry;
            return const SizedBox();
          },
          errorStateListener: (_, ___, __, onRetry) {
            capturedListenerRetry = onRetry;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedBuilderRetry, isNull);
      expect(capturedListenerRetry, isNull);

      expect(provider1.refreshCalls, 0);
      expect(provider2.refreshCalls, 0);
    });

    testWidgets('builder onRetry refreshes providers in ErrorState', (
      tester,
    ) async {
      final provider = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data',
      );

      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          errorBuilder: (_, ___, __, onRetry, ____) {
            capturedOnRetry = onRetry;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.state = ErrorState<String>(
        StateError('Error'),
        StackTrace.current,
      );

      await tester.pump();

      expect(capturedOnRetry, isA<VoidCallback>());

      capturedOnRetry!();

      expect(provider.refreshCalls, 1);
    });

    testWidgets('listener onRetry refreshes providers in ErrorState', (
      tester,
    ) async {
      final provider = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data',
      );

      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          errorStateListener: (_, ___, __, onRetry) {
            capturedOnRetry = onRetry;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider.state = ErrorState<String>(
        StateError('Error'),
        StackTrace.current,
      );

      await tester.pump();

      expect(capturedOnRetry, isA<VoidCallback>());

      capturedOnRetry!();

      expect(provider.refreshCalls, 1);
    });

    testWidgets(
      'onRetry prefers explicit ErrorState callback over provider refresh',
      (tester) async {
        var retryCalls = 0;

        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        VoidCallback? capturedBuilderRetry;
        VoidCallback? capturedListenerRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (value: provider.watch),
            errorBuilder: (_, ___, __, onRetry, ____) {
              capturedBuilderRetry = onRetry;
              return const SizedBox();
            },
            errorStateListener: (_, ___, __, onRetry) {
              capturedListenerRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.state = ErrorState<String>(
          StateError('Error'),
          StackTrace.current,
          onRetry: () => retryCalls++,
        );

        await tester.pump();

        expect(capturedBuilderRetry, isA<VoidCallback>());
        expect(capturedListenerRetry, isA<VoidCallback>());

        capturedBuilderRetry!();

        expect(retryCalls, 1);
        expect(provider.refreshCalls, 0);

        capturedListenerRetry!();

        expect(retryCalls, 2);
        expect(provider.refreshCalls, 0);
      },
    );

    testWidgets(
      'errorBuilder receives null onRetry when error is not retryable',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const DataState('data'));

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (value: provider.watch),
            errorBuilder: (_, __, ___, onRetry, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );

        await tester.pump();

        expect(capturedOnRetry, isNull);
      },
    );

    testWidgets(
      'onRetry retries all retryable errored providers and skips non-retryable providers',
      (tester) async {
        int explicitRetryCalls = 0;

        final explicitRetryProvider = TestViewStateNotifier<String>(
          ErrorState<String>(
            StateError('explicit'),
            StackTrace.current,
            onRetry: () {
              explicitRetryCalls++;
            },
          ),
        );

        final asyncProvider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        asyncProvider.state = ErrorState<String>(
          StateError('async'),
          StackTrace.current,
        );

        final nonRetryableProvider = TestViewStateNotifier<String>(
          ErrorState<String>(StateError('non-retryable'), StackTrace.current),
        );

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (
              explicit: explicitRetryProvider.watch,
              async: asyncProvider.watch,
              nonRetryable: nonRetryableProvider.watch,
            ),
            errorBuilder: (_, __, ___, onRetry, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        expect(capturedOnRetry, isA<VoidCallback>());

        capturedOnRetry!();

        expect(explicitRetryCalls, 1);
        expect(asyncProvider.refreshCalls, 1);
      },
    );
    // -----------------------------------------------------------------------
    // 6. rebuildWhen / listenWhen
    // -----------------------------------------------------------------------

    testWidgets(
      'rebuildWhen controls builder and listenWhen controls listener independently',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const DataState('data'));

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (value: provider.watch),
            dataBuilder: (_) {
              buildCount++;
              return const SizedBox();
            },
            dataStateListener: (_) {
              listenerCount++;
            },
            rebuildWhen: (_, __) => false,
            listenWhen: (_, __) => true,
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);

        provider.emit(const DataState('new data'));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);
      },
    );

    // -----------------------------------------------------------------------
    // 7. callListenerOnInit
    // -----------------------------------------------------------------------

    testWidgets(
      'callListenerOnInit calls listener with combined initial state',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState('init1'),
        );

        final provider2 = TestViewStateNotifier<String>(
          const LoadingState('init load'),
        );

        bool dataCalled = false;
        bool loadingCalled = false;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => (first: provider1.watch, second: provider2.watch),
            dataBuilder: (_) => const SizedBox(),
            dataStateListener: (_) {
              dataCalled = true;
            },
            loadingStateListener: (_, __) {
              loadingCalled = true;
            },
            callListenerOnInit: true,
          ),
        );

        expect(loadingCalled, isTrue);
        expect(dataCalled, isFalse);
      },
    );

    testWidgets('callListenerOnInit false does not call listener on init', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('init1'));

      final provider2 = TestViewStateNotifier<String>(const DataState('init2'));

      bool dataCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) {
            dataCalled = true;
          },
          callListenerOnInit: false,
        ),
      );

      expect(dataCalled, isFalse);
    });

    // -----------------------------------------------------------------------
    // 8. Default ViewStateWidgetsProvider
    // -----------------------------------------------------------------------

    testWidgets('uses default initial widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const InitialState());

      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState('load'),
      );

      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const EmptyState('empty'),
      );

      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        ErrorState<String>(StateError('Error'), StackTrace.current),
      );

      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 9. isSliver
    // -----------------------------------------------------------------------

    testWidgets('passes isSliver to errorBuilder', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('dummy'));

      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          errorBuilder: (_, __, ___, ____, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      provider.emit(
        ErrorState<String>(StateError('Error'), StackTrace.current),
      );

      await tester.pump();

      expect(isSliverPassed, isTrue);
    });

    testWidgets('passes isSliver to loadingBuilder', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState('load'),
      );

      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          loadingBuilder: (_, __, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, isTrue);
    });

    testWidgets('passes isSliver to emptyBuilder', (tester) async {
      final provider = TestViewStateNotifier<String>(const EmptyState('empty'));

      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          emptyBuilder: (_, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, isTrue);
    });

    testWidgets('default widgets from provider receive isSliver', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState('load'),
      );

      bool? isSliverPassed;

      await tester.pumpWidget(
        ViewStateWidgetsProvider(
          initialStateBuilder: (_) => const SizedBox(),
          loadingStateBuilder: (_, __, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          emptyStateBuilder: (_, __) => const SizedBox(),
          errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MultiViewStateConsumer(
              providers: () => (value: provider.watch),
              isSliver: true,
              dataBuilder: (_) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(isSliverPassed, isTrue);
    });

    // -----------------------------------------------------------------------
    // 10. Runtime Dependency Replacement
    // -----------------------------------------------------------------------

    testWidgets(
      'switches to a new dependency when providers callback changes',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));

        var useProvider1 = true;

        String? capturedValue;

        Widget build() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MultiViewStateConsumer(
              providers: () =>
                  (value: (useProvider1 ? provider1 : provider2).watch),
              dataBuilder: (state) {
                // `.data` is safe here because this callback is only valid
                // when the selected dependency is in DataState.
                capturedValue = state.value.data;
                return const SizedBox();
              },
              dataStateListener: (state) {
                // Also verify the listener receives only DataState values.
                expect(state.value.data, isA<String>());
              },
            ),
          );
        }

        await tester.pumpWidget(build());

        expect(capturedValue, 'one');

        provider1.emit(const DataState('one-new'));
        await tester.pump();

        expect(capturedValue, 'one-new');

        useProvider1 = false;

        await tester.pumpWidget(build());

        expect(capturedValue, 'two');

        // provider1 is no longer a dependency.
        provider1.emit(const DataState('one-after-switch'));
        await tester.pump();

        expect(capturedValue, 'two');

        provider2.emit(const DataState('two-new'));
        await tester.pump();

        expect(capturedValue, 'two-new');
      },
    );

    testWidgets('parent rebuild with same providers rebuilds the consumer', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      int buildCount = 0;
      int listenerCount = 0;

      Widget buildFrame() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MultiViewStateConsumer(
            providers: () => (value: provider.watch),
            dataBuilder: (_) {
              buildCount++;
              return const SizedBox();
            },
            dataStateListener: (_) {
              listenerCount++;
            },
          ),
        );
      }

      await tester.pumpWidget(buildFrame());

      expect(buildCount, 1);
      expect(listenerCount, 0);

      await tester.pumpWidget(buildFrame());

      expect(buildCount, 2);
      expect(listenerCount, 0);

      provider.emit(const DataState('new data'));
      await tester.pump();

      expect(buildCount, 3);
      expect(listenerCount, 1);
    });

    // -----------------------------------------------------------------------
    // 11. Cleanup
    // -----------------------------------------------------------------------

    testWidgets('detaches listeners when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        buildConsumer(
          providers: () => (value: provider.watch),
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // -----------------------------------------------------------------------
    // 12. Diagnostics
    // -----------------------------------------------------------------------

    testWidgets('debugFillProperties includes all relevant properties', (
      tester,
    ) async {
      final diagnostics = DiagnosticPropertiesBuilder();

      final provider = TestViewStateNotifier<String>(const DataState('data'));

      MultiViewStateConsumer(
        providers: () => (value: provider.watch),
        initialBuilder: (_) => const SizedBox(),
        loadingBuilder: (_, __, ___) => const SizedBox(),
        emptyBuilder: (_, __) => const SizedBox(),
        errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
        dataBuilder: (_) => const SizedBox(),
        initialStateListener: () {},
        loadingStateListener: (_, __) {},
        emptyStateListener: (_) {},
        errorStateListener: (_, __, ___, ____) {},
        dataStateListener: (_) {},
        rebuildWhen: (_, __) => true,
        listenWhen: (_, __) => true,
        callListenerOnInit: true,
        isSliver: true,
      ).debugFillProperties(diagnostics);

      final description = diagnostics.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('providers')), isTrue);

      expect(description.any((value) => value.contains('rebuildWhen')), isTrue);

      expect(description.any((value) => value.contains('listenWhen')), isTrue);

      expect(
        description.any(
          (value) =>
              value.contains('callListenerOnInit') && value.contains('true'),
        ),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('initialBuilder')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('loadingBuilder')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('emptyBuilder')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('errorBuilder')),
        isTrue,
      );

      expect(description.any((value) => value.contains('dataBuilder')), isTrue);

      expect(
        description.any(
          (value) => value.contains('isSliver') && value.contains('true'),
        ),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('initialStateListener')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('loadingStateListener')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('emptyStateListener')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('errorStateListener')),
        isTrue,
      );

      expect(
        description.any((value) => value.contains('dataStateListener')),
        isTrue,
      );
    });
  });
}
