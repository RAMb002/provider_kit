import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

typedef TwoStates = ({ViewState<String> first, ViewState<String> second});

void main() {
  group('MultiViewStateListener', () {
    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    MultiStateProviders<ViewState<String>> singleProvider(
      ViewStateNotifier<String> provider,
    ) {
      return () => provider.watch;
    }

    MultiStateProviders<TwoStates> twoProviders(
      ViewStateNotifier<String> provider1,
      ViewStateNotifier<String> provider2,
    ) {
      return () => (first: provider1.watch, second: provider2.watch);
    }

    Widget buildListener({
      required MultiStateProviders<ViewState<String>> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<ViewState<String>>? dataStateListener,
      ListenWhen<ViewState<String>>? listenWhen,
      bool callListenerOnInit = false,
      Widget? child,
    }) {
      return wrap(
        MultiViewStateListener<ViewState<String>>(
          providers: providers,
          initialStateListener: initialStateListener,
          loadingStateListener: loadingStateListener,
          emptyStateListener: emptyStateListener,
          errorStateListener: errorStateListener,
          dataStateListener: dataStateListener,
          listenWhen: listenWhen,
          callListenerOnInit: callListenerOnInit,
          child: child ?? const SizedBox(),
        ),
      );
    }

    Widget buildTwoProviderListener({
      required MultiStateProviders<TwoStates> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<TwoStates>? dataStateListener,
      ListenWhen<TwoStates>? listenWhen,
      bool callListenerOnInit = false,
      EmptyStateBehavior emptyBehavior = EmptyStateBehavior.allEmpty,
      Widget? child,
    }) {
      return wrap(
        MultiViewStateListener<TwoStates>(
          providers: providers,
          initialStateListener: initialStateListener,
          loadingStateListener: loadingStateListener,
          emptyStateListener: emptyStateListener,
          errorStateListener: errorStateListener,
          dataStateListener: dataStateListener,
          listenWhen: listenWhen,
          callListenerOnInit: callListenerOnInit,
          emptyBehavior: emptyBehavior,
          child: child ?? const SizedBox(),
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 1. Rendering & Child
    // -----------------------------------------------------------------------

    testWidgets('renders child', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          child: const SizedBox(key: Key('child')),
        ),
      );

      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      await tester.pumpWidget(
        MultiViewStateListener<ViewState<String>>(
          providers: singleProvider(provider),
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (AssertionError error) => error.message,
          'message',
          contains('child'),
        ),
      );
    });

    // -----------------------------------------------------------------------
    // 2. State-specific callbacks
    // -----------------------------------------------------------------------

    testWidgets('invokes errorStateListener for ErrorState', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int errorCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          errorStateListener: (_, __, ___, ____) {
            errorCalls++;
          },
        ),
      );

      provider.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pump();

      expect(errorCalls, 1);
    });

    testWidgets('invokes initialStateListener for InitialState', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int initialCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          initialStateListener: () {
            initialCalls++;
          },
        ),
      );

      provider.emit(const InitialState<String>());

      await tester.pump();

      expect(initialCalls, 1);
    });

    testWidgets('invokes loadingStateListener for LoadingState', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int loadingCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          loadingStateListener: (_, __) {
            loadingCalls++;
          },
        ),
      );

      provider.emit(const LoadingState<String>('Loading'));

      await tester.pump();

      expect(loadingCalls, 1);
    });

    testWidgets('invokes emptyStateListener for EmptyState', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int emptyCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          emptyStateListener: (_) {
            emptyCalls++;
          },
        ),
      );

      provider.emit(const EmptyState<String>('Empty'));

      await tester.pump();

      expect(emptyCalls, 1);
    });

    testWidgets('invokes dataStateListener for DataState', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('initial'));

      String? capturedData;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (ViewState<String> state) {
            capturedData = (state as DataState<String>).data;
          },
        ),
      );

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(capturedData, 'updated');
    });

    // -----------------------------------------------------------------------
    // 3. State priority
    // -----------------------------------------------------------------------

    testWidgets('follows Error > Initial > Loading > Empty > Data priority', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int errorCalls = 0;
      int initialCalls = 0;
      int loadingCalls = 0;
      int emptyCalls = 0;
      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          errorStateListener: (_, __, ___, ____) {
            errorCalls++;
          },
          initialStateListener: () {
            initialCalls++;
          },
          loadingStateListener: (_, __) {
            loadingCalls++;
          },
          emptyStateListener: (_) {
            emptyCalls++;
          },
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      provider.emit(const EmptyState<String>('empty'));
      await tester.pump();

      expect(emptyCalls, 1);
      expect(loadingCalls, 0);
      expect(initialCalls, 0);
      expect(errorCalls, 0);

      provider.emit(const LoadingState<String>('loading'));
      await tester.pump();

      expect(loadingCalls, 1);

      provider.emit(const InitialState<String>());
      await tester.pump();

      expect(initialCalls, 1);

      provider.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );
      await tester.pump();

      expect(errorCalls, 1);

      provider.emit(const DataState<String>('data'));
      await tester.pump();

      expect(dataCalls, 1);
    });

    testWidgets('Error remains higher priority than Empty', (tester) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      int errorCalls = 0;
      int emptyCalls = 0;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          errorStateListener: (_, __, ___, ____) {
            errorCalls++;
          },
          emptyStateListener: (_) {
            emptyCalls++;
          },
        ),
      );

      provider1.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pump();

      expect(errorCalls, 1);

      provider2.emit(const EmptyState<String>('empty'));

      await tester.pump();

      expect(errorCalls, 2);
      expect(emptyCalls, 0);
    });

    // -----------------------------------------------------------------------
    // 4. EmptyStateBehavior
    // -----------------------------------------------------------------------

    testWidgets('allEmpty keeps aggregate as Data when one provider is Empty', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      int dataCalls = 0;
      int emptyCalls = 0;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          emptyBehavior: EmptyStateBehavior.allEmpty,
          dataStateListener: (_) {
            dataCalls++;
          },
          emptyStateListener: (_) {
            emptyCalls++;
          },
        ),
      );

      provider2.emit(const EmptyState<String>('empty'));

      await tester.pump();

      expect(dataCalls, 1);
      expect(emptyCalls, 0);
    });

    testWidgets('allEmpty emits Empty only when every provider is Empty', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      String? capturedMessage;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          emptyBehavior: EmptyStateBehavior.allEmpty,
          emptyStateListener: (message) {
            capturedMessage = message;
          },
        ),
      );

      provider1.emit(const EmptyState<String>('Empty A'));

      await tester.pump();

      expect(capturedMessage, isNull);

      provider2.emit(const EmptyState<String>('Empty B'));

      await tester.pump();

      expect(capturedMessage, 'Empty A');
    });

    testWidgets('anyEmpty emits Empty when any provider is Empty', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      String? capturedMessage;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          emptyBehavior: EmptyStateBehavior.anyEmpty,
          emptyStateListener: (message) {
            capturedMessage = message;
          },
        ),
      );

      provider2.emit(const EmptyState<String>('Empty B'));

      await tester.pump();

      expect(capturedMessage, 'Empty B');
    });

    // -----------------------------------------------------------------------
    // 5. Callback parameter ordering
    // -----------------------------------------------------------------------

    testWidgets('errorStateListener receives parameters in exact order', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      final Object expectedError = Exception('original error');
      final StackTrace expectedStackTrace = StackTrace.current;

      const ErrorInfo expectedErrorInfo = ErrorInfo(
        message: 'Mapped error',
        code: 'mapped_error',
      );

      bool originalRetryCalled = false;

      void expectedOnRetry() {
        originalRetryCalled = true;
      }

      ErrorInfo? capturedErrorInfo;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          errorStateListener:
              (
                ErrorInfo errorInfo,
                Object error,
                StackTrace stackTrace,
                VoidCallback? onRetry,
              ) {
                capturedErrorInfo = errorInfo;
                capturedError = error;
                capturedStackTrace = stackTrace;
                capturedOnRetry = onRetry;
              },
        ),
      );

      provider.emit(
        ErrorState<String>(
          expectedError,
          expectedStackTrace,
          errorInfo: expectedErrorInfo,
          onRetry: expectedOnRetry,
        ),
      );

      await tester.pump();

      // These prove the callback parameter ordering.
      expect(capturedErrorInfo, same(expectedErrorInfo));
      expect(capturedError, same(expectedError));
      expect(capturedStackTrace, same(expectedStackTrace));

      // MultiViewStateListener supplies its own aggregate retry callback.
      expect(capturedOnRetry, isNotNull);

      // Calling the aggregate callback should invoke the provider's retry.
      capturedOnRetry!();

      expect(originalRetryCalled, isTrue);
    });

    testWidgets(
      'loadingStateListener receives message first and progress second',
      (tester) async {
        final TestViewStateNotifier<String> provider =
            TestViewStateNotifier<String>(const DataState<String>('data'));

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            loadingStateListener: (String? message, double? progress) {
              capturedMessage = message;
              capturedProgress = progress;
            },
          ),
        );

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.4);
      },
    );

    testWidgets('emptyStateListener receives message', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      String? capturedMessage;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          emptyStateListener: (String? message) {
            capturedMessage = message;
          },
        ),
      );

      provider.emit(const EmptyState<String>('Nothing found'));

      await tester.pump();

      expect(capturedMessage, 'Nothing found');
    });

    // -----------------------------------------------------------------------
    // 6. Exact combined T
    // -----------------------------------------------------------------------

    testWidgets('dataStateListener receives the exact combined T value', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      TwoStates? capturedState;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          dataStateListener: (TwoStates state) {
            capturedState = state;
          },
        ),
      );

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(capturedState, (
        first: const DataState<String>('one-new'),
        second: const DataState<String>('two'),
      ));
    });

    // -----------------------------------------------------------------------
    // 7. First-state details and retry
    // -----------------------------------------------------------------------

    testWidgets(
      'uses the first ErrorState details and retries all current errors',
      (tester) async {
        int provider1RetryCalls = 0;
        int provider2RetryCalls = 0;

        final TestViewStateNotifier<String> provider1 =
            TestViewStateNotifier<String>(const DataState<String>('one'));
        final TestViewStateNotifier<String> provider2 =
            TestViewStateNotifier<String>(const DataState<String>('two'));

        final Object error1 = Exception('error 1');
        final Object error2 = Exception('error 2');

        final StackTrace stackTrace1 = StackTrace.current;
        final StackTrace stackTrace2 = StackTrace.current;

        const ErrorInfo errorInfo1 = ErrorInfo(
          message: 'first error',
          code: 'first',
        );

        const ErrorInfo errorInfo2 = ErrorInfo(
          message: 'second error',
          code: 'second',
        );

        ErrorInfo? capturedErrorInfo;
        Object? capturedError;
        StackTrace? capturedStackTrace;
        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildTwoProviderListener(
            providers: twoProviders(provider1, provider2),
            errorStateListener:
                (
                  ErrorInfo errorInfo,
                  Object error,
                  StackTrace stackTrace,
                  VoidCallback? onRetry,
                ) {
                  capturedErrorInfo = errorInfo;
                  capturedError = error;
                  capturedStackTrace = stackTrace;
                  capturedOnRetry = onRetry;
                },
          ),
        );

        provider1.emit(
          ErrorState<String>(
            error1,
            stackTrace1,
            errorInfo: errorInfo1,
            onRetry: () {
              provider1RetryCalls++;
            },
          ),
        );

        await tester.pump();

        provider2.emit(
          ErrorState<String>(
            error2,
            stackTrace2,
            errorInfo: errorInfo2,
            onRetry: () {
              provider2RetryCalls++;
            },
          ),
        );

        await tester.pump();

        expect(capturedErrorInfo, same(errorInfo1));
        expect(capturedError, same(error1));
        expect(capturedStackTrace, same(stackTrace1));
        expect(capturedOnRetry, isNotNull);

        capturedOnRetry!();

        expect(provider1RetryCalls, 1);
        expect(provider2RetryCalls, 1);
      },
    );

    testWidgets('uses AsyncViewStateNotifier refresh as retry fallback', (
      tester,
    ) async {
      final MockAsyncViewStateNotifier<String> provider =
          MockAsyncViewStateNotifier<String>(fetchDataImpl: () => 'data');

      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          errorStateListener:
              (
                ErrorInfo errorInfo,
                Object error,
                StackTrace stackTrace,
                VoidCallback? onRetry,
              ) {
                capturedOnRetry = onRetry;
              },
        ),
      );

      provider.state = ErrorState<String>(
        StateError('error'),
        StackTrace.current,
      );

      await tester.pump();

      expect(capturedOnRetry, isNotNull);

      capturedOnRetry!();

      expect(provider.refreshCalls, 1);
    });

    testWidgets(
      'retry does nothing for non-async provider without ErrorState retry',
      (tester) async {
        final TestViewStateNotifier<String> provider =
            TestViewStateNotifier<String>(
              ErrorState<String>(StateError('error'), StackTrace.current),
            );

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            callListenerOnInit: true,
            errorStateListener:
                (
                  ErrorInfo errorInfo,
                  Object error,
                  StackTrace stackTrace,
                  VoidCallback? onRetry,
                ) {
                  capturedOnRetry = onRetry;
                },
          ),
        );

        expect(capturedOnRetry, isNotNull);

        capturedOnRetry!();

        expect(provider.state, isA<ErrorState<String>>());
      },
    );

    // -----------------------------------------------------------------------
    // 8. Loading aggregation
    // -----------------------------------------------------------------------

    testWidgets('uses first loading message and averages available progress', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          loadingStateListener: (String? message, double? progress) {
            capturedMessage = message;
            capturedProgress = progress;
          },
        ),
      );

      provider1.emit(const LoadingState<String>('Load A', 0.3));

      await tester.pump();

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.3);

      provider2.emit(const LoadingState<String>('Load B', 0.7));

      await tester.pump();

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.5);
    });

    testWidgets('ignores null loading progress', (tester) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      double? capturedProgress;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          loadingStateListener: (_, progress) {
            capturedProgress = progress;
          },
        ),
      );

      provider1.emit(const LoadingState<String>('Load A', 0.8));

      await tester.pump();

      provider2.emit(const LoadingState<String>('Load B'));

      await tester.pump();

      expect(capturedProgress, 0.8);
    });

    testWidgets('returns zero progress when every loading progress is null', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));
      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      double? capturedProgress;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          loadingStateListener: (_, progress) {
            capturedProgress = progress;
          },
        ),
      );

      provider1.emit(const LoadingState<String>('Load A'));

      await tester.pump();

      expect(capturedProgress, 0.0);

      provider2.emit(const LoadingState<String>('Load B'));

      await tester.pump();

      expect(capturedProgress, 0.0);
    });

    // -----------------------------------------------------------------------
    // 9. listenWhen
    // -----------------------------------------------------------------------

    testWidgets('default listenWhen ignores equivalent values', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('initial'));

      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(dataCalls, 1);

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(dataCalls, 1);
    });

    testWidgets(
      'custom listenWhen receives previous and current combined values',
      (tester) async {
        final TestViewStateNotifier<String> provider1 =
            TestViewStateNotifier<String>(const DataState<String>('one'));
        final TestViewStateNotifier<String> provider2 =
            TestViewStateNotifier<String>(const DataState<String>('two'));

        TwoStates? capturedPrevious;
        TwoStates? capturedCurrent;
        int dataCalls = 0;

        await tester.pumpWidget(
          buildTwoProviderListener(
            providers: twoProviders(provider1, provider2),
            listenWhen: (previous, current) {
              capturedPrevious = previous;
              capturedCurrent = current;

              return previous.second != current.second;
            },
            dataStateListener: (_) {
              dataCalls++;
            },
          ),
        );

        provider1.emit(const DataState<String>('one-new'));

        await tester.pump();

        expect(capturedPrevious, (
          first: const DataState<String>('one'),
          second: const DataState<String>('two'),
        ));

        expect(capturedCurrent, (
          first: const DataState<String>('one-new'),
          second: const DataState<String>('two'),
        ));

        expect(dataCalls, 0);

        provider2.emit(const DataState<String>('two-new'));

        await tester.pump();

        expect(dataCalls, 1);

        expect(capturedPrevious, (
          first: const DataState<String>('one-new'),
          second: const DataState<String>('two'),
        ));

        expect(capturedCurrent, (
          first: const DataState<String>('one-new'),
          second: const DataState<String>('two-new'),
        ));
      },
    );

    testWidgets('listenWhen baseline advances when a change is filtered', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('first'));

      final List<String> previousValues = <String>[];
      final List<String> currentValues = <String>[];

      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          listenWhen: (previous, current) {
            final DataState<String> previousState =
                previous as DataState<String>;

            final DataState<String> currentState = current as DataState<String>;

            previousValues.add(previousState.data);
            currentValues.add(currentState.data);

            return currentState.data == 'third';
          },
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      provider.emit(const DataState<String>('second'));

      await tester.pump();

      expect(dataCalls, 0);

      provider.emit(const DataState<String>('third'));

      await tester.pump();

      expect(previousValues, <String>['first', 'second']);

      expect(currentValues, <String>['second', 'third']);

      expect(dataCalls, 1);
    });

    // -----------------------------------------------------------------------
    // 10. callListenerOnInit
    // -----------------------------------------------------------------------

    testWidgets('does not call listeners on init by default', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      await tester.pump();

      expect(dataCalls, 0);
    });

    testWidgets('callListenerOnInit invokes the listener with initial state', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(
            const LoadingState<String>('Loading', 0.5),
          );

      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          callListenerOnInit: true,
          loadingStateListener: (message, progress) {
            capturedMessage = message;
            capturedProgress = progress;
          },
        ),
      );

      await tester.pump();

      expect(capturedMessage, 'Loading');
      expect(capturedProgress, 0.5);
    });

    // -----------------------------------------------------------------------
    // 11. Dependency tracking
    // -----------------------------------------------------------------------

    testWidgets('tracks every provider accessed through watch', (tester) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));

      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      int dataCalls = 0;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          dataStateListener: (_) {
            dataCalls++;
          },
        ),
      );

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataCalls, 1);

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(dataCalls, 2);
    });

    testWidgets('deduplicates the same watched provider', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      int dataCalls = 0;

      await tester.pumpWidget(
        wrap(
          MultiViewStateListener<TwoStates>(
            providers: () => (first: provider.watch, second: provider.watch),
            dataStateListener: (_) {
              dataCalls++;
            },
            child: const SizedBox(),
          ),
        ),
      );

      provider.emit(const DataState<String>('updated'));

      await tester.pump();

      expect(dataCalls, 1);
    });

    testWidgets(
      'throws StateError when a watched dependency is not a ViewStateNotifier',
      (tester) async {
        final StateField<String> field = StateField<String>('data');

        await tester.pumpWidget(
          wrap(
            MultiViewStateListener<String>(
              providers: () => field.watch,
              child: const SizedBox(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('ViewStateNotifier'),
          ),
        );
      },
    );

    // -----------------------------------------------------------------------
    // 12. Runtime dependency changes
    // -----------------------------------------------------------------------

    testWidgets('switches subscriptions when watched provider changes', (
      tester,
    ) async {
      final TestViewStateNotifier<String> provider1 =
          TestViewStateNotifier<String>(const DataState<String>('one'));

      final TestViewStateNotifier<String> provider2 =
          TestViewStateNotifier<String>(const DataState<String>('two'));

      MultiStateProviders<ViewState<String>> providers = singleProvider(
        provider1,
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  MultiViewStateListener<ViewState<String>>(
                    providers: providers,
                    dataStateListener: (_) {
                      dataCalls++;
                    },
                    child: const SizedBox(),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        providers = singleProvider(provider2);
                      });
                    },
                    child: const Text('Switch'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataCalls, 1);

      await tester.tap(find.text('Switch'));

      await tester.pump();

      provider1.emit(const DataState<String>('one-after-switch'));

      await tester.pump();

      expect(dataCalls, 1);

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(dataCalls, 2);
    });

    testWidgets(
      'does not duplicate notifications after rebuilding with same dependency',
      (tester) async {
        final TestViewStateNotifier<String> provider =
            TestViewStateNotifier<String>(const DataState<String>('data'));

        int dataCalls = 0;

        Widget buildFrame() {
          return buildListener(
            providers: singleProvider(provider),
            dataStateListener: (_) {
              dataCalls++;
            },
          );
        }

        await tester.pumpWidget(buildFrame());

        provider.emit(const DataState<String>('first'));

        await tester.pump();

        expect(dataCalls, 1);

        await tester.pumpWidget(buildFrame());

        provider.emit(const DataState<String>('second'));

        await tester.pump();

        expect(dataCalls, 2);
      },
    );

    // -----------------------------------------------------------------------
    // 13. Cleanup
    // -----------------------------------------------------------------------

    testWidgets('detaches listeners when widget is removed', (tester) async {
      final TestViewStateNotifier<String> provider =
          TestViewStateNotifier<String>(const DataState<String>('data'));

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });
  });
}
