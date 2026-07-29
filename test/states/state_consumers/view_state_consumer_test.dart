import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

// -----------------------------------------------------------------------------
// Helper to provide default ViewStateWidgetsProvider keys once.
// -----------------------------------------------------------------------------
const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

Widget _withDefaultWidgetProvider(Widget child) {
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
      bool shouldCallListenerOnInit = false,
      bool isSliver = false,
      bool withDefaultWidgetProvider = true,
    }) {
      final consumer = ViewStateConsumer<TestViewStateNotifier<String>, String>(
        provider: provider,
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
        shouldCallListenerOnInit: shouldCallListenerOnInit,
        isSliver: isSliver,
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

    testWidgets('dataBuilder is required and called for DataState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('Hello'));
      String? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (data) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, 'Hello');
    });

    testWidgets('calls initialBuilder when state is InitialState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialBuilt = false;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          initialBuilder: (_) {
            initialBuilt = true;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(initialBuilt, true);
    });

    testWidgets('calls loadingBuilder with correct parameters', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const LoadingState('Loading', 0.7));
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          loadingBuilder: (message, progress, _) {
            capturedMessage = message;
            capturedProgress = progress;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'Loading');
      expect(capturedProgress, 0.7);
    });

    testWidgets('calls emptyBuilder with message', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const EmptyState('No data'));
      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          emptyBuilder: (message, _) {
            capturedMessage = message;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'No data');
    });

    testWidgets('calls errorBuilder with correct parameters', (tester) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(
            'Error', Exception('boom'), StackTrace.current, () {}),
      );
      String? capturedMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          errorBuilder: (message, onRetry, exception, stackTrace, isSliver) {
            capturedMessage = message;
            capturedOnRetry = onRetry;
            capturedException = exception;
            capturedStackTrace = stackTrace;
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedMessage, 'Error');
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedException, isA<Exception>());
      expect(capturedStackTrace, isNotNull);
      expect(capturedIsSliver, true);
    });

    // -----------------------------------------------------------------------
    // Fallback to ViewStateWidgetsProvider (builder)
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const EmptyState());

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(
          ErrorState<String>('Error', Exception(), StackTrace.current, null));

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultWidgetProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    testWidgets(
        'throws assertion when state is not DataState and no provider in context',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    // -----------------------------------------------------------------------
    // onRetry resolution (for builder)
    // -----------------------------------------------------------------------
    testWidgets(
        'errorBuilder receives onRetry from ProviderKit when not explicitly set',
        (tester) async {
      final exception = Exception('Test');
      final provider = MockProviderKit<String>(
        fetchDataImpl: () => throw exception,
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<MockProviderKit<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, provider.refresh);
    });

    testWidgets(
        'errorBuilder receives onRetry from ErrorState when explicitly set (overrides provider)',
        (tester) async {
      final provider = MockProviderKit<String>(
        fetchDataImpl: () => throw Exception('Test'),
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;
      void explicitOnRetry() {}

      provider.state = ErrorState<String>('Error', null, null, explicitOnRetry);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<MockProviderKit<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, explicitOnRetry);
    });

    testWidgets(
        'errorBuilder receives null onRetry when provider is not a ProviderKit',
        (tester) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>('Error', Exception(), StackTrace.current, null),
      );
      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, isNull);
    });

    // -----------------------------------------------------------------------
    // rebuildWhen (builder filtering)
    // -----------------------------------------------------------------------
    testWidgets('rebuildWhen controls whether builder is called',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int buildCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (data) {
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
          dataBuilder: (_) => const SizedBox(),
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

      provider.emit(const ErrorState<String>('error'));
      await tester.pump();

      expect(previousList.length, 3);
      expect(previousList[2], const DataState<String>('data'));
      expect(currentList[2], isA<ErrorState<String>>());
    });

    // -----------------------------------------------------------------------
    // isSliver flag propagation (builder)
    // -----------------------------------------------------------------------
    testWidgets(
        'passes isSliver flag to all builders (initial, loading, empty, error)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialIsSliver = false;
      bool loadingIsSliver = false;
      bool emptyIsSliver = false;
      bool errorIsSliver = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            isSliver: true,
            initialBuilder: (isSliver) {
              initialIsSliver = isSliver;
              return const SizedBox();
            },
            loadingBuilder: (_, __, isSliver) {
              loadingIsSliver = isSliver;
              return const SizedBox();
            },
            emptyBuilder: (_, isSliver) {
              emptyIsSliver = isSliver;
              return const SizedBox();
            },
            errorBuilder: (_, __, ___, ____, isSliver) {
              errorIsSliver = isSliver;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(initialIsSliver, true);

      provider.emit(const LoadingState<String>());
      await tester.pump();
      expect(loadingIsSliver, true);

      provider.emit(const EmptyState<String>());
      await tester.pump();
      expect(emptyIsSliver, true);

      provider.emit(const ErrorState<String>('Error', null, null, null));
      await tester.pump();
      expect(errorIsSliver, true);
    });

    testWidgets('default widgets from provider receive isSliver',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());
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
            child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
              provider: provider,
              isSliver: true,
              dataBuilder: (_) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(isSliverPassed, true);
    });

    // =======================================================================
    // SECTION 2: LISTENER TESTS (mirror ViewStateListener)
    // =======================================================================

    testWidgets('calls initialStateListener when state is InitialState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          initialStateListener: () => initialCalled = true,
          shouldCallListenerOnInit: true,
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
      'does not call listener on init when shouldCallListenerOnInit is false, but calls on state change',
      (tester) async {
        final provider =
            TestViewStateNotifier<String>(const DataState('initial'));
        bool initialCalled = false;

        await tester.pumpWidget(
          buildConsumer(
            provider: provider,
            dataBuilder: (_) => const SizedBox(),
            initialStateListener: () => initialCalled = true,
            shouldCallListenerOnInit: false,
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

    testWidgets('calls loadingStateListener with correct parameters',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          loadingStateListener: (message, progress) {
            capturedMessage = message;
            capturedProgress = progress;
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
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (data) => capturedData = data,
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
          dataBuilder: (_) => const SizedBox(),
          emptyStateListener: (message) => capturedMessage = message,
        ),
      );

      provider.emit(const EmptyState<String>('No items found'));
      await tester.pump();

      expect(capturedMessage, 'No items found');
    });

    testWidgets('calls errorStateListener with correct parameters',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedErrorMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;

      void onRetry() {}
      final exception = Exception('Test error');
      final stackTrace = StackTrace.current;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          errorStateListener: (errorMessage, onRetry, exception, stackTrace) {
            capturedErrorMessage = errorMessage;
            capturedOnRetry = onRetry;
            capturedException = exception;
            capturedStackTrace = stackTrace;
          },
        ),
      );

      provider.emit(ErrorState<String>(
        'Something went wrong',
        exception,
        stackTrace,
        onRetry,
      ));
      await tester.pump();

      expect(capturedErrorMessage, 'Something went wrong');
      expect(capturedOnRetry, onRetry);
      expect(capturedException, exception);
      expect(capturedStackTrace, stackTrace);
    });

    testWidgets('errorStateListener receives onRetry callback from ErrorState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      VoidCallback? capturedOnRetry;
      void expectedOnRetry() {}

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          errorStateListener: (_, onRetry, __, ___) {
            capturedOnRetry = onRetry;
          },
        ),
      );

      provider.emit(ErrorState<String>('error', null, null, expectedOnRetry));
      await tester.pump();
      expect(capturedOnRetry, expectedOnRetry);
    });

    testWidgets(
      'errorStateListener receives correct error details and refresh as onRetry when using ProviderKit',
      (tester) async {
        final exception = Exception('Test error');
        final provider = MockProviderKit<String>(
          fetchDataImpl: () => throw exception,
        );
        await tester.pumpAndSettle();

        expect(provider.state, isA<ErrorState<String>>());

        String? capturedErrorMessage;
        VoidCallback? capturedOnRetry;
        dynamic capturedException;
        StackTrace? capturedStackTrace;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: _withDefaultWidgetProvider(
              ViewStateConsumer<MockProviderKit<String>, String>(
                provider: provider,
                dataBuilder: (_) => const SizedBox(),
                errorStateListener:
                    (errorMessage, onRetry, exception, stackTrace) {
                  capturedErrorMessage = errorMessage;
                  capturedOnRetry = onRetry;
                  capturedException = exception;
                  capturedStackTrace = stackTrace;
                },
                shouldCallListenerOnInit: true,
              ),
            ),
          ),
        );

        expect(capturedErrorMessage, exception.toString());
        expect(capturedOnRetry, provider.refresh);
        expect(capturedStackTrace, isNotNull);
        expect(capturedException, isNotNull);
      },
    );

    testWidgets('does not call listener when emitting the same state twice',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int dataListenerCount = 0;
      int builderCallCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) {
            builderCallCount++;
            return const SizedBox();
          },
          dataStateListener: (_) => dataListenerCount++,
          shouldCallListenerOnInit: false,
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
      final provider = TestViewStateNotifier<String>(const InitialState());

      int initialListenerCount = 0;
      int loadingListenerCount = 0;
      int dataListenerCount = 0;
      int emptyListenerCount = 0;
      int errorListenerCount = 0;

      bool initialBuilt = false;
      bool loadingBuilt = false;
      bool dataBuilt = false;
      bool emptyBuilt = false;
      bool errorBuilt = false;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          // Builders
          initialBuilder: (_) {
            initialBuilt = true;
            return const SizedBox();
          },
          loadingBuilder: (_, __, ___) {
            loadingBuilt = true;
            return const SizedBox();
          },
          dataBuilder: (_) {
            dataBuilt = true;
            return const SizedBox();
          },
          emptyBuilder: (_, __) {
            emptyBuilt = true;
            return const SizedBox();
          },
          errorBuilder: (_, __, ___, ____, _____) {
            errorBuilt = true;
            return const SizedBox();
          },
          initialStateListener: () => initialListenerCount++,
          loadingStateListener: (_, __) => loadingListenerCount++,
          dataStateListener: (_) => dataListenerCount++,
          emptyStateListener: (_) => emptyListenerCount++,
          errorStateListener: (_, __, ___, ____) => errorListenerCount++,
          shouldCallListenerOnInit: false,
        ),
      );

      expect(initialBuilt, true);
      expect(initialListenerCount, 0);

      // ----- Transition to Loading -----
      provider.emit(const LoadingState<String>());
      await tester.pump();
      expect(loadingListenerCount, 1);
      expect(loadingBuilt, true);
      expect(initialListenerCount, 0);
      expect(dataListenerCount, 0);
      expect(emptyListenerCount, 0);
      expect(errorListenerCount, 0);
      expect(dataBuilt, false);
      expect(emptyBuilt, false);
      expect(errorBuilt, false);

      // ----- Transition to Data -----
      provider.emit(const DataState<String>('data'));
      await tester.pump();
      expect(dataListenerCount, 1);
      expect(dataBuilt, true);
      expect(loadingListenerCount, 1);
      expect(emptyListenerCount, 0);
      expect(errorListenerCount, 0);
      expect(loadingBuilt, true);
      expect(emptyBuilt, false);
      expect(errorBuilt, false);

      // ----- Transition to Empty -----
      provider.emit(const EmptyState<String>());
      await tester.pump();
      expect(emptyListenerCount, 1);
      expect(emptyBuilt, true);
      expect(dataListenerCount, 1);
      expect(loadingListenerCount, 1);
      expect(errorListenerCount, 0);
      expect(dataBuilt, true);
      expect(loadingBuilt, true);
      expect(errorBuilt, false);

      // ----- Transition to Error -----
      provider.emit(const ErrorState<String>('error'));
      await tester.pump();
      expect(errorListenerCount, 1);
      expect(errorBuilt, true);
      expect(emptyListenerCount, 1);
      expect(dataListenerCount, 1);
      expect(loadingListenerCount, 1);
      expect(emptyBuilt, true);
      expect(dataBuilt, true);
      expect(loadingBuilt, true);

      // ----- Transition back to Initial -----
      provider.emit(const InitialState());
      await tester.pump();
      expect(initialListenerCount, 1);
      expect(initialBuilt, true);
      expect(errorListenerCount, 1);
      expect(emptyListenerCount, 1);
      expect(dataListenerCount, 1);
      expect(loadingListenerCount, 1);
      expect(errorBuilt, true);
      expect(emptyBuilt, true);
      expect(dataBuilt, true);
      expect(loadingBuilt, true);
    });

    testWidgets('shouldCallListenerOnInit calls matching listener on init',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int dataCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) => dataCount++,
          shouldCallListenerOnInit: true,
        ),
      );

      expect(dataCount, 1);

      provider.emit(const DataState<String>('new data'));
      await tester.pump();
      expect(dataCount, 2);
    });

    testWidgets('shouldCallListenerOnInit false does not call on init',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int dataCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) => dataCount++,
          shouldCallListenerOnInit: false,
        ),
      );

      expect(dataCount, 0);

      provider.emit(const DataState<String>('new'));
      await tester.pump();
      expect(dataCount, 1);
    });

    testWidgets('listenWhen controls whether listener callbacks are triggered',
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
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) => dataCount++,
          listenWhen: listenWhen,
          shouldCallListenerOnInit: false,
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
    });

    testWidgets(
        'listenWhen receives correct previous and current ViewState objects',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      List<ViewState<String>> previousList = [];
      List<ViewState<String>> currentList = [];

      await tester.pumpWidget(
        buildConsumer(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) {},
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
    });

    // -----------------------------------------------------------------------
    // Safe to trigger side effects (deferred execution)
    // -----------------------------------------------------------------------
    testWidgets('safe to trigger dialogs inside listener (deferred)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: _withDefaultWidgetProvider(
                  ViewStateConsumer<TestViewStateNotifier<String>, String>(
                    provider: provider,
                    dataBuilder: (_) => const SizedBox(),
                    dataStateListener: (data) {
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

    testWidgets('does not crash when state occurs without matching callback',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _withDefaultWidgetProvider(
            ViewStateConsumer<TestViewStateNotifier<String>, String>(
              provider: provider,
              dataBuilder: (_) => const SizedBox(),
              dataStateListener: (_) {},
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

    testWidgets('uses explicit provider when provided', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('explicit'));
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (data) {
              capturedData = data;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedData, 'explicit');
    });

    testWidgets('reads provider from context when not provided',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('context'));
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
              dataBuilder: (data) {
                capturedData = data;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedData, 'context');
    });

    testWidgets('switches to new provider when provider parameter changes',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));
      String? capturedData;
      int listenerCount1 = 0;
      int listenerCount2 = 0;

      Widget buildFrame(TestViewStateNotifier<String>? provider) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (data) {
              capturedData = data;
              return const SizedBox();
            },
            dataStateListener: (data) {
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
    });

    // =======================================================================
    // SECTION 4: CLEANUP
    // =======================================================================

    testWidgets('detaches listener when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateConsumer<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (_) => const SizedBox(),
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

    testWidgets('debugFillProperties includes all relevant properties',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateConsumer<TestViewStateNotifier<String>, String>(
        provider: TestViewStateNotifier<String>(),
        dataBuilder: (_) => const SizedBox(),
        initialBuilder: (_) => const SizedBox(),
        loadingBuilder: (_, __, ___) => const SizedBox(),
        emptyBuilder: (_, __) => const SizedBox(),
        errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
        initialStateListener: () {},
        loadingStateListener: (_, __) {},
        emptyStateListener: (_) {},
        errorStateListener: (_, __, ___, ____) {},
        dataStateListener: (_) {},
        rebuildWhen: (_, __) => true,
        listenWhen: (_, __) => true,
        shouldCallListenerOnInit: true,
        isSliver: true,
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      // Inherited from StateConsumer
      expect(description.any((e) => e.contains('provider')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
        description.any((e) =>
            e.contains('shouldCallListenerOnInit') && e.contains('true')),
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
          isTrue);

      // Listener fields
      expect(
          description.any((e) => e.contains('initialStateListener')), isTrue);
      expect(
          description.any((e) => e.contains('loadingStateListener')), isTrue);
      expect(description.any((e) => e.contains('emptyStateListener')), isTrue);
      expect(description.any((e) => e.contains('errorStateListener')), isTrue);
      expect(description.any((e) => e.contains('dataStateListener')), isTrue);
    });
  });
}
