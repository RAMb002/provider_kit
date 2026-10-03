import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';

void main() {
  group('MultiViewState change detection', () {
    testWidgets(
      'does not rebuild or listen when a DataState with equal values is emitted',
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
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);

        // New DataState object with the same value.
        // ignore: prefer_const_constructors
        provider2.emit(DataState<String>('two'));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);
      },
    );

    testWidgets(
      'rebuilds and listens when one of four Data providers changes',
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
          ),
        );
        expect(buildCount, 1);
        provider3.emit(const DataState<String>('three-new'));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);
      },
    );

    testWidgets(
      'does not react when a later Loading message changes but the aggregate stays the same',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const LoadingState<String>('First', 0.2),
        );
        final provider2 = TestViewStateNotifier<String>(
          const LoadingState<String>('Second', 0.8),
        );
        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );
        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

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
          ),
        );

        expect(buildCount, 1);

        // The combined record/list state changes, but the first loading
        // message and average progress remain unchanged.
        provider2.emit(const LoadingState<String>('Second changed', 0.8));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);
      },
    );

    testWidgets('reacts when Loading aggregate progress changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState<String>('First', 0.2),
      );
      final provider2 = TestViewStateNotifier<String>(
        const LoadingState<String>('Second', 0.8),
      );
      final provider3 = TestViewStateNotifier<String>(
        const DataState<String>('three'),
      );
      final provider4 = TestViewStateNotifier<String>(
        const DataState<String>('four'),
      );

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
        ),
      );

      provider2.emit(const LoadingState<String>('Second', 0.9));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);
    });

    testWidgets('reacts when the first Loading provider message changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const LoadingState<String>('First', 0.2),
      );
      final provider2 = TestViewStateNotifier<String>(
        const LoadingState<String>('Second', 0.8),
      );
      final provider3 = TestViewStateNotifier<String>(
        const DataState<String>('three'),
      );
      final provider4 = TestViewStateNotifier<String>(
        const DataState<String>('four'),
      );

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
        ),
      );

      provider1.emit(const LoadingState<String>('First changed', 0.2));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);
    });

    testWidgets(
      'does not react when a later Empty message changes but the aggregate stays the same',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const EmptyState<String>('First'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const EmptyState<String>('Second'),
        );
        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );
        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

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
          ),
        );
        provider2.emit(const EmptyState<String>('Second changed'));
        await tester.pump();
        expect(buildCount, 1);
        expect(listenerCount, 0);
      },
    );

    testWidgets('reacts when the first Empty provider message changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const EmptyState<String>('First'),
      );
      final provider2 = TestViewStateNotifier<String>(
        const EmptyState<String>('Second'),
      );
      final provider3 = TestViewStateNotifier<String>(
        const DataState<String>('three'),
      );
      final provider4 = TestViewStateNotifier<String>(
        const DataState<String>('four'),
      );

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
        ),
      );

      provider1.emit(const EmptyState<String>('First changed'));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);
    });

    testWidgets(
      'ignores changes to a later Error when first error details and retry set stay the same',
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
            errorInfo: const ErrorInfo(message: 'First'),
            onRetry: () => firstRetryCalls++,
          ),
        );

        final provider2 = TestViewStateNotifier<String>(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: const ErrorInfo(message: 'Second'),
            onRetry: () => secondRetryCalls++,
          ),
        );

        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );

        final provider4 = TestViewStateNotifier<String>(
          const DataState<String>('four'),
        );

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
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);

        provider2.emit(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: const ErrorInfo(message: 'Second'),
            onRetry: () => secondRetryCalls++,
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);

        // Removing the retry operation changes the retryable provider set.
        provider2.emit(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: const ErrorInfo(message: 'Second'),
          ),
        );
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        // Changing the first error details changes the aggregate.
        final changedFirstError = StateError('first-changed');

        provider1.emit(
          ErrorState<String>(
            changedFirstError,
            firstStackTrace,
            errorInfo: const ErrorInfo(message: 'First changed'),
            onRetry: () => firstRetryCalls++,
          ),
        );
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);
      },
    );

    testWidgets(
      'reacts when a retryable Error provider is removed from the retry set',
      (tester) async {
        int firstRetryCalls = 0;
        int secondRetryCalls = 0;

        final firstError = StateError('first');
        final secondError = StateError('second');

        final firstStackTrace = StackTrace.current;
        final secondStackTrace = StackTrace.current;

        final provider1 = TestViewStateNotifier<String>(
          ErrorState<String>(
            firstError,
            firstStackTrace,
            onRetry: () => firstRetryCalls++,
          ),
        );

        final provider2 = TestViewStateNotifier<String>(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            onRetry: () => secondRetryCalls++,
          ),
        );

        final provider3 = TestViewStateNotifier<String>(
          const DataState<String>('three'),
        );

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [
              provider1.watch,
              provider2.watch,
              provider3.watch,
            ],
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
          ),
        );

        expect(buildCount, 1);

        provider2.emit(const DataState<String>('two'));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        // The first provider remains retryable.
        expect(firstRetryCalls, 0);
        expect(secondRetryCalls, 0);
      },
    );

    testWidgets(
      'uses the latest retry callback from a later error provider without rebuilding or',
      (tester) async {
        int firstRetryCalls = 0;
        int oldSecondRetryCalls = 0;
        int newSecondRetryCalls = 0;

        final provider1 = TestViewStateNotifier<String>(
          ErrorState<String>(
            StateError('first'),
            StackTrace.current,
            errorInfo: const ErrorInfo(message: 'First'),
            onRetry: () => firstRetryCalls++,
          ),
        );

        final secondError = StateError('second');
        final secondStackTrace = StackTrace.current;
        const secondErrorInfo = ErrorInfo(message: 'Second');

        final provider2 = TestViewStateNotifier<String>(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: secondErrorInfo,
            onRetry: () => oldSecondRetryCalls++,
          ),
        );

        int buildCount = 0;
        int listenerCount = 0;

        VoidCallback? errorBuilderRetry;
        VoidCallback? errorListenerRetry;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => [provider1.watch, provider2.watch],
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            callListenerOnInit: true,
            onErrorBuilder: (_, __, ___, onRetry, ____) {
              errorBuilderRetry = onRetry;
              return const SizedBox();
            },
            onErrorListener: (_, __, ___, onRetry) {
              errorListenerRetry = onRetry;
            },
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 1);
        expect(errorBuilderRetry, isNotNull);
        expect(errorListenerRetry, isNotNull);
        provider2.emit(
          ErrorState<String>(
            secondError,
            secondStackTrace,
            errorInfo: secondErrorInfo,
            onRetry: () => newSecondRetryCalls++,
          ),
        );

        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 1);

        errorBuilderRetry!.call();

        expect(firstRetryCalls, 1);
        expect(oldSecondRetryCalls, 0);
        expect(newSecondRetryCalls, 1);

        errorListenerRetry!.call();

        expect(firstRetryCalls, 2);
        expect(oldSecondRetryCalls, 0);
        expect(newSecondRetryCalls, 2);
      },
    );

    testWidgets('reacts when the set of retryable Error providers changes', (
      tester,
    ) async {
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
          errorInfo: const ErrorInfo(message: 'First'),
          onRetry: () => firstRetryCalls++,
        ),
      );

      final provider2 = TestViewStateNotifier<String>(
        ErrorState<String>(
          secondError,
          secondStackTrace,
          errorInfo: const ErrorInfo(message: 'Second'),
        ),
      );

      int buildCount = 0;
      int listenerCount = 0;

      await tester.pumpWidget(
        _buildConsumer(
          providers: () => [provider1.watch, provider2.watch],
          onBuild: () => buildCount++,
          onListen: () => listenerCount++,
        ),
      );

      expect(buildCount, 1);
      expect(listenerCount, 0);

      // Add a retry operation to the later Error provider.
      provider2.emit(
        ErrorState<String>(
          secondError,
          secondStackTrace,
          errorInfo: const ErrorInfo(message: 'Second'),
          onRetry: () => secondRetryCalls++,
        ),
      );

      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);

      // Remove the retry operation again.
      provider2.emit(
        ErrorState<String>(
          secondError,
          secondStackTrace,
          errorInfo: const ErrorInfo(message: 'Second'),
        ),
      );

      await tester.pump();

      expect(buildCount, 3);
      expect(listenerCount, 2);
    });

    testWidgets(
      'reacts when the aggregate enters InitialState and ignores repeated InitialState',
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
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);

        // Data → Initial changes the aggregate.
        provider1.emit(const InitialState<String>());
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        // Repeated Initial does not change the aggregate.
        provider1.emit(const InitialState<String>());
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        // Initial → Loading changes the aggregate again.
        provider1.emit(const LoadingState<String>('loading', 0.2));
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);
      },
    );

    testWidgets(
      'reacts to an aggregate change even when combined T stays equal',
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

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer<bool>(
            providers: () {
              provider1.watch;
              provider2.watch;
              provider3.watch;
              provider4.watch;

              return true;
            },
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
          ),
        );

        expect(buildCount, 1);

        provider3.emit(const LoadingState<String>('loading', 0.2));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        provider3.emit(const LoadingState<String>('loading', 0.2));
        await tester.pump();

        expect(buildCount, 2);
        expect(listenerCount, 1);

        provider3.emit(const LoadingState<String>('loading', 0.4));
        await tester.pump();

        expect(buildCount, 3);
        expect(listenerCount, 2);
      },
    );

    testWidgets(
      'ignores a combined T change while the aggregate remains Loading',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const LoadingState<String>('First', 0.2),
        );
        final provider2 = TestViewStateNotifier<String>(
          const LoadingState<String>('Second', 0.8),
        );

        int buildCount = 0;
        int listenerCount = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => (first: provider1.watch, second: provider2.watch),
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
          ),
        );

        expect(buildCount, 1);

        // T changes because the second ViewState changes.
        // The aggregate does not change because provider1 remains the first
        // Loading provider and the average progress remains 0.5.
        provider2.emit(const LoadingState<String>('Second changed', 0.8));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);
      },
    );

    testWidgets(
      'replacing the watched provider with another provider that has the same state does not fire a notification',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('same'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('same'),
        );

        bool useProvider1 = true;
        int listenerCount = 0;

        Widget buildWidget() {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: MultiViewStateListener(
              providers: () => (useProvider1 ? provider1 : provider2).watch,
              dataStateListener: (_) => listenerCount++,
              child: const SizedBox(),
            ),
          );
        }

        await tester.pumpWidget(buildWidget());

        expect(listenerCount, 0);

        useProvider1 = false;
        await tester.pumpWidget(buildWidget());

        // Dependency replacement establishes the new baseline.
        expect(listenerCount, 0);

        // The old provider must no longer trigger the listener.
        provider1.emit(const DataState<String>('changed'));
        await tester.pump();

        expect(listenerCount, 0);

        // The new provider is now subscribed.
        provider2.emit(const DataState<String>('changed'));
        await tester.pump();

        expect(listenerCount, 1);
      },
    );

    testWidgets(
      'evaluates listenWhen and rebuildWhen only after a meaningful change',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('loading', 0.2),
        );

        int buildCount = 0;
        int listenerCount = 0;
        int listenWhenCalls = 0;
        int rebuildWhenCalls = 0;

        await tester.pumpWidget(
          _buildConsumer(
            providers: () => provider.watch,
            onBuild: () => buildCount++,
            onListen: () => listenerCount++,
            listenWhen: (_, __) {
              listenWhenCalls++;
              return false;
            },
            rebuildWhen: (_, __) {
              rebuildWhenCalls++;
              return false;
            },
          ),
        );

        expect(buildCount, 1);
        expect(listenerCount, 0);
        expect(listenWhenCalls, 0);
        expect(rebuildWhenCalls, 0);

        // Same aggregate.
        provider.emit(const LoadingState<String>('loading', 0.2));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);
        expect(listenWhenCalls, 0);
        expect(rebuildWhenCalls, 0);

        // Aggregate changed, so both user filters are evaluated.
        provider.emit(const LoadingState<String>('loading', 0.3));
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerCount, 0);
        expect(listenWhenCalls, 1);
        expect(rebuildWhenCalls, 1);
      },
    );

    testWidgets('applies listenWhen and rebuildWhen independently', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState<String>('loading', 0.2),
      );

      int buildCount = 0;
      int listenerCount = 0;

      bool allowBuild = true;
      bool allowListen = false;

      await tester.pumpWidget(
        _buildConsumer(
          providers: () => provider.watch,
          onBuild: () => buildCount++,
          onListen: () => listenerCount++,
          listenWhen: (_, __) => allowListen,
          rebuildWhen: (_, __) => allowBuild,
        ),
      );

      expect(buildCount, 1);
      expect(listenerCount, 0);

      // Rebuild only.
      provider.emit(const LoadingState<String>('loading', 0.3));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 0);

      // Listen only.
      allowBuild = false;
      allowListen = true;

      provider.emit(const LoadingState<String>('loading', 0.4));
      await tester.pump();

      expect(buildCount, 2);
      expect(listenerCount, 1);
    });
  });
}

Widget _buildConsumer<T>({
  required MultiStateProviders<T> providers,
  required VoidCallback onBuild,
  required VoidCallback onListen,
  ErrorStateBuilder? onErrorBuilder,
  ErrorStateListener? onErrorListener,
  ListenWhen<T>? listenWhen,
  RebuildWhen<T>? rebuildWhen,
  bool callListenerOnInit = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MultiViewStateConsumer<T>(
      callListenerOnInit: callListenerOnInit,
      providers: providers,
      initialBuilder: (_) {
        onBuild();
        return const SizedBox();
      },
      loadingBuilder: (_, __, ___) {
        onBuild();
        return const SizedBox();
      },
      emptyBuilder: (_, __) {
        onBuild();
        return const SizedBox();
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
      dataBuilder: (_) {
        onBuild();
        return const SizedBox();
      },
      initialStateListener: onListen,
      loadingStateListener: (_, __) => onListen(),
      emptyStateListener: (_) => onListen(),
      errorStateListener: (errorInfo, error, stackTrace, onRetry) {
        onListen();
        onErrorListener?.call(errorInfo, error, stackTrace, onRetry);
      },
      dataStateListener: (_) => onListen(),
      listenWhen: listenWhen,
      rebuildWhen: rebuildWhen,
    ),
  );
}
