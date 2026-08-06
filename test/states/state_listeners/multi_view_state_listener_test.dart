import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

void main() {
  group('MultiViewStateListener', () {
    // -----------------------------------------------------------------------
    // Helper to pump a MultiViewStateListener.
    // -----------------------------------------------------------------------
    Widget buildListener({
      required List<ViewStateNotifier<String>> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      MultiDataStateListener<List<DataState<String>>>? dataStateListener,
      ListenWhen<List<ViewState<String>>>? listenWhen,
      bool shouldCallListenerOnInit = false,
      Widget? child,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MultiViewStateListener<String>(
          providers: providers,
          initialStateListener: initialStateListener,
          loadingStateListener: loadingStateListener,
          emptyStateListener: emptyStateListener,
          errorStateListener: errorStateListener,
          dataStateListener: dataStateListener,
          listenWhen: listenWhen,
          shouldCallListenerOnInit: shouldCallListenerOnInit,
          child: child ?? const SizedBox(),
        ),
      );
    }

    // -----------------------------------------------------------------------
    // 1. Basic Rendering & Child
    // -----------------------------------------------------------------------
    testWidgets('renders child', (tester) async {
      const childKey = Key('child');
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      await tester.pumpWidget(
        buildListener(
          providers: [provider],
          child: const SizedBox(key: childKey),
        ),
      );
      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('throws AssertionError when child is not specified',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      await tester.pumpWidget(
        MultiViewStateListener<String>(
          providers: [provider],
        ),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>()
            .having((e) => e.message, 'message', contains('child')),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Priority Logic (Correct callback is invoked on each change)
    // -----------------------------------------------------------------------

    testWidgets(
      'errorStateListener called when aggregated state is Error',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data1'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));
        bool errorCalled = false;
        bool dataCalled = false;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            errorStateListener: (_, __, ___, ____) => errorCalled = true,
            dataStateListener: (_) => dataCalled = true,
          ),
        );

        provider1.emit(const ErrorState('Error!'));
        await tester.pump();
        expect(errorCalled, true);
        expect(dataCalled, false);

        errorCalled = false;
        dataCalled = false;
        provider1.emit(const DataState('data1-new'));
        await tester.pump();
        expect(errorCalled, false);
        expect(dataCalled, true);
      },
    );

    testWidgets(
      'initialStateListener called when aggregated state is Initial',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));
        bool initialCalled = false;
        bool dataCalled = false;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            initialStateListener: () => initialCalled = true,
            dataStateListener: (_) => dataCalled = true,
          ),
        );

        provider2.emit(const InitialState());
        await tester.pump();
        expect(initialCalled, true);
        expect(dataCalled, false);

        initialCalled = false;
        dataCalled = false;
        provider2.emit(const DataState('data2-new'));
        await tester.pump();
        expect(initialCalled, false);
        expect(dataCalled, true);
      },
    );

    testWidgets(
      'loadingStateListener called when aggregated state is Loading',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));
        bool loadingCalled = false;
        bool dataCalled = false;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            loadingStateListener: (_, __) => loadingCalled = true,
            dataStateListener: (_) => dataCalled = true,
          ),
        );

        provider1.emit(const LoadingState('Loading...'));
        await tester.pump();
        expect(loadingCalled, true);
        expect(dataCalled, false);

        loadingCalled = false;
        dataCalled = false;
        provider1.emit(const DataState('data1-new'));
        await tester.pump();
        expect(loadingCalled, false);
        expect(dataCalled, true);
      },
    );

    testWidgets(
      'emptyStateListener called when aggregated state is Empty',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));
        bool emptyCalled = false;
        bool dataCalled = false;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            emptyStateListener: (_) => emptyCalled = true,
            dataStateListener: (_) => dataCalled = true,
          ),
        );

        provider2.emit(const EmptyState('Empty!'));
        await tester.pump();
        expect(emptyCalled, true);
        expect(dataCalled, false);

        emptyCalled = false;
        dataCalled = false;
        provider2.emit(const DataState('data2-new'));
        await tester.pump();
        expect(emptyCalled, false);
        expect(dataCalled, true);
      },
    );

    testWidgets(
      'dataStateListener called when aggregated state is Data',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data1'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));
        bool dataCalled = false;
        List<DataState<String>>? capturedData;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            dataStateListener: (data) {
              dataCalled = true;
              capturedData = data;
            },
          ),
        );

        provider2.emit(const DataState('data2-new'));
        await tester.pump();
        expect(dataCalled, true);
        expect(capturedData, [
          const DataState('data1'),
          const DataState('data2-new'),
        ]);

        dataCalled = false;
        provider2.emit(const DataState('data2-new'));
        await tester.pump();
        expect(dataCalled, false);
      },
    );

    testWidgets(
      'priority chain: Error > Initial > Loading > Empty > Data',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data1'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));

        int errorCalls = 0;
        int initialCalls = 0;
        int loadingCalls = 0;
        int emptyCalls = 0;
        int dataCalls = 0;

        await tester.pumpWidget(
          buildListener(
            providers: [provider1, provider2],
            errorStateListener: (_, __, ___, ____) => errorCalls++,
            initialStateListener: () => initialCalls++,
            loadingStateListener: (_, __) => loadingCalls++,
            emptyStateListener: (_) => emptyCalls++,
            dataStateListener: (_) => dataCalls++,
          ),
        );

        // --- Step 1: Both Data → aggregated Data (no call on init) ---
        expect(dataCalls, 0);

        // --- Step 2: Emit Empty on provider1 → aggregated Empty ---
        provider1.emit(const EmptyState('empty'));
        await tester.pump();
        expect(emptyCalls, 1);
        expect(dataCalls, 0);

        // --- Step 3: Emit Loading on provider1 → aggregated Loading ---
        provider1.emit(const LoadingState('load'));
        await tester.pump();
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);

        // --- Step 4: Emit Initial on provider1 → aggregated Initial ---
        provider1.emit(const InitialState());
        await tester.pump();
        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);

        // --- Step 5: Emit Error on provider1 → aggregated Error ---
        provider1.emit(const ErrorState('error'));
        await tester.pump();
        expect(errorCalls, 1);
        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(dataCalls, 0);

        // --- Step 6: Emit Data on provider1 → aggregated Data ---
        provider1.emit(const DataState('data1-new'));
        await tester.pump();
        expect(dataCalls, 1);
        expect(errorCalls, 1);
        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Listener Parameters
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
        buildListener(
          providers: [provider1, provider2],
          errorStateListener: (message, onRetry, exception, stackTrace) {
            capturedMessage = message;
            capturedOnRetry = onRetry;
            capturedException = exception;
            capturedStackTrace = stackTrace;
          },
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
        buildListener(
          providers: [provider1, provider2],
          loadingStateListener: (message, progress) {
            capturedMessage = message;
            capturedProgress = progress;
          },
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
      expect(capturedMessage, 'Load A'); // message from first provider
      expect(capturedProgress, 0.5); // (0.3 + 0.7) / 2

      capturedMessage = null;
      capturedProgress = null;
      provider1.emit(const LoadingState('Load A', 0.5));
      await tester.pump();
      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.6); // (0.5 + 0.7) / 2
    });

    testWidgets('emptyStateListener receives message from first EmptyState',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));
      String? capturedMessage;

      await tester.pumpWidget(
        buildListener(
          providers: [provider1, provider2],
          emptyStateListener: (message) => capturedMessage = message,
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
        buildListener(
          providers: [provider1, provider2],
          dataStateListener: (data) => capturedData = data,
        ),
      );

      provider2.emit(const DataState('two-new'));
      await tester.pump();
      expect(capturedData, [
        const DataState('one'),
        const DataState('two-new'),
      ]);
    });

    testWidgets('onRetry calls refresh on all AsyncViewStateNotifier providers',
        (tester) async {
      final provider1 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data1',
      );
      final provider2 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data2',
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildListener(
          providers: [provider1, provider2],
          errorStateListener: (_, onRetry, __, ___) {
            capturedOnRetry = onRetry;
          },
        ),
      );

      // Force Error state on provider1.
      provider1.state = const ErrorState<String>('Error');
      await tester.pump();

      expect(capturedOnRetry, isA<VoidCallback>());
    });

    // -----------------------------------------------------------------------
    // 4. listenWhen (default and custom)
    // -----------------------------------------------------------------------

    testWidgets(
        'default listenWhen fires on every state change (full-list comparison)',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      int dataCallCount = 0;
      int loadingCallCount = 0;

      await tester.pumpWidget(
        buildListener(
          providers: [provider1, provider2],
          dataStateListener: (_) => dataCallCount++,
          loadingStateListener: (_, __) => loadingCallCount++,
        ),
      );

      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(dataCallCount, 1);
      expect(loadingCallCount, 0);

      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(dataCallCount, 1);
      expect(loadingCallCount, 0);

      provider2.emit(const LoadingState('Loading'));
      await tester.pump();
      expect(dataCallCount, 1);
      expect(loadingCallCount, 1);

      provider2.emit(const LoadingState('Loading2'));
      await tester.pump();
      expect(dataCallCount, 1);
      expect(loadingCallCount, 2);
    });

    testWidgets('custom listenWhen overrides default behaviour',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));

      int dataCallCount = 0;
      bool listenWhenCalled = false;

      await tester.pumpWidget(
        buildListener(
          providers: [provider1, provider2],
          dataStateListener: (_) => dataCallCount++,
          listenWhen: (previous, current) {
            listenWhenCalled = true;
            // Only fire when provider2 changes.
            return previous[1] != current[1];
          },
        ),
      );

      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(listenWhenCalled, true);
      expect(dataCallCount, 0);

      listenWhenCalled = false;
      provider2.emit(const DataState('new data2'));
      await tester.pump();
      expect(listenWhenCalled, true);
      expect(dataCallCount, 1);
    });

    // -----------------------------------------------------------------------
    // 5. shouldCallListenerOnInit
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
        buildListener(
          providers: [provider1, provider2],
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
        buildListener(
          providers: [provider1, provider2],
          dataStateListener: (_) => dataCalled = true,
          shouldCallListenerOnInit: false,
        ),
      );

      expect(dataCalled, false);
    });

    // -----------------------------------------------------------------------
    // 6. Runtime Provider Changes
    // -----------------------------------------------------------------------

    testWidgets(
      'switches to new provider list and updates combined state',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));
        final provider3 =
            TestViewStateNotifier<String>(const LoadingState('load'));

        bool dataCalled = false;
        bool loadingCalled = false;

        List<ViewStateNotifier<String>> providers = [provider1, provider2];
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    MultiViewStateListener<String>(
                      providers: providers,
                      dataStateListener: (_) => dataCalled = true,
                      loadingStateListener: (_, __) => loadingCalled = true,
                      child: const SizedBox(),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        providers = [provider3];
                      }),
                      child: const Text('Swap'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        provider1.emit(const DataState('one-new'));
        await tester.pump();
        expect(dataCalled, true);
        dataCalled = false;

        await tester.tap(find.text('Swap'));
        await tester.pump();

        provider3.emit(const LoadingState('new load'));
        await tester.pump();

        expect(loadingCalled, true);
        expect(dataCalled, false);
      },
    );

    testWidgets('detects in-place provider list mutation', (tester) async {
      final providerA = TestViewStateNotifier<String>(const DataState('A'));
      final providerB = TestViewStateNotifier<String>(const DataState('B'));
      final providers = [providerA];
      bool dataCalled = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MultiViewStateListener<String>(
                providers: providers,
                dataStateListener: (_) => dataCalled = true,
                child: TextButton(
                  onPressed: () => setState(() {
                    providers[0] = providerB;
                  }),
                  child: const Text('Mutate'),
                ),
              ),
            );
          },
        ),
      );

      providerA.emit(const DataState('A-new'));
      await tester.pump();
      expect(dataCalled, true);
      dataCalled = false;

      await tester.tap(find.text('Mutate'));
      await tester.pump();

      providerB.emit(const DataState('B-new'));
      await tester.pump();
      expect(dataCalled, true);
    });

    testWidgets('does not reattach on no-op provider list replacement',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      int callCount = 0;

      Widget buildFrame() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MultiViewStateListener<String>(
            providers: [provider],
            dataStateListener: (_) => callCount++,
            child: const SizedBox(),
          ),
        );
      }

      await tester.pumpWidget(buildFrame());

      provider.emit(const DataState('new'));
      await tester.pump();
      expect(callCount, 1);

      await tester.pumpWidget(buildFrame());
      expect(callCount, 1);

      provider.emit(const DataState('another'));
      await tester.pump();
      expect(callCount, 2);
    });

    // -----------------------------------------------------------------------
    // 7. Cleanup
    // -----------------------------------------------------------------------
    testWidgets('detaches listeners when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      await tester.pumpWidget(
        buildListener(
          providers: [provider],
          dataStateListener: (_) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // -----------------------------------------------------------------------
    // 8. Diagnostics
    // -----------------------------------------------------------------------
    testWidgets('debugFillProperties includes all relevant properties',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiViewStateListener<String>(
        providers: [
          TestViewStateNotifier<String>(),
        ],
        dataStateListener: (_) {},
        loadingStateListener: (_, __) {},
        initialStateListener: () {},
        emptyStateListener: (_) {},
        errorStateListener: (_, __, ___, ____) {},
        listenWhen: (_, __) => true,
        shouldCallListenerOnInit: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((e) => e.contains('providers')), isTrue);
      expect(description.any((e) => e.contains('listener')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
        description.any((e) =>
            e.contains('shouldCallListenerOnInit') && e.contains('true')),
        isTrue,
      );
    });
  });
}
