import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider keys.
// -----------------------------------------------------------------------------

const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

void main() {
  group('MultiViewStateBuilder', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget defaultProviderWidget(Widget child) {
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

    Widget buildBuilder<T>({
      required MultiStateProviders<T> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      RebuildWhen<T>? rebuildWhen,
      bool isSliver = false,
      bool withDefaultProvider = false,
    }) {
      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: MultiViewStateBuilder(
          providers: providers,
          initialBuilder: initialBuilder,
          loadingBuilder: loadingBuilder,
          emptyBuilder: emptyBuilder,
          errorBuilder: errorBuilder,
          dataBuilder: dataBuilder,
          rebuildWhen: rebuildWhen,
          isSliver: isSliver,
        ),
      );

      if (withDefaultProvider) {
        widget = defaultProviderWidget(widget);
      }

      return widget;
    }

    // =========================================================================
    // DATA BUILDING
    // =========================================================================

    testWidgets('renders dataBuilder with the exact combined state', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<int>(const DataState<int>(10));
      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('hello'),
      );

      ({ViewState<int> count, ViewState<String> name})? capturedState;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (count: provider1.watch, name: provider2.watch),
          dataBuilder: (state) {
            capturedState = state;

            return Text('${state.count.data}-${state.name.data}');
          },
        ),
      );

      expect(capturedState, isNotNull);
      expect(capturedState!.count.data, 10);
      expect(capturedState!.name.data, 'hello');
      expect(find.text('10-hello'), findsOneWidget);
    });

    testWidgets('supports a list as the combined state', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );
      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      List<ViewState<String>>? capturedState;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => [provider1.watch, provider2.watch],
          dataBuilder: (state) {
            capturedState = state;

            return Text('${state[0].data}-${state[1].data}');
          },
        ),
      );

      expect(capturedState, isNotNull);
      expect(capturedState![0].data, 'one');
      expect(capturedState![1].data, 'two');
      expect(find.text('one-two'), findsOneWidget);
    });

    testWidgets(
      'dataBuilder runs only when every watched source is DataState',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const LoadingState<String>('loading'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('two'),
        );

        int dataBuilds = 0;
        String? firstData;
        String? secondData;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => (first: provider1.watch, second: provider2.watch),
            initialBuilder: (_) => const SizedBox(),
            loadingBuilder: (_, __, ___) => const SizedBox(),
            emptyBuilder: (_, __) => const SizedBox(),
            errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            dataBuilder: (state) {
              dataBuilds++;
              firstData = state.first.data;
              secondData = state.second.data;

              return const SizedBox();
            },
          ),
        );

        expect(dataBuilds, 0);
        expect(firstData, isNull);
        expect(secondData, isNull);

        provider1.emit(const EmptyState<String>('empty'));
        await tester.pump();

        expect(dataBuilds, 0);

        provider1.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(dataBuilds, 0);

        provider1.emit(const InitialState<String>());
        await tester.pump();

        expect(dataBuilds, 0);

        provider1.emit(const LoadingState<String>('loading-again'));
        await tester.pump();

        expect(dataBuilds, 0);

        provider1.emit(const DataState<String>('one'));
        await tester.pump();

        expect(dataBuilds, 1);
        expect(firstData, 'one');
        expect(secondData, 'two');
      },
    );

    // =========================================================================
    // STATE AGGREGATION
    // =========================================================================

    testWidgets(
      'uses state priority Error > Initial > Loading > Empty > Data',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('one'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('two'),
        );

        String? renderedState;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => (first: provider1.watch, second: provider2.watch),
            errorBuilder: (_, __, ___, ____, _____) {
              renderedState = 'error';
              return const SizedBox();
            },
            initialBuilder: (_) {
              renderedState = 'initial';
              return const SizedBox();
            },
            loadingBuilder: (_, __, ___) {
              renderedState = 'loading';
              return const SizedBox();
            },
            emptyBuilder: (_, __) {
              renderedState = 'empty';
              return const SizedBox();
            },
            dataBuilder: (state) {
              renderedState = 'data';
              // Data is only valid when every source is DataState.
              state.first.data;
              state.second.data;
              return const SizedBox();
            },
          ),
        );

        expect(renderedState, 'data');

        // Data + Loading -> Loading.
        provider2.emit(const LoadingState<String>('loading'));
        await tester.pump();
        expect(renderedState, 'loading');

        // Initial + Loading -> Initial.
        provider1.emit(const InitialState<String>());
        await tester.pump();
        expect(renderedState, 'initial');

        // Initial + Error -> Error.
        provider2.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();
        expect(renderedState, 'error');

        // Empty + Error -> Error.
        provider1.emit(const EmptyState<String>('empty'));
        await tester.pump();
        expect(renderedState, 'error');

        // Empty + Data -> Empty.
        provider2.emit(const DataState<String>('two-new'));
        await tester.pump();
        expect(renderedState, 'empty');

        // Data + Data -> Data.
        provider1.emit(const DataState<String>('one-new'));
        await tester.pump();
        expect(renderedState, 'data');
      },
    );

    testWidgets('uses the first encountered error details', (tester) async {
      final firstError = StateError('first');
      final firstStackTrace = StackTrace.current;

      final provider1 = TestViewStateNotifier<String>(
        ErrorState<String>(
          firstError,
          firstStackTrace,
          errorInfo: const ErrorInfo(message: 'First error'),
        ),
      );

      final provider2 = TestViewStateNotifier<String>(
        ErrorState<String>(
          StateError('second'),
          StackTrace.current,
          errorInfo: const ErrorInfo(message: 'Second error'),
        ),
      );

      ErrorInfo? capturedErrorInfo;
      Object? capturedError;
      StackTrace? capturedStackTrace;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (errorInfo, error, stackTrace, __, ___) {
            capturedErrorInfo = errorInfo;
            capturedError = error;
            capturedStackTrace = stackTrace;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedErrorInfo, isNotNull);
      expect(capturedErrorInfo!.message, 'First error');
      expect(capturedError, same(firstError));
      expect(capturedStackTrace, same(firstStackTrace));
    });

    // =========================================================================
    // BUILDER PARAMETERS
    // =========================================================================

    testWidgets('errorBuilder receives all expected parameters', (
      tester,
    ) async {
      final error = StateError('Error!');
      final stackTrace = StackTrace.current;

      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: const ErrorInfo(message: 'Error!'),
        ),
      );

      ErrorInfo? capturedErrorInfo;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      VoidCallback? capturedOnRetry;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          errorBuilder:
              (
                errorInfo,
                receivedError,
                receivedStackTrace,
                onRetry,
                isSliver,
              ) {
                capturedErrorInfo = errorInfo;
                capturedError = receivedError;
                capturedStackTrace = receivedStackTrace;
                capturedOnRetry = onRetry;
                capturedIsSliver = isSliver;

                return const SizedBox();
              },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedErrorInfo, isNotNull);
      expect(capturedErrorInfo!.message, 'Error!');
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
      expect(
        capturedOnRetry,
        isNull,
      ); // No retry callback provided in this test.
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('loadingBuilder receives first message and average progress', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState<String>('Load A', 0.2),
      );
      final provider2 = TestViewStateNotifier<String>(
        const LoadingState<String>('Load B', 0.8),
      );

      String? capturedMessage;
      double? capturedProgress;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
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

    testWidgets('loading progress ignores states without progress', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState<String>('Load A', 0.4),
      );
      final provider2 = TestViewStateNotifier<String>(
        const LoadingState<String>('Load B'),
      );

      double? capturedProgress;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (first: provider1.watch, second: provider2.watch),
          loadingBuilder: (_, progress, __) {
            capturedProgress = progress;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedProgress, 0.4);
    });

    testWidgets('emptyBuilder receives the first empty message', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const EmptyState<String>('First empty'),
      );
      final provider2 = TestViewStateNotifier<String>(
        const EmptyState<String>('Second empty'),
      );

      String? capturedMessage;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
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

      expect(capturedMessage, 'First empty');
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('initialBuilder receives the isSliver flag', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          initialBuilder: (isSliver) {
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedIsSliver, isTrue);
    });

    // =========================================================================
    // DEFAULT WIDGET FALLBACKS
    // =========================================================================

    testWidgets('uses default initial widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState<String>('loading'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const EmptyState<String>('empty'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    // =========================================================================
    // RETRY
    // =========================================================================

    testWidgets('onRetry invokes retry callbacks only for errored providers', (
      tester,
    ) async {
      int firstRetryCalls = 0;
      int secondRetryCalls = 0;

      final provider1 = TestViewStateNotifier<String>(
        ErrorState<String>(
          StateError('first'),
          StackTrace.current,
          onRetry: () {
            firstRetryCalls++;
          },
        ),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (first: provider1.watch, second: provider2.watch),
          errorBuilder: (_, __, ___, onRetry, ____) {
            capturedOnRetry = onRetry;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedOnRetry, isA<VoidCallback>());

      capturedOnRetry!();

      expect(firstRetryCalls, 1);
      expect(secondRetryCalls, 0);
    });

    testWidgets(
      'onRetry refreshes AsyncViewStateNotifier providers without retry callback',
      (tester) async {
        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        provider.state = ErrorState<String>(
          StateError('error'),
          StackTrace.current,
        );

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            errorBuilder: (_, __, ___, onRetry, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        expect(capturedOnRetry, isA<VoidCallback>());

        capturedOnRetry!();

        expect(provider.refreshCalls, 1);
      },
    );

    testWidgets(
      'onRetry does nothing for a non-async provider without retry callback',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            errorBuilder: (_, __, ___, onRetry, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

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
          buildBuilder(
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

    // =========================================================================
    // REBUILDING
    // =========================================================================

    testWidgets('rebuilds dataBuilder when a watched provider changes', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('first'),
      );

      final states = <String>[];

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (state) {
            states.add(state.data);
            return Text(state.data);
          },
        ),
      );

      expect(states, ['first']);

      provider.emit(const DataState<String>('second'));
      await tester.pump();

      expect(states, ['first', 'second']);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('rebuildWhen can prevent dataBuilder rebuilds', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('first'),
      );

      int buildCount = 0;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (state) {
            buildCount++;
            return Text(state.data);
          },
          rebuildWhen: (_, __) => false,
        ),
      );

      expect(buildCount, 1);

      provider.emit(const DataState<String>('second'));
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('first'), findsOneWidget);
    });

    // =========================================================================
    // RUNTIME DEPENDENCY REPLACEMENT
    // =========================================================================

    testWidgets(
      'switches to a new dependency when providers callback changes',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('one'),
        );

        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('two'),
        );

        bool useProvider1 = true;
        String? capturedValue;

        Widget build() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MultiViewStateBuilder(
              providers: () =>
                  (value: (useProvider1 ? provider1 : provider2).watch),
              dataBuilder: (state) {
                capturedValue = state.value.data;
                return Text(state.value.data);
              },
            ),
          );
        }

        await tester.pumpWidget(build());
        expect(capturedValue, 'one');

        provider1.emit(const DataState<String>('one-new'));
        await tester.pump();
        expect(capturedValue, 'one-new');

        useProvider1 = false;
        await tester.pumpWidget(build());

        expect(capturedValue, 'two');

        provider1.emit(const DataState<String>('one-after-switch'));
        await tester.pump();
        expect(capturedValue, 'two');

        provider2.emit(const DataState<String>('two-new'));
        await tester.pump();
        expect(capturedValue, 'two-new');
      },
    );

    // =========================================================================
    // CLEANUP
    // =========================================================================

    testWidgets('detaches dependencies when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =========================================================================
    // DIAGNOSTICS
    // =========================================================================

    testWidgets(
      'debugFillProperties exposes MultiViewStateBuilder properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<int>(const DataState<int>(1));

        MultiViewStateBuilder(
          providers: () => (value: provider.watch),
          initialBuilder: (_) => const SizedBox(),
          loadingBuilder: (_, __, ___) => const SizedBox(),
          emptyBuilder: (_, __) => const SizedBox(),
          errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
          rebuildWhen: (_, __) => true,
        ).debugFillProperties(diagnostics);

        final description = diagnostics.properties
            .where((node) => !node.isFiltered(DiagnosticLevel.info))
            .map((node) => node.toString())
            .toList();

        expect(description.any((value) => value.contains('providers')), isTrue);
        expect(
          description.any((value) => value.contains('rebuildWhen')),
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
        expect(
          description.any((value) => value.contains('dataBuilder')),
          isTrue,
        );
        expect(
          description.any(
            (value) => value.contains('isSliver') && value.contains('true'),
          ),
          isTrue,
        );
      },
    );
  });
}
