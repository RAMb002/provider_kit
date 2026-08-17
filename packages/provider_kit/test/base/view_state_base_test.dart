import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/states/states.dart';
import 'package:provider_kit/src/view_state_widgets_provider.dart';

import '../shared/mocks/provider_kit.dart';
import '../shared/mocks/view_state_notifiers.dart';

void main() {
  group('ViewStateBase', () {
    // =========================================================================
    // hasErrorState
    // =========================================================================

    group('hasErrorState', () {
      test('returns true when at least one ErrorState exists', () {
        final states = <ViewState<String>>[
          const DataState('data'),
          const ErrorState<String>('error'),
          const LoadingState<String>(),
        ];

        expect(ViewStateBase.hasErrorState(states), isTrue);
      });

      test('returns false when no ErrorState exists', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const LoadingState<String>(),
          const EmptyState<String>(),
          const DataState('data'),
        ];

        expect(ViewStateBase.hasErrorState(states), isFalse);
      });

      test('returns false for an empty list', () {
        expect(
          ViewStateBase.hasErrorState<String>(const []),
          isFalse,
        );
      });
    });

    // =========================================================================
    // hasInitialState
    // =========================================================================

    group('hasInitialState', () {
      test('returns true when at least one InitialState exists', () {
        final states = <ViewState<String>>[
          const DataState('data'),
          const InitialState<String>(),
        ];

        expect(ViewStateBase.hasInitialState(states), isTrue);
      });

      test('returns false when no InitialState exists', () {
        final states = <ViewState<String>>[
          const LoadingState<String>(),
          const EmptyState<String>(),
          const DataState('data'),
          const ErrorState<String>('error'),
        ];

        expect(ViewStateBase.hasInitialState(states), isFalse);
      });

      test('returns false for an empty list', () {
        expect(
          ViewStateBase.hasInitialState<String>(const []),
          isFalse,
        );
      });
    });

    // =========================================================================
    // hasLoadingState
    // =========================================================================

    group('hasLoadingState', () {
      test('returns true when at least one LoadingState exists', () {
        final states = <ViewState<String>>[
          const DataState('data'),
          const LoadingState<String>(),
        ];

        expect(ViewStateBase.hasLoadingState(states), isTrue);
      });

      test('returns false when no LoadingState exists', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const EmptyState<String>(),
          const DataState('data'),
          const ErrorState<String>('error'),
        ];

        expect(ViewStateBase.hasLoadingState(states), isFalse);
      });

      test('returns false for an empty list', () {
        expect(
          ViewStateBase.hasLoadingState<String>(const []),
          isFalse,
        );
      });
    });

    // =========================================================================
    // hasEmptyState
    // =========================================================================

    group('hasEmptyState', () {
      test('returns true when at least one EmptyState exists', () {
        final states = <ViewState<String>>[
          const DataState('data'),
          const EmptyState<String>(),
        ];

        expect(ViewStateBase.hasEmptyState(states), isTrue);
      });

      test('returns false when no EmptyState exists', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const LoadingState<String>(),
          const DataState('data'),
          const ErrorState<String>('error'),
        ];

        expect(ViewStateBase.hasEmptyState(states), isFalse);
      });

      test('returns false for an empty list', () {
        expect(
          ViewStateBase.hasEmptyState<String>(const []),
          isFalse,
        );
      });
    });

    // =========================================================================
    // allAreDataState
    // =========================================================================

    group('allAreDataState', () {
      test('returns true when every state is DataState', () {
        final states = <ViewState<String>>[
          const DataState('one'),
          const DataState('two'),
          const DataState('three'),
        ];

        expect(ViewStateBase.allAreDataState(states), isTrue);
      });

      test('returns false when any state is not DataState', () {
        final states = <ViewState<String>>[
          const DataState('one'),
          const LoadingState<String>(),
          const DataState('three'),
        ];

        expect(ViewStateBase.allAreDataState(states), isFalse);
      });

      test('returns false when the first state is not DataState', () {
        final states = <ViewState<String>>[
          const LoadingState<String>(),
          const DataState('data'),
        ];

        expect(ViewStateBase.allAreDataState(states), isFalse);
      });

      test('returns false when the last state is not DataState', () {
        final states = <ViewState<String>>[
          const DataState('data'),
          const ErrorState<String>('error'),
        ];

        expect(ViewStateBase.allAreDataState(states), isFalse);
      });

      test('returns true for an empty list', () {
        // Iterable.every() is true for an empty iterable.
        expect(
          ViewStateBase.allAreDataState<String>(const []),
          isTrue,
        );
      });
    });

    // =========================================================================
    // buildInitialWidget
    // =========================================================================

    group('buildInitialWidget', () {
      testWidgets('uses custom builder when provided', (tester) async {
        const customKey = Key('custom_initial');
        bool? receivedIsSliver;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final widget = ViewStateBase.buildInitialWidget(
                  context,
                  (isSliver) {
                    receivedIsSliver = isSliver;
                    return const SizedBox(key: customKey);
                  },
                  true,
                );

                return widget;
              },
            ),
          ),
        );

        expect(find.byKey(customKey), findsOneWidget);
        expect(receivedIsSliver, isTrue);
      });

      testWidgets('uses default ViewStateWidgetsProvider when builder is null',
          (tester) async {
        const defaultKey = Key('default_initial');

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_) => const SizedBox(key: defaultKey),
            loadingStateBuilder: (_, __, ___) => const SizedBox(),
            emptyStateBuilder: (_, __) => const SizedBox(),
            errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return ViewStateBase.buildInitialWidget(
                    context,
                    null,
                    false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byKey(defaultKey), findsOneWidget);
      });
    });

    // =========================================================================
    // buildLoadingWidget
    // =========================================================================

    group('buildLoadingWidget', () {
      testWidgets('uses custom builder when provided', (tester) async {
        const customKey = Key('custom_loading');

        String? capturedMessage;
        double? capturedProgress;
        bool? capturedIsSliver;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                return ViewStateBase.buildLoadingWidget(
                  context,
                  (message, progress, isSliver) {
                    capturedMessage = message;
                    capturedProgress = progress;
                    capturedIsSliver = isSliver;
                    return const SizedBox(key: customKey);
                  },
                  'Loading...',
                  0.5,
                  true,
                );
              },
            ),
          ),
        );

        expect(find.byKey(customKey), findsOneWidget);
        expect(capturedMessage, 'Loading...');
        expect(capturedProgress, 0.5);
        expect(capturedIsSliver, isTrue);
      });

      testWidgets('passes null message and progress to custom builder',
          (tester) async {
        String? capturedMessage = 'initial';
        double? capturedProgress = 1.0;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                return ViewStateBase.buildLoadingWidget(
                  context,
                  (message, progress, _) {
                    capturedMessage = message;
                    capturedProgress = progress;
                    return const SizedBox();
                  },
                  null,
                  null,
                  false,
                );
              },
            ),
          ),
        );

        expect(capturedMessage, isNull);
        expect(capturedProgress, isNull);
      });

      testWidgets('uses default ViewStateWidgetsProvider when builder is null',
          (tester) async {
        const defaultKey = Key('default_loading');

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_) => const SizedBox(),
            loadingStateBuilder: (_, __, ___) =>
                const SizedBox(key: defaultKey),
            emptyStateBuilder: (_, __) => const SizedBox(),
            errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return ViewStateBase.buildLoadingWidget(
                    context,
                    null,
                    'Loading...',
                    0.5,
                    false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byKey(defaultKey), findsOneWidget);
      });
    });

    // =========================================================================
    // buildEmptyWidget
    // =========================================================================

    group('buildEmptyWidget', () {
      testWidgets('uses custom builder when provided', (tester) async {
        const customKey = Key('custom_empty');

        String? capturedMessage;
        bool? capturedIsSliver;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                return ViewStateBase.buildEmptyWidget(
                  context,
                  (message, isSliver) {
                    capturedMessage = message;
                    capturedIsSliver = isSliver;
                    return const SizedBox(key: customKey);
                  },
                  'Nothing here',
                  true,
                );
              },
            ),
          ),
        );

        expect(find.byKey(customKey), findsOneWidget);
        expect(capturedMessage, 'Nothing here');
        expect(capturedIsSliver, isTrue);
      });

      testWidgets('passes null message to custom builder', (tester) async {
        String? capturedMessage = 'initial';

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                return ViewStateBase.buildEmptyWidget(
                  context,
                  (message, _) {
                    capturedMessage = message;
                    return const SizedBox();
                  },
                  null,
                  false,
                );
              },
            ),
          ),
        );

        expect(capturedMessage, isNull);
      });

      testWidgets('uses default ViewStateWidgetsProvider when builder is null',
          (tester) async {
        const defaultKey = Key('default_empty');

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_) => const SizedBox(),
            loadingStateBuilder: (_, __, ___) => const SizedBox(),
            emptyStateBuilder: (_, __) => const SizedBox(key: defaultKey),
            errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return ViewStateBase.buildEmptyWidget(
                    context,
                    null,
                    'Empty',
                    false,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byKey(defaultKey), findsOneWidget);
      });
    });

    // =========================================================================
    // onRetry
    // =========================================================================

    group('onRetry', () {
      test('calls explicit ErrorState.onRetry callback', () {
        var retryCalls = 0;

        final provider = TestViewStateNotifier<String>(
          ErrorState<String>(
            'Error',
            null,
            null,
            () => retryCalls++,
          ),
        );

        ViewStateBase.onRetry<String>([provider]);

        expect(retryCalls, 1);
      });

      test('prefers explicit onRetry over AsyncViewStateNotifier.refresh',
          () async {
        var retryCalls = 0;

        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await provider.refresh();

        final refreshCallsBefore = provider.refreshCalls;

        provider.state = ErrorState<String>(
          'Error',
          null,
          null,
          () => retryCalls++,
        );

        ViewStateBase.onRetry<String>([provider]);

        expect(retryCalls, 1);
        expect(provider.refreshCalls, refreshCallsBefore);
      });
      test('calls refresh for AsyncViewStateNotifier without explicit retry',
          () async {
        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await provider.refresh();

        final refreshCallsBefore = provider.refreshCalls;

        provider.state = const ErrorState<String>('Error');

        ViewStateBase.onRetry<String>([provider]);

        expect(
          provider.refreshCalls,
          refreshCallsBefore + 1,
        );
      });

      test('ignores providers that are not in ErrorState', () {
        final provider = TestViewStateNotifier<String>(
          const DataState('data'),
        );

        ViewStateBase.onRetry<String>([provider]);

        expect(provider.state, const DataState('data'));
      });

      test('does nothing for non-async ErrorState without explicit retry', () {
        final provider = TestViewStateNotifier<String>(
          const ErrorState<String>('Error'),
        );

        ViewStateBase.onRetry<String>([provider]);

        expect(
          provider.state,
          const ErrorState<String>('Error'),
        );
      });

      test('processes every provider independently', () {
        var explicitRetryCalls = 0;

        final explicitProvider = TestViewStateNotifier<String>(
          ErrorState<String>(
            'Explicit error',
            null,
            null,
            () => explicitRetryCalls++,
          ),
        );

        final nonErrorProvider = TestViewStateNotifier<String>(
          const DataState('data'),
        );

        ViewStateBase.onRetry<String>([
          explicitProvider,
          nonErrorProvider,
        ]);

        expect(explicitRetryCalls, 1);
        expect(nonErrorProvider.state, const DataState('data'));
      });

      test('retries every eligible async error provider', () async {
        final provider1 = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data1',
        );

        final provider2 = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data2',
        );

        await provider1.refresh();
        await provider2.refresh();

        final provider1RefreshCalls = provider1.refreshCalls;
        final provider2RefreshCalls = provider2.refreshCalls;

        provider1.state = const ErrorState<String>('Error 1');
        provider2.state = const ErrorState<String>('Error 2');

        ViewStateBase.onRetry<String>([
          provider1,
          provider2,
        ]);

        expect(provider1.refreshCalls, provider1RefreshCalls + 1);
        expect(provider2.refreshCalls, provider2RefreshCalls + 1);
      });
    });

    // =========================================================================
    // getCombinedLoadingProgress
    // =========================================================================

    group('getCombinedLoadingProgress', () {
      test('returns the average progress of all loading states', () {
        final states = <LoadingState<String>>[
          const LoadingState<String>('one', 0.2),
          const LoadingState<String>('two', 0.6),
          const LoadingState<String>('three', 1.0),
        ];

        expect(
          ViewStateBase.getCombinedLoadingProgress(states),
          closeTo(0.6, 0.000001),
        );
      });

      test('treats null progress as zero', () {
        final states = <LoadingState<String>>[
          const LoadingState<String>('one'),
          const LoadingState<String>('two', 0.6),
        ];

        expect(
          ViewStateBase.getCombinedLoadingProgress(states),
          closeTo(0.3, 0.000001),
        );
      });

      test('returns exact progress for a single state', () {
        final states = <LoadingState<String>>[
          const LoadingState<String>('loading', 0.75),
        ];

        expect(
          ViewStateBase.getCombinedLoadingProgress(states),
          closeTo(0.75, 0.000001),
        );
      });
    });

    // =========================================================================
    // getErrorStates
    // =========================================================================

    group('getErrorStates', () {
      test('returns only ErrorState values in original order', () {
        const error1 = ErrorState<String>('error1');
        const error2 = ErrorState<String>('error2');

        final states = <ViewState<String>>[
          const DataState('data'),
          error1,
          const LoadingState<String>(),
          error2,
        ];

        expect(
          ViewStateBase.getErrorStates(states),
          [error1, error2],
        );
      });

      test('returns empty list when there are no errors', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const LoadingState<String>(),
          const EmptyState<String>(),
          const DataState('data'),
        ];

        expect(
          ViewStateBase.getErrorStates(states),
          isEmpty,
        );
      });

      test('returns empty list for an empty input', () {
        expect(
          ViewStateBase.getErrorStates<String>(const []),
          isEmpty,
        );
      });
    });

    // =========================================================================
    // getLoadingStates
    // =========================================================================

    group('getLoadingStates', () {
      test('returns only LoadingState values in original order', () {
        const loading1 = LoadingState<String>('loading1', 0.2);
        const loading2 = LoadingState<String>('loading2', 0.8);

        final states = <ViewState<String>>[
          const DataState('data'),
          loading1,
          const ErrorState<String>('error'),
          loading2,
        ];

        expect(
          ViewStateBase.getLoadingStates(states),
          [loading1, loading2],
        );
      });

      test('returns empty list when there are no loading states', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const EmptyState<String>(),
          const DataState('data'),
        ];

        expect(
          ViewStateBase.getLoadingStates(states),
          isEmpty,
        );
      });

      test('returns empty list for an empty input', () {
        expect(
          ViewStateBase.getLoadingStates<String>(const []),
          isEmpty,
        );
      });
    });

    // =========================================================================
    // getEmptyStates
    // =========================================================================

    group('getEmptyStates', () {
      test('returns only EmptyState values in original order', () {
        const empty1 = EmptyState<String>('empty1');
        const empty2 = EmptyState<String>('empty2');

        final states = <ViewState<String>>[
          const DataState('data'),
          empty1,
          const LoadingState<String>(),
          empty2,
        ];

        expect(
          ViewStateBase.getEmptyStates(states),
          [empty1, empty2],
        );
      });

      test('returns empty list when there are no empty states', () {
        final states = <ViewState<String>>[
          const InitialState<String>(),
          const LoadingState<String>(),
          const DataState('data'),
          const ErrorState<String>('error'),
        ];

        expect(
          ViewStateBase.getEmptyStates(states),
          isEmpty,
        );
      });

      test('returns empty list for an empty input', () {
        expect(
          ViewStateBase.getEmptyStates<String>(const []),
          isEmpty,
        );
      });
    });
  });
}
