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
    // -----------------------------------------------------------------------
    // Helper to pump a MultiViewStateConsumer.
    // -----------------------------------------------------------------------
    Widget buildConsumer({
      required List<ViewStateNotifier<String>> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required MultiDataStateBuilder<List<DataState<String>>> dataBuilder,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<List<DataState<String>>>? dataStateListener,
      RebuildWhen<List<ViewState<String>>>? rebuildWhen,
      ListenWhen<List<ViewState<String>>>? listenWhen,
      bool shouldCallListenerOnInit = false,
      bool isSliver = false,
      bool withDefaultProvider = true,
    }) {
      final consumer = MultiViewStateConsumer<String>(
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
        shouldCallListenerOnInit: shouldCallListenerOnInit,
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
          providers: [provider],
          dataBuilder: (_) {
            built = true;
            return const SizedBox();
          },
        ),
      );

      expect(built, true);
    });

    // -----------------------------------------------------------------------
    // 2. Priority Logic (Builder and Listener)
    // -----------------------------------------------------------------------
    testWidgets(
      'priority chain: Error > Initial > Loading > Empty > Data (builder and listener)',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data1'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));

        bool errorBuilt = false;
        bool initialBuilt = false;
        bool loadingBuilt = false;
        bool emptyBuilt = false;
        bool dataBuilt = false;

        int errorListenerCalls = 0;
        int initialListenerCalls = 0;
        int loadingListenerCalls = 0;
        int emptyListenerCalls = 0;
        int dataListenerCalls = 0;

        await tester.pumpWidget(
          buildConsumer(
            providers: [provider1, provider2],
            errorBuilder: (_, __, ___, ____, _____) {
              errorBuilt = true;
              return const SizedBox();
            },
            initialBuilder: (_) {
              initialBuilt = true;
              return const SizedBox();
            },
            loadingBuilder: (_, __, ___) {
              loadingBuilt = true;
              return const SizedBox();
            },
            emptyBuilder: (_, __) {
              emptyBuilt = true;
              return const SizedBox();
            },
            dataBuilder: (_) {
              dataBuilt = true;
              return const SizedBox();
            },
            errorStateListener: (_, __, ___, ____) => errorListenerCalls++,
            initialStateListener: () => initialListenerCalls++,
            loadingStateListener: (_, __) => loadingListenerCalls++,
            emptyStateListener: (_) => emptyListenerCalls++,
            dataStateListener: (_) => dataListenerCalls++,
          ),
        );

        expect(dataBuilt, true);
        expect(dataListenerCalls, 0);

        dataBuilt = false;

        provider1.emit(const EmptyState('empty'));
        await tester.pump();
        expect(emptyBuilt, true);
        expect(dataBuilt, false);
        expect(emptyListenerCalls, 1);
        expect(dataListenerCalls, 0);

        emptyBuilt = false;

        provider1.emit(const LoadingState('load'));
        await tester.pump();
        expect(loadingBuilt, true);
        expect(emptyBuilt, false);
        expect(loadingListenerCalls, 1);
        expect(emptyListenerCalls, 1);

        loadingBuilt = false;

        provider1.emit(const InitialState());
        await tester.pump();
        expect(initialBuilt, true);
        expect(loadingBuilt, false);
        expect(initialListenerCalls, 1);
        expect(loadingListenerCalls, 1);
        expect(emptyListenerCalls, 1);

        initialBuilt = false;

        provider1.emit(const ErrorState('error'));
        await tester.pump();
        expect(errorBuilt, true);
        expect(initialBuilt, false);
        expect(errorListenerCalls, 1);
        expect(initialListenerCalls, 1);
        expect(loadingListenerCalls, 1);
        expect(emptyListenerCalls, 1);
        expect(dataListenerCalls, 0);

        errorBuilt = false;
        dataBuilt = false;

        provider1.emit(const DataState('data1-new'));
        await tester.pump();
        expect(dataBuilt, true);
        expect(errorBuilt, false);
        expect(dataListenerCalls, 1);
        expect(errorListenerCalls, 1);
        expect(initialListenerCalls, 1);
        expect(loadingListenerCalls, 1);
        expect(emptyListenerCalls, 1);
      },
    );
    // -----------------------------------------------------------------------
    // 3. Builder Parameters
    // -----------------------------------------------------------------------
    testWidgets('errorBuilder receives correct parameters', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('dummy'));
      final provider2 =
          TestViewStateNotifier<String>(const ErrorState('Error!'));

      String? capturedMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
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

      expect(capturedMessage, 'Error!');
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedException, isNull);
      expect(capturedStackTrace, isNull);
      expect(capturedIsSliver, true);
    });

    testWidgets('loadingBuilder receives message and combined progress',
        (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('Load A', 0.3));
      final provider2 =
          TestViewStateNotifier<String>(const LoadingState('Load B', 0.7));

      String? capturedMessage;
      double? capturedProgress;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
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
      expect(capturedIsSliver, true);
    });

    testWidgets('emptyBuilder receives message', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('Empty A'));
      final provider2 =
          TestViewStateNotifier<String>(const EmptyState('Empty B'));

      String? capturedMessage;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
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
      expect(capturedIsSliver, true);
    });

    testWidgets('dataBuilder receives list of DataStates in order',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));
      List<DataState<String>>? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (data) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, [
        const DataState('one'),
        const DataState('two'),
      ]);
    });

    // -----------------------------------------------------------------------
    // 4. Listener Parameters
    // -----------------------------------------------------------------------
    testWidgets('errorStateListener receives correct parameters',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('dummy'));
      final provider2 =
          TestViewStateNotifier<String>(const DataState('dummy2'));
      final exception = Exception('Test error');
      final stackTrace = StackTrace.current;
      String? capturedMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          errorStateListener: (message, onRetry, exception, stackTrace) {
            capturedMessage = message;
            capturedOnRetry = onRetry;
            capturedException = exception;
            capturedStackTrace = stackTrace;
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider1.emit(ErrorState<String>('Error!', exception, stackTrace, null));
      await tester.pump();

      expect(capturedMessage, 'Error!');
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedException, exception);
      expect(capturedStackTrace, stackTrace);
    });

    testWidgets('loadingStateListener receives message and combined progress',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
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

    testWidgets('emptyStateListener receives message from first EmptyState',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));
      String? capturedMessage;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          emptyStateListener: (message) => capturedMessage = message,
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

    testWidgets('dataStateListener receives list of DataStates in order',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));
      List<DataState<String>>? capturedData;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataStateListener: (data) => capturedData = data,
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider2.emit(const DataState('two-new'));
      await tester.pump();
      expect(capturedData, [
        const DataState('one'),
        const DataState('two-new'),
      ]);
    });

    testWidgets(
      'does not provide onRetry when no provider is in ErrorState',
      (tester) async {
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
            providers: [provider1, provider2],
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedBuilderRetry = onRetry;
              return const SizedBox();
            },
            errorStateListener: (_, onRetry, __, ___) {
              capturedListenerRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        expect(capturedBuilderRetry, isNull);
        expect(capturedListenerRetry, isNull);

        expect(provider1.refreshCalls, 0);
        expect(provider2.refreshCalls, 0);
      },
    );

    testWidgets(
      'builder onRetry refreshes providers in ErrorState',
      (tester) async {
        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: [provider],
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.state = const ErrorState<String>('Error');
        await tester.pump();

        expect(capturedOnRetry, isA<VoidCallback>());

        capturedOnRetry!();

        expect(provider.refreshCalls, 1);
      },
    );

    testWidgets(
      'listener onRetry refreshes providers in ErrorState',
      (tester) async {
        final provider = MockAsyncViewStateNotifier<String>(
          fetchDataImpl: () => 'data',
        );

        await tester.pumpAndSettle();

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: [provider],
            errorStateListener: (_, onRetry, __, ___) {
              capturedOnRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.state = const ErrorState<String>('Error');
        await tester.pump();

        expect(capturedOnRetry, isA<VoidCallback>());

        capturedOnRetry!();

        expect(provider.refreshCalls, 1);
      },
    );

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
            providers: [provider],
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedBuilderRetry = onRetry;
              return const SizedBox();
            },
            errorStateListener: (_, onRetry, __, ___) {
              capturedListenerRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        );

        provider.state = ErrorState<String>(
          'Error',
          null,
          null,
          () => retryCalls++,
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


    // -----------------------------------------------------------------------
    // 5. rebuildWhen and listenWhen
    // -----------------------------------------------------------------------
    testWidgets(
        'rebuildWhen controls builder; listenWhen controls listener independently',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      int buildCount = 0;
      int listenerCount = 0;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) {
            buildCount++;
            return const SizedBox();
          },
          dataStateListener: (_) => listenerCount++,
          rebuildWhen: (_, __) => false, // never rebuild
          listenWhen: (_, __) => true, // always listen
        ),
      );

      expect(buildCount, 1);
      expect(listenerCount, 0);

      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(buildCount, 1); // no rebuild
      expect(listenerCount, 1); // listener fires
    });

    // -----------------------------------------------------------------------
    // 6. shouldCallListenerOnInit
    // -----------------------------------------------------------------------
    testWidgets(
        'shouldCallListenerOnInit calls listener with combined initial state',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('init1'));
      final provider2 =
          TestViewStateNotifier<String>(const LoadingState('init load'));
      bool dataCalled = false;
      bool loadingCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) => dataCalled = true,
          loadingStateListener: (_, __) => loadingCalled = true,
          shouldCallListenerOnInit: true,
        ),
      );

      expect(loadingCalled, true);
      expect(dataCalled, false);
    });

    testWidgets('shouldCallListenerOnInit false does not call on init',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('init1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('init2'));
      bool dataCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) => dataCalled = true,
          shouldCallListenerOnInit: false,
        ),
      );

      expect(dataCalled, false);
    });

    // -----------------------------------------------------------------------
    // 7. Fallback to ViewStateWidgetsProvider (builder)
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const InitialState());
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('load'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('empty'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const ErrorState('error'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 8. isSliver flag propagation
    // -----------------------------------------------------------------------
    testWidgets('passes isSliver flag to errorBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const ErrorState('error'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          errorBuilder: (_, __, ___, ____, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    testWidgets('passes isSliver flag to loadingBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('load'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          loadingBuilder: (_, __, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    testWidgets('passes isSliver flag to emptyBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('empty'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider1, provider2],
          emptyBuilder: (_, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    testWidgets('default widgets from provider receive isSliver',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const LoadingState('load'));
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
            child: MultiViewStateConsumer<String>(
              providers: [provider],
              isSliver: true,
              dataBuilder: (_) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(isSliverPassed, true);
    });

    // -----------------------------------------------------------------------
    // 9. Runtime Provider List Transitions
    // -----------------------------------------------------------------------
    testWidgets(
      'updates to new provider list when providers change',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));
        final provider3 =
            TestViewStateNotifier<String>(const DataState('three'));

        List<ViewStateNotifier<String>> providers = [provider1, provider2];
        String? capturedData;
        bool listenerCalled = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MultiViewStateConsumer<String>(
                  providers: providers,
                  dataBuilder: (data) {
                    capturedData = data[0].data;
                    return const SizedBox();
                  },
                  dataStateListener: (_) => listenerCalled = true,
                ),
              );
            },
          ),
        );

        expect(capturedData, 'one');

        provider1.emit(const DataState('one-new'));
        await tester.pump();
        expect(capturedData, 'one-new');
        expect(listenerCalled, true);

        listenerCalled = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MultiViewStateConsumer<String>(
                  providers: [provider3],
                  dataBuilder: (data) {
                    capturedData = data[0].data;
                    return const SizedBox();
                  },
                  dataStateListener: (_) => listenerCalled = true,
                ),
              );
            },
          ),
        );
        await tester.pump();
        expect(capturedData, 'three');
        listenerCalled = false;
        provider3.emit(const DataState('three-new'));
        await tester.pump();
        expect(listenerCalled, true);
      },
    );

    testWidgets('detects in-place provider list mutation', (tester) async {
      final providerA = TestViewStateNotifier<String>(const DataState('A'));
      final providerB = TestViewStateNotifier<String>(const DataState('B'));
      final providers = [providerA];
      String? capturedData;
      bool listenerCalled = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MultiViewStateConsumer<String>(
                providers: providers,
                dataBuilder: (data) {
                  capturedData = data[0].data;
                  return const SizedBox();
                },
                dataStateListener: (_) => listenerCalled = true,
              ),
            );
          },
        ),
      );

      expect(capturedData, 'A');

      providers[0] = providerB;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MultiViewStateConsumer<String>(
                providers: providers,
                dataBuilder: (data) {
                  capturedData = data[0].data;
                  return const SizedBox();
                },
                dataStateListener: (_) => listenerCalled = true,
              ),
            );
          },
        ),
      );
      await tester.pump();
      expect(capturedData, 'B');

      listenerCalled = false;
      providerA.emit(const DataState('A-new'));
      await tester.pump();
      expect(capturedData, 'B');
      expect(listenerCalled, false);

      listenerCalled = false;
      providerB.emit(const DataState('B-new'));
      await tester.pump();
      expect(capturedData, 'B-new');
      expect(listenerCalled, true);
    });

    testWidgets(
        'parent rebuild with same providers causes builder rebuild (expected)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      int buildCount = 0;
      int listenerCount = 0;

      Widget buildFrame() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MultiViewStateConsumer<String>(
            providers: [provider],
            dataBuilder: (_) {
              buildCount++;
              return const SizedBox();
            },
            dataStateListener: (_) => listenerCount++,
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
    // 10. Cleanup
    // -----------------------------------------------------------------------
    testWidgets('detaches listeners when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        buildConsumer(
          providers: [provider],
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
    // 11. Diagnostics
    // -----------------------------------------------------------------------
    testWidgets('debugFillProperties includes all relevant properties',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiViewStateConsumer<String>(
        providers: [TestViewStateNotifier<String>(const DataState('data'))],
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

      expect(description.any((e) => e.contains('providers')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('initialBuilder')), isTrue);
      expect(description.any((e) => e.contains('loadingBuilder')), isTrue);
      expect(description.any((e) => e.contains('emptyBuilder')), isTrue);
      expect(description.any((e) => e.contains('errorBuilder')), isTrue);
      expect(description.any((e) => e.contains('dataBuilder')), isTrue);
      expect(
          description.any((e) => e.contains('isSliver') && e.contains('true')),
          isTrue);

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
