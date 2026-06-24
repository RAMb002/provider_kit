import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

void main() {
  group('ViewStateListener', () {
    testWidgets('renders child', (tester) async {
      const childKey = Key('child');
      final provider = TestViewStateNotifier<String>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            child: const SizedBox(key: childKey),
          ),
        ),
      );
      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('throws AssertionError when child is not specified',
        (tester) async {
      final provider = TestViewStateNotifier<String>();

      await tester.pumpWidget(
        ViewStateListener<TestViewStateNotifier<String>, String>(
          provider: provider,
        ),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>()
            .having((e) => e.message, 'message', contains('child')),
      );
    });

    Widget buildListener({
      required TestViewStateNotifier<String> provider,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<String>? dataStateListener,
      ListenWhen<ViewState<String>>? listenWhen,
      bool shouldCallListenerOnInit = false,
      Widget? child,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ViewStateListener<TestViewStateNotifier<String>, String>(
          provider: provider,
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

    testWidgets('calls initialStateListener when state is InitialState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialCalled = false;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          initialStateListener: () => initialCalled = true,
          shouldCallListenerOnInit: true,
        ),
      );

      expect(initialCalled, true);

      initialCalled = false;
      provider.emit(const DataState<String>('data'));
      await tester.pump();
      expect(initialCalled, false);

      // Now change to InitialState
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
          buildListener(
            provider: provider,
            initialStateListener: () => initialCalled = true,
            shouldCallListenerOnInit: false,
          ),
        );

        expect(initialCalled, false);

        provider.emit(const LoadingState<String>());
        await tester.pump();
        expect(initialCalled, false); // still not called

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
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
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

    testWidgets('does not call listener when emitting the same state twice',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      int dataCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          dataStateListener: (_) => dataCount++,
          shouldCallListenerOnInit: false,
        ),
      );

      provider.emit(const DataState<String>('same'));
      await tester.pump();
      expect(dataCount, 1);

      provider.emit(const DataState<String>('same')); // same state
      await tester.pump();
      expect(dataCount, 1); // no second call
    });

    testWidgets('only the matching callback is called for each state',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      int initialCount = 0;
      int loadingCount = 0;
      int dataCount = 0;
      int emptyCount = 0;
      int errorCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          initialStateListener: () => initialCount++,
          loadingStateListener: (_, __) => loadingCount++,
          dataStateListener: (_) => dataCount++,
          emptyStateListener: (_) => emptyCount++,
          errorStateListener: (_, __, ___, ____) => errorCount++,
          shouldCallListenerOnInit: false,
        ),
      );

      provider.emit(const LoadingState<String>());
      await tester.pump();
      expect(loadingCount, 1);
      expect(initialCount, 0);
      expect(dataCount, 0);
      expect(emptyCount, 0);
      expect(errorCount, 0);

      provider.emit(const DataState<String>('data'));
      await tester.pump();
      expect(dataCount, 1);
      expect(loadingCount, 1);
      // others remain 0

      provider.emit(const EmptyState<String>());
      await tester.pump();
      expect(emptyCount, 1);
      expect(dataCount, 1);
      expect(loadingCount, 1);

      provider.emit(const ErrorState<String>('error'));
      await tester.pump();
      expect(errorCount, 1);
      expect(emptyCount, 1);
      expect(dataCount, 1);
      expect(loadingCount, 1);

      provider.emit(const InitialState());
      await tester.pump();
      expect(initialCount, 1);
      expect(errorCount, 1);
      expect(emptyCount, 1);
      expect(dataCount, 1);
      expect(loadingCount, 1);
    });

    testWidgets('listenWhen controls whether callbacks are triggered',
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
        buildListener(
          provider: provider,
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

    testWidgets('shouldCallListenerOnInit calls matching callback on init',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int dataCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
          dataStateListener: (_) => dataCount++,
          shouldCallListenerOnInit: false,
        ),
      );

      expect(dataCount, 0);

      provider.emit(const DataState<String>('new'));
      await tester.pump();
      expect(dataCount, 1);
    });

    testWidgets('safe to trigger dialogs inside listener (deferred)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ViewStateListener<TestViewStateNotifier<String>, String>(
                  provider: provider,
                  dataStateListener: (data) {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          const AlertDialog(title: Text('Data loaded')),
                    );
                  },
                  child: const SizedBox(),
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

    testWidgets('uses explicit provider when provided', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool dataCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataStateListener: (_) => dataCalled = true,
            child: const SizedBox(),
          ),
        ),
      );

      provider.emit(const DataState<String>('test'));
      await tester.pump();
      expect(dataCalled, true);
    });

    testWidgets('reads provider from context when not provided',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool dataCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateListener<TestViewStateNotifier<String>, String>(
              // no provider, uses context.read
              dataStateListener: (_) => dataCalled = true,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      provider.emit(const DataState<String>('test'));
      await tester.pump();
      expect(dataCalled, true);
    });

    testWidgets('detaches listener when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataStateListener: (_) {},
            child: const SizedBox(),
          ),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    testWidgets(
        'switches to new provider when provider parameter changes at runtime',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const InitialState());
      final provider2 = TestViewStateNotifier<String>(const InitialState());
      int dataCount1 = 0;
      int dataCount2 = 0;

      Widget buildFrame(TestViewStateNotifier<String>? provider) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataStateListener: (data) {
              if (provider == provider1) {
                dataCount1++;
              } else if (provider == provider2) {
                dataCount2++;
              }
            },
            child: const SizedBox(),
          ),
        );
      }

      // Start with provider1
      await tester.pumpWidget(buildFrame(provider1));
      provider1.emit(const DataState<String>('a'));
      await tester.pump();
      expect(dataCount1, 1);
      expect(dataCount2, 0);

      // Switch to provider2
      await tester.pumpWidget(buildFrame(provider2));
      // No state change yet, so counts unchanged
      expect(dataCount1, 1);
      expect(dataCount2, 0);

      // Emit from provider2
      provider2.emit(const DataState<String>('b'));
      await tester.pump();
      expect(dataCount1, 1);
      expect(dataCount2, 1);

      // Emit from provider1 should no longer trigger (detached)
      provider1.emit(const DataState<String>('c'));
      await tester.pump();
      expect(dataCount1, 1); // unchanged
      expect(dataCount2, 1);
    });

    testWidgets(
        'listenWhen receives correct previous and current ViewState objects',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      List<ViewState<String>> previousList = [];
      List<ViewState<String>> currentList = [];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            listenWhen: (previous, current) {
              previousList.add(previous);
              currentList.add(current);
              return true;
            },
            dataStateListener: (_) {},
            child: const SizedBox(),
          ),
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

    testWidgets('errorStateListener receives onRetry callback', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      VoidCallback? capturedOnRetry;
      void expectedOnRetry() {}

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            errorStateListener: (_, onRetry, __, ___) {
              capturedOnRetry = onRetry;
            },
            child: const SizedBox(),
          ),
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
            child: ViewStateListener<MockProviderKit<String>, String>(
              provider: provider,
              errorStateListener:
                  (errorMessage, onRetry, exception, stackTrace) {
                capturedErrorMessage = errorMessage;
                capturedOnRetry = onRetry;
                capturedException = exception;
                capturedStackTrace = stackTrace;
              },
              shouldCallListenerOnInit: true,
              child: const SizedBox(),
            ),
          ),
        );

        expect(capturedErrorMessage, exception.toString());
        expect(capturedOnRetry, provider.refresh);
        expect(capturedStackTrace, isNotNull);
        expect(capturedException, isNotNull);
      },
    );

    testWidgets('does not crash when state occurs without matching callback',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      // Only provide dataStateListener, but we will emit LoadingState
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataStateListener: (_) {},
            child: const SizedBox(),
          ),
        ),
      );

      provider.emit(const LoadingState<String>());
      await tester.pump();
    });

    // -----------------------------------------------------------------------
    // 9. Diagnostics
    // -----------------------------------------------------------------------
    testWidgets('debugFillProperties includes all relevant properties',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateListener<TestViewStateNotifier<String>, String>(
        provider: TestViewStateNotifier<String>(),
        dataStateListener: (_) {},
        loadingStateListener: (_, __) {},
        emptyStateListener: (_) {},
        errorStateListener: (_, __, ___, ____) {},
        initialStateListener: () {},
        listenWhen: (_, __) => true,
        shouldCallListenerOnInit: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((e) => e.contains('provider')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
        description.any((e) =>
            e.contains('shouldCallListenerOnInit') && e.contains('true')),
        isTrue,
      );

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
