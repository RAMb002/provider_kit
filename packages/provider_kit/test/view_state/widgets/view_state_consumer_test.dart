import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/future_notifier.dart';
import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

// -----------------------------------------------------------------------------
// Helper to provide default ViewStateWidgetsProvider keys once.
// -----------------------------------------------------------------------------
const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

Widget _withDefaultWidgetProvider(Widget child) {
  return ViewStateWidgetsProvider(
    initialStateBuilder: (_, __) => const SizedBox(key: _defaultInitialKey),
    loadingStateBuilder: (_, __, ___) =>
        const SizedBox(key: _defaultLoadingKey),
    emptyStateBuilder: (_, __, ___) => const SizedBox(key: _defaultEmptyKey),
    errorStateBuilder: (_, __, ___) => const SizedBox(key: _defaultErrorKey),
    child: child,
  );
}

void main() {
  group('ViewStateConsumer', () {
    // -----------------------------------------------------------------------
    // Helper to pump a ViewStateConsumer with optional parameters.
    // -----------------------------------------------------------------------
    Widget buildConsumer({
      required TestViewStateNotifier<String> provider,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<String> dataBuilder,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<String>? dataStateListener,
      RebuildWhen<ViewState<String>>? rebuildWhen,
      ListenWhen<ViewState<String>>? listenWhen,
      bool callListenerOnInit = false,
      bool isSliver = false,
      bool withDefaultWidgetProvider = true,
      Widget? child,
    }) {
      final consumer = ViewStateConsumer<String>(
        listenable: provider,
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
        child: child,
      );

      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: consumer,
      );

      if (withDefaultWidgetProvider) {
        widget = _withDefaultWidgetProvider(widget);
      }
      return widget;
    }

    // =======================================================================
    // SECTION 1: BUILDER TESTS (mirror ViewStateBuilder)
    // =======================================================================

    testWidgets('dataBuilder is required and called for DataState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const DataState('Hello'));
      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, data, ___) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, 'Hello');
    });

    testWidgets(
      'reuses the same child without rebuilding it when data changes',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('first'),
        );
        addTearDown(provider.dispose);

        var childBuildCount = 0;
        var dataBuilderCallCount = 0;
        final receivedChildren = <Widget?>[];

        final staticChild = Builder(
          builder: (context) {
            childBuildCount++;
            return const Text('static child');
          },
        );

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            child: staticChild,
            dataBuilder: (_, data, child) {
              dataBuilderCallCount++;
              receivedChildren.add(child);

              return Column(children: [Text(data), if (child != null) child]);
            },
          ),
        );

        expect(find.text('first'), findsOneWidget);
        expect(find.text('static child'), findsOneWidget);
        expect(dataBuilderCallCount, 1);
        expect(childBuildCount, 1);
        expect(identical(receivedChildren.first, staticChild), isTrue);

        provider.emit(const DataState<String>('second'));
        await tester.pump();

        expect(find.text('first'), findsNothing);
        expect(find.text('second'), findsOneWidget);

        // The data builder runs again, but the child instance is reused.
        expect(dataBuilderCallCount, 2);
        expect(childBuildCount, 1);
        expect(receivedChildren, hasLength(2));
        expect(
          receivedChildren.every((child) => identical(child, staticChild)),
          isTrue,
        );
      },
    );

    testWidgets('calls initialBuilder when state is InitialState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialBuilt = false;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialBuilder: (_) {
            initialBuilt = true;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(initialBuilt, true);
    });

    testWidgets('calls loadingBuilder with correct parameters', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState('Loading', 0.7),
      );
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          loadingBuilder: (_, details) {
            capturedMessage = details.message;
            capturedProgress = details.progress;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'Loading');
      expect(capturedProgress, 0.7);
    });

    testWidgets('calls emptyBuilder with message', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const EmptyState('No data'),
      );
      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyBuilder: (_, details) {
            capturedMessage = details.message;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'No data');
    });

    testWidgets('calls errorBuilder with correct parameters', (tester) async {
      final error = Exception('boom');
      final stackTrace = StackTrace.current;

      const errorInfo = ErrorInfo(message: 'Error', code: 'boom');

      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: () {},
        ),
      );

      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      String? capturedMessage;
      String? capturedCode;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          errorBuilder: (_, details) {
            capturedErrorInfo = details.errorInfo;
            capturedOnRetry = details.onRetry;
            capturedError = details.error;
            capturedStackTrace = details.stackTrace;
            capturedMessage = details.message;
            capturedCode = details.code;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedErrorInfo, same(errorInfo));
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedMessage, 'Error');
      expect(capturedCode, 'boom');
    });

    // -----------------------------------------------------------------------
    // Fallback to ViewStateWidgetsProvider (builder)
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const EmptyState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(Exception('Error'), StackTrace.current),
      );

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    testWidgets(
      'throws assertion when state is not DataState and no specific builder or ViewStateWidgetProvider is available',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateConsumer<String>(
              listenable: provider,
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(tester.takeException(), isA<AssertionError>());
      },
    );

    // -----------------------------------------------------------------------
    // onRetry resolution (for builder)
    // -----------------------------------------------------------------------
    testWidgets(
      'errorBuilder receives onRetry from FutureNotifier when not explicitly set',
      (tester) async {
        final exception = Exception('Test');
        final provider = MockFutureNotifier<String>(
          buildImpl: () => throw exception,
        );
        await tester.pumpAndSettle();

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateConsumer<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(capturedOnRetry, isNotNull);
      },
    );

    testWidgets(
      'errorBuilder receives onRetry from ErrorState when explicitly set (overrides notifier retry callback)',
      (tester) async {
        final provider = MockFutureNotifier<String>(
          buildImpl: () => throw Exception('Test'),
        );
        await tester.pumpAndSettle();

        VoidCallback? capturedOnRetry;
        void explicitOnRetry() {}

        provider.state = ErrorState<String>(
          StateError('Error'),
          StackTrace.current,
          onRetry: explicitOnRetry,
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateConsumer<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(capturedOnRetry, explicitOnRetry);
      },
    );

    testWidgets(
      'errorBuilder receives null onRetry when listenable is not a FutureNotifier',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          ErrorState<String>(StateError('Error'), StackTrace.current),
        );
        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateConsumer<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(capturedOnRetry, isNull);
      },
    );

    // -----------------------------------------------------------------------
    // rebuildWhen (builder filtering)
    // -----------------------------------------------------------------------
    testWidgets('rebuildWhen controls whether builder is called', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int buildCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, data, ___) {
            buildCount++;
            return const SizedBox();
          },
          rebuildWhen: (previous, current) {
            if (current is DataState<String>) {
              return current.data.length > 3;
            }
            return true;
          },
        ),
      );

      expect(buildCount, 1);

      provider.emit(const DataState<String>('abc'));
      await tester.pump();
      expect(buildCount, 1);

      provider.emit(const DataState<String>('abcd'));
      await tester.pump();
      expect(buildCount, 2);

      provider.emit(const DataState<String>('xy'));
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets(
      'rebuildWhen receives correct previous and current states across transitions',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        List<ViewState<String>> previousList = [];
        List<ViewState<String>> currentList = [];

        await tester.pumpWidget(
          buildConsumer(
            withDefaultWidgetProvider: true,
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            rebuildWhen: (previous, current) {
              previousList.add(previous);
              currentList.add(current);
              return true;
            },
          ),
        );

        provider.emit(const LoadingState<String>());
        await tester.pump();

        expect(previousList.length, 1);
        expect(previousList[0], const InitialState<String>());
        expect(currentList[0], const LoadingState<String>());

        provider.emit(const DataState<String>('data'));
        await tester.pump();

        expect(previousList.length, 2);
        expect(previousList[1], const LoadingState<String>());
        expect(currentList[1], const DataState<String>('data'));

        provider.emit(
          ErrorState<String>(StateError('Error'), StackTrace.current),
        );
        await tester.pump();

        expect(previousList.length, 3);
        expect(previousList[2], const DataState<String>('data'));
        expect(currentList[2], isA<ErrorState<String>>());
      },
    );

    testWidgets(
      'default widgets from ViewStateWidgetsProvider receive isSliver',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const LoadingState());
        bool? isSliverPassed;

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_, __) => const SizedBox(),
            loadingStateBuilder: (_, __, isSliver) {
              isSliverPassed = isSliver;
              return const SizedBox();
            },
            emptyStateBuilder: (_, __, ___) => const SizedBox(),
            errorStateBuilder: (_, __, ___) => const SizedBox(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ViewStateConsumer<String>(
                listenable: provider,
                isSliver: true,
                dataBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        );

        expect(isSliverPassed, true);
      },
    );

    // =======================================================================
    // SECTION 2: LISTENER TESTS (mirror ViewStateListener)
    // =======================================================================

    testWidgets('calls initialStateListener when state is InitialState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          initialStateListener: (_) => initialCalled = true,
          callListenerOnInit: true,
        ),
      );

      expect(initialCalled, true);

      initialCalled = false;
      provider.emit(const DataState<String>('data'));
      await tester.pump();
      expect(initialCalled, false);

      provider.emit(const InitialState());
      await tester.pump();
      expect(initialCalled, true);
    });

    testWidgets(
      'does not call listener on init when callListenerOnInit is false, but calls on state change',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState('initial'),
        );
        bool initialCalled = false;

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            initialStateListener: (_) => initialCalled = true,
            callListenerOnInit: false,
          ),
        );

        expect(initialCalled, false);

        provider.emit(const LoadingState<String>());
        await tester.pump();
        expect(initialCalled, false);

        provider.emit(const InitialState());
        await tester.pump();
        expect(initialCalled, true);
      },
    );

    testWidgets('calls loadingStateListener with correct parameters', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          loadingStateListener: (_, details) {
            capturedMessage = details.message;
            capturedProgress = details.progress;
          },
        ),
      );

      provider.emit(const LoadingState<String>('Loading...', 0.5));
      await tester.pump();

      expect(capturedMessage, 'Loading...');
      expect(capturedProgress, 0.5);
    });

    testWidgets('calls dataStateListener with data', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          dataStateListener: (_, data) => capturedData = data,
        ),
      );

      provider.emit(const DataState<String>('Hello World'));
      await tester.pump();

      expect(capturedData, 'Hello World');
    });

    testWidgets('calls emptyStateListener with message', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          emptyStateListener: (_, details) => capturedMessage = details.message,
        ),
      );

      provider.emit(const EmptyState<String>('No items found'));
      await tester.pump();

      expect(capturedMessage, 'No items found');
    });

    testWidgets('calls errorStateListener with correct parameters', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      String? capturedMessage;
      String? capturedCode;
      void onRetry() {}
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      const errorInfo = ErrorInfo(
        message: 'Something went wrong',
        code: 'test_error',
      );

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          errorStateListener: (_, details) {
            capturedErrorInfo = details.errorInfo;
            capturedOnRetry = details.onRetry;
            capturedError = details.error;
            capturedStackTrace = details.stackTrace;
            capturedMessage = details.message;
            capturedCode = details.code;
          },
        ),
      );

      provider.emit(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: onRetry,
        ),
      );
      await tester.pump();

      expect(capturedErrorInfo, same(errorInfo));
      expect(capturedOnRetry, same(onRetry));
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
      expect(capturedMessage, 'Something went wrong');
      expect(capturedCode, 'test_error');
    });

    testWidgets(
      'errorStateListener receives onRetry callback from ErrorState',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        VoidCallback? capturedOnRetry;
        void expectedOnRetry() {}

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            errorStateListener: (_, details) {
              capturedOnRetry = details.onRetry;
            },
          ),
        );

        provider.emit(
          ErrorState<String>(
            StateError('error'),
            StackTrace.current,
            onRetry: expectedOnRetry,
          ),
        );
        await tester.pump();
        expect(capturedOnRetry, expectedOnRetry);
      },
    );

    testWidgets(
      'errorStateListener receives correct error details and refresh as onRetry when using FutureNotifier',
      (tester) async {
        final exception = Exception('Test error');
        final provider = MockFutureNotifier<String>(
          buildImpl: () => throw exception,
        );
        await tester.pumpAndSettle();

        expect(provider.state, isA<ErrorState<String>>());

        ErrorInfo? capturedErrorInfo;
        VoidCallback? capturedOnRetry;
        Object? capturedError;
        StackTrace? capturedStackTrace;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: _withDefaultWidgetProvider(
              ViewStateConsumer<String>(
                listenable: provider,
                dataBuilder: (_, __, ___) => const SizedBox(),
                errorStateListener: (_, details) {
                  capturedErrorInfo = details.errorInfo;
                  capturedOnRetry = details.onRetry;
                  capturedError = details.error;
                  capturedStackTrace = details.stackTrace;
                },
                callListenerOnInit: true,
              ),
            ),
          ),
        );

        expect(capturedErrorInfo, isNotNull);
        expect(capturedErrorInfo!.message, exception.toString());
        expect(capturedError, same(exception));
        expect(capturedStackTrace, isNotNull);
        expect(capturedOnRetry, isA<VoidCallback>());

        final refreshCallsBefore = provider.refreshCalls;

        capturedOnRetry!();

        expect(provider.refreshCalls, refreshCallsBefore + 1);
      },
    );

    testWidgets('does not call listener when emitting the same state twice', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int dataListenerCount = 0;
      int builderCallCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) {
            builderCallCount++;
            return const SizedBox();
          },
          dataStateListener: (_, __) => dataListenerCount++,
          callListenerOnInit: false,
        ),
      );

      expect(builderCallCount, 1);

      provider.emit(const DataState<String>('same'));
      await tester.pump();
      expect(dataListenerCount, 1);
      expect(builderCallCount, 2);

      provider.emit(const DataState<String>('same'));
      await tester.pump();

      expect(dataListenerCount, 1);
      expect(builderCallCount, 2);
    });

    testWidgets(
      'only the matching listener and builder callbacks are invoked for each state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );
        addTearDown(provider.dispose);

        final calledBuilders = <String>[];
        final calledListeners = <String>[];

        void expectContext(BuildContext context) {
          expect(
            context
                .findAncestorWidgetOfExactType<TestLocaleInherited>()
                ?.locale,
            'en',
          );
        }

        await tester.pumpWidget(
          TestLocaleInherited(
            locale: 'en',
            child: buildConsumer(
              provider: provider,

              // State builders.
              initialBuilder: (context) {
                expectContext(context);
                calledBuilders.add('initial');
                return const SizedBox();
              },
              loadingBuilder: (context, details) {
                expectContext(context);
                calledBuilders.add('loading');
                return const SizedBox();
              },
              dataBuilder: (context, data, child) {
                expectContext(context);
                calledBuilders.add('data');
                return const SizedBox();
              },
              emptyBuilder: (context, details) {
                expectContext(context);
                calledBuilders.add('empty');
                return const SizedBox();
              },
              errorBuilder: (context, details) {
                expectContext(context);
                calledBuilders.add('error');
                return const SizedBox();
              },

              // State listeners.
              initialStateListener: (context) {
                expectContext(context);
                calledListeners.add('initial');
              },
              loadingStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('loading');
              },
              dataStateListener: (context, data) {
                expectContext(context);
                calledListeners.add('data');
              },
              emptyStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('empty');
              },
              errorStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('error');
              },

              callListenerOnInit: false,
            ),
          ),
        );

        // Initial state: initial builder runs, but the listener does not.
        expect(calledBuilders, ['initial']);
        expect(calledListeners, isEmpty);

        // Initial -> Loading.
        provider.emit(const LoadingState<String>());
        await tester.pump();

        expect(calledBuilders, ['initial', 'loading']);
        expect(calledListeners, ['loading']);

        // Loading -> Data.
        provider.emit(const DataState<String>('data'));
        await tester.pump();

        expect(calledBuilders, ['initial', 'loading', 'data']);
        expect(calledListeners, ['loading', 'data']);

        // Data -> Empty.
        provider.emit(const EmptyState<String>());
        await tester.pump();

        expect(calledBuilders, ['initial', 'loading', 'data', 'empty']);
        expect(calledListeners, ['loading', 'data', 'empty']);

        // Empty -> Error.
        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(calledBuilders, [
          'initial',
          'loading',
          'data',
          'empty',
          'error',
        ]);
        expect(calledListeners, ['loading', 'data', 'empty', 'error']);

        // Error -> Initial.
        provider.emit(const InitialState<String>());
        await tester.pump();

        expect(calledBuilders, [
          'initial',
          'loading',
          'data',
          'empty',
          'error',
          'initial',
        ]);
        expect(calledListeners, [
          'loading',
          'data',
          'empty',
          'error',
          'initial',
        ]);
      },
    );
    testWidgets('callListenerOnInit calls matching listener on init', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int dataCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          dataStateListener: (_, __) => dataCount++,
          callListenerOnInit: true,
        ),
      );

      expect(dataCount, 1);

      provider.emit(const DataState<String>('new data'));
      await tester.pump();
      expect(dataCount, 2);
    });

    testWidgets('callListenerOnInit false does not call on init', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int dataCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          dataStateListener: (_, __) => dataCount++,
          callListenerOnInit: false,
        ),
      );

      expect(dataCount, 0);

      provider.emit(const DataState<String>('new'));
      await tester.pump();
      expect(dataCount, 1);
    });

    testWidgets(
      'listenWhen controls whether listener callbacks are triggered',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        int dataCount = 0;

        bool listenWhen(ViewState<String> previous, ViewState<String> current) {
          if (current is DataState<String>) {
            return current.data.length > 3;
          }
          return true;
        }

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            dataStateListener: (_, __) => dataCount++,
            listenWhen: listenWhen,
            callListenerOnInit: false,
          ),
        );

        provider.emit(const DataState<String>('abc'));
        await tester.pump();
        expect(dataCount, 0);

        provider.emit(const DataState<String>('abcd'));
        await tester.pump();
        expect(dataCount, 1);

        provider.emit(const DataState<String>('xy'));
        await tester.pump();
        expect(dataCount, 1);
      },
    );

    testWidgets(
      'listenWhen receives correct previous and current ViewState objects',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        List<ViewState<String>> previousList = [];
        List<ViewState<String>> currentList = [];

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            dataStateListener: (_, __) {},
            listenWhen: (previous, current) {
              previousList.add(previous);
              currentList.add(current);
              return true;
            },
          ),
        );

        provider.emit(const LoadingState<String>());
        await tester.pump();

        expect(previousList.length, 1);
        expect(previousList[0], const InitialState<String>());
        expect(currentList[0], const LoadingState<String>());

        provider.emit(const DataState<String>('data'));
        await tester.pump();

        expect(previousList.length, 2);
        expect(previousList[1], const LoadingState<String>());
        expect(currentList[1], const DataState<String>('data'));
      },
    );

    testWidgets(
      'updates localized builder messages and uses the latest locale for listener callbacks',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );
        addTearDown(provider.dispose);

        var locale = 'en';
        late StateSetter changeLocale;

        final builderMessages = <String?>[];
        final listenerMessages = <String?>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                changeLocale = setState;

                return TestLocaleInherited(
                  locale: locale,
                  child: ViewStateWidgetsProvider(
                    initialStateBuilder: testDefaultInitialStateBuilder,
                    loadingStateBuilder: testDefaultLoadingStateBuilder,
                    emptyStateBuilder: testDefaultEmptyStateBuilder,
                    errorStateBuilder: testDefaultErrorStateBuilder,
                    messageResolver: testLocaleMessageResolver,
                    child: ViewStateConsumer<String>(
                      listenable: provider,
                      loadingBuilder: (context, details) {
                        builderMessages.add(details.message);
                        return Text(details.message ?? '');
                      },
                      loadingStateListener: (context, details) {
                        expect(
                          context
                              .findAncestorWidgetOfExactType<
                                TestLocaleInherited
                              >()
                              ?.locale,
                          locale,
                        );
                        listenerMessages.add(details.message);
                      },
                      dataBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // The first loading event uses English.
        provider.emit(const LoadingState<String>('profile.loading'));
        await tester.pump();

        expect(find.text('en:profile.loading'), findsOneWidget);
        expect(builderMessages, ['en:profile.loading']);
        expect(listenerMessages, ['en:profile.loading']);

        // Changing locale rebuilds the presentation, not the state listener.
        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(find.text('en:profile.loading'), findsNothing);
        expect(find.text('fr:profile.loading'), findsOneWidget);
        expect(builderMessages, ['en:profile.loading', 'fr:profile.loading']);
        expect(listenerMessages, ['en:profile.loading']);

        // The next state event uses the new locale in both callbacks.
        provider.emit(const LoadingState<String>('profile.refreshing'));
        await tester.pump();

        expect(find.text('fr:profile.refreshing'), findsOneWidget);
        expect(builderMessages, [
          'en:profile.loading',
          'fr:profile.loading',
          'fr:profile.refreshing',
        ]);
        expect(listenerMessages, [
          'en:profile.loading',
          'fr:profile.refreshing',
        ]);
      },
    );

    // -----------------------------------------------------------------------
    // Safe to trigger side effects (deferred execution)
    // -----------------------------------------------------------------------
    testWidgets('safe to trigger dialogs inside listener (deferred)', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: _withDefaultWidgetProvider(
                  ViewStateConsumer<String>(
                    listenable: provider,
                    dataBuilder: (_, __, ___) => const SizedBox(),
                    dataStateListener: (_, data) {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            const AlertDialog(title: Text('Data loaded')),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      provider.emit(const DataState<String>('hello'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('does not crash when state occurs without matching callback', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _withDefaultWidgetProvider(
            ViewStateConsumer<String>(
              listenable: provider,
              dataBuilder: (_, __, ___) => const SizedBox(),
              dataStateListener: (_, __) {},
            ),
          ),
        ),
      );

      provider.emit(const LoadingState<String>());
      await tester.pump();

      // Ensure the default loading widget is rendered, confirming the builder worked.
      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
      // No assertion needed for listener; the test passes if no exception is thrown.
    });

    // =======================================================================
    // SECTION 3: PROVIDER RESOLUTION & RUNTIME CHANGES
    // =======================================================================

    testWidgets('uses explicit listenable when provided', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('explicit'),
      );
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<String>(
            listenable: provider,
            dataBuilder: (_, data, ___) {
              capturedData = data;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedData, 'explicit');
    });

    testWidgets('reads listenable from context using ViewStateConsumer.of', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('context'),
      );
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateConsumer.of<TestViewStateNotifier<String>, String>(
              dataBuilder: (_, data, ___) {
                capturedData = data;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedData, 'context');
    });

    testWidgets(
      'switches to new listenable when listenable parameter changes',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));
        String? capturedData;
        int listenerCount1 = 0;
        int listenerCount2 = 0;

        Widget buildFrame(TestViewStateNotifier<String> provider) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateConsumer<String>(
              listenable: provider,
              dataBuilder: (_, data, __) {
                capturedData = data;
                return const SizedBox();
              },
              dataStateListener: (_, data) {
                if (provider == provider1) {
                  listenerCount1++;
                } else if (provider == provider2) {
                  listenerCount2++;
                }
              },
            ),
          );
        }

        await tester.pumpWidget(buildFrame(provider1));
        expect(capturedData, 'one');

        // Trigger listener for provider1
        provider1.emit(const DataState('one-new'));
        await tester.pump();
        expect(listenerCount1, 1);

        // Switch to provider2
        await tester.pumpWidget(buildFrame(provider2));
        expect(capturedData, 'two');

        // Listener for provider2 not called yet
        expect(listenerCount2, 0);

        // Emit from provider2
        provider2.emit(const DataState('two-new'));
        await tester.pump();
        expect(listenerCount2, 1);

        // Emit from provider1 should no longer trigger
        provider1.emit(const DataState('three'));
        await tester.pump();
        expect(listenerCount1, 1); // unchanged
      },
    );

    // =======================================================================
    // SECTION 4: CLEANUP
    // =======================================================================

    testWidgets('detaches listener when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<String>(
            listenable: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =======================================================================
    // SECTION 5: DIAGNOSTICS
    // =======================================================================

    testWidgets('debugFillProperties includes all relevant properties', (
      tester,
    ) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateConsumer<String>(
        listenable: TestViewStateNotifier<String>(),
        dataBuilder: (_, __, ___) => const SizedBox(),
        initialBuilder: (_) => const SizedBox(),
        loadingBuilder: (_, __) => const SizedBox(),
        emptyBuilder: (_, __) => const SizedBox(),
        errorBuilder: (_, __) => const SizedBox(),
        initialStateListener: (_) {},
        loadingStateListener: (_, __) {},
        emptyStateListener: (_, __) {},
        errorStateListener: (_, __) {},
        dataStateListener: (_, __) {},
        rebuildWhen: (_, __) => true,
        listenWhen: (_, __) => true,
        callListenerOnInit: true,
        isSliver: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      // Inherited from StateConsumer
      expect(description.any((e) => e.contains('listenable')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
        description.any(
          (e) => e.contains('callListenerOnInit') && e.contains('true'),
        ),
        isTrue,
      );

      // Builder fields
      expect(description.any((e) => e.contains('initialBuilder')), isTrue);
      expect(description.any((e) => e.contains('loadingBuilder')), isTrue);
      expect(description.any((e) => e.contains('emptyBuilder')), isTrue);
      expect(description.any((e) => e.contains('errorBuilder')), isTrue);
      expect(description.any((e) => e.contains('dataBuilder')), isTrue);
      expect(
        description.any((e) => e.contains('isSliver') && e.contains('true')),
        isTrue,
      );
      expect(description.any((e) => e.contains('child')), isTrue);

      // Listener fields
      expect(
        description.any((e) => e.contains('initialStateListener')),
        isTrue,
      );
      expect(
        description.any((e) => e.contains('loadingStateListener')),
        isTrue,
      );
      expect(description.any((e) => e.contains('emptyStateListener')), isTrue);
      expect(description.any((e) => e.contains('errorStateListener')), isTrue);
      expect(description.any((e) => e.contains('dataStateListener')), isTrue);
    });
  });
}
