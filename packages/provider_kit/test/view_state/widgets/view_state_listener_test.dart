import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/future_notifier.dart';
import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

void main() {
  group('ViewStateListener', () {
    testWidgets('renders child', (tester) async {
      const childKey = Key('child');
      final provider = TestViewStateNotifier<String>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<String>(
            listenable: provider,
            child: const SizedBox(key: childKey),
          ),
        ),
      );
      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>();

      await tester.pumpWidget(ViewStateListener<String>(listenable: provider));
      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('child'),
        ),
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
      bool callListenerOnInit = false,
      Widget? child,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: ViewStateListener<String>(
          listenable: provider,
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

    testWidgets('calls initialStateListener when state is InitialState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialCalled = false;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          initialStateListener: (_) => initialCalled = true,
          callListenerOnInit: true,
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
      'does not call listener on init when callListenerOnInit is false, but calls on state change',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState('initial'),
        );
        bool initialCalled = false;

        await tester.pumpWidget(
          buildListener(
            provider: provider,
            initialStateListener: (_) => initialCalled = true,
            callListenerOnInit: false,
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

    testWidgets('calls loadingStateListener with correct parameters', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
          emptyStateListener: (_, details) => capturedMessage = details.message,
        ),
      );

      provider.emit(const EmptyState<String>('No items found'));
      await tester.pump();

      expect(capturedMessage, 'No items found');
    });

    testWidgets(
      'resolves loading, empty, and error messages before listener callbacks',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );

        BuildContext? loadingContext;
        BuildContext? emptyContext;
        BuildContext? errorContext;

        LoadingStateDetails? loadingDetails;
        EmptyStateDetails? emptyDetails;
        ErrorStateDetails? errorDetails;

        const originalErrorInfo = ErrorInfo(
          message: 'error.network',
          code: 'network_error',
        );

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_, __) => const SizedBox(),
            loadingStateBuilder: (_, __, ___) => const SizedBox(),
            emptyStateBuilder: (_, __, ___) => const SizedBox(),
            errorStateBuilder: (_, __, ___) => const SizedBox(),
            messageResolver: (context, message) => 'localized:$message',
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ViewStateListener<String>(
                listenable: provider,
                loadingStateListener: (context, details) {
                  loadingContext = context;
                  loadingDetails = details;
                },
                emptyStateListener: (context, details) {
                  emptyContext = context;
                  emptyDetails = details;
                },
                errorStateListener: (context, details) {
                  errorContext = context;
                  errorDetails = details;
                },
                child: const SizedBox(),
              ),
            ),
          ),
        );

        // Loading message.
        provider.emit(const LoadingState<String>('profile.loading'));
        await tester.pump();

        expect(loadingContext, isA<BuildContext>());
        expect(loadingDetails!.message, 'localized:profile.loading');

        // Empty message.
        provider.emit(const EmptyState<String>('profile.empty'));
        await tester.pump();

        expect(emptyContext, isA<BuildContext>());
        expect(emptyDetails!.message, 'localized:profile.empty');

        // Error message.
        final error = StateError('Request failed');

        provider.emit(
          ErrorState<String>(
            error,
            StackTrace.current,
            errorInfo: originalErrorInfo,
          ),
        );
        await tester.pump();

        expect(errorContext, isA<BuildContext>());
        expect(errorContext, isA<BuildContext>());

        // Test the new convenience getters.
        expect(errorDetails!.message, 'localized:error.network');
        expect(errorDetails!.code, 'network_error');

        // Full error information remains accessible.
        expect(errorDetails!.errorInfo.message, 'localized:error.network');
        expect(errorDetails!.errorInfo.code, 'network_error');
        expect(errorDetails!.error, same(error));

        // Resolution must not mutate the stored error information.
        final storedState = provider.state as ErrorState<String>;
        expect(storedState.errorInfo.message, 'error.network');
        expect(storedState.errorInfo.code, 'network_error');
      },
    );

    testWidgets('calls errorStateListener with correct parameters', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      void onRetry() {}

      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      const errorInfo = ErrorInfo(
        message: 'Something went wrong',
        code: 'test_error',
      );

      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          errorStateListener: (_, details) {
            capturedErrorInfo = details.errorInfo;
            capturedOnRetry = details.onRetry;
            capturedError = details.error;
            capturedStackTrace = details.stackTrace;
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
    });

    testWidgets('does not call listener when emitting the same state twice', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      int dataCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          dataStateListener: (_, __) => dataCount++,
          callListenerOnInit: false,
        ),
      );

      provider.emit(const DataState<String>('same'));
      await tester.pump();
      expect(dataCount, 1);

      provider.emit(const DataState<String>('same')); // same state
      await tester.pump();
      expect(dataCount, 1); // no second call
    });

    testWidgets('only the matching callback is called for each state', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      int initialCount = 0;
      int loadingCount = 0;
      int dataCount = 0;
      int emptyCount = 0;
      int errorCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
          initialStateListener: (_) => initialCount++,
          loadingStateListener: (_, __) => loadingCount++,
          dataStateListener: (_, __) => dataCount++,
          emptyStateListener: (_, __) => emptyCount++,
          errorStateListener: (_, __) => errorCount++,
          callListenerOnInit: false,
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

      provider.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );
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

    testWidgets('listenWhen controls whether callbacks are triggered', (
      tester,
    ) async {
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
    });

    testWidgets('callListenerOnInit calls matching callback on init', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int dataCount = 0;

      await tester.pumpWidget(
        buildListener(
          provider: provider,
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
        buildListener(
          provider: provider,
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
      'safe to trigger dialogs inside listener (executed after state change)',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ViewStateListener<String>(
                    listenable: provider,
                    dataStateListener: (_, data) {
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
      },
    );

    testWidgets('calls dataStateListener when explicit listenable is passed', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool dataCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<String>(
            listenable: provider,
            dataStateListener: (_, __) => dataCalled = true,
            child: const SizedBox(),
          ),
        ),
      );

      provider.emit(const DataState<String>('test'));
      await tester.pump();
      expect(dataCalled, true);
    });

    testWidgets('reads listenable from context using ViewStateListener.of', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool dataCalled = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateListener.of<TestViewStateNotifier<String>, String>(
              // no provider, uses context.read
              dataStateListener: (_, __) => dataCalled = true,
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
          child: ViewStateListener<String>(
            listenable: provider,
            dataStateListener: (_, __) {},
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
      'switches to new listenable when listenable parameter changes at runtime',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const InitialState());
        final provider2 = TestViewStateNotifier<String>(const InitialState());
        int dataCount1 = 0;
        int dataCount2 = 0;

        Widget buildFrame(TestViewStateNotifier<String> provider) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateListener<String>(
              listenable: provider,
              dataStateListener: (_, data) {
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
      },
    );

    testWidgets(
      'listenWhen receives correct previous and current ViewState objects',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        List<ViewState<String>> previousList = [];
        List<ViewState<String>> currentList = [];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateListener<String>(
              listenable: provider,
              listenWhen: (previous, current) {
                previousList.add(previous);
                currentList.add(current);
                return true;
              },
              dataStateListener: (_, __) {},
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
      },
    );

    testWidgets('errorStateListener receives onRetry callback', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      VoidCallback? capturedOnRetry;
      void expectedOnRetry() {}

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<String>(
            listenable: provider,
            errorStateListener: (_, details) {
              capturedOnRetry = details.onRetry;
            },
            child: const SizedBox(),
          ),
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
    });

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
            child: ViewStateListener<String>(
              listenable: provider,
              errorStateListener: (_, details) {
                capturedErrorInfo = details.errorInfo;
                capturedOnRetry = details.onRetry;
                capturedError = details.error;
                capturedStackTrace = details.stackTrace;
              },
              callListenerOnInit: true,
              child: const SizedBox(),
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

    testWidgets('does not crash when state occurs without matching callback', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      // Only provide dataStateListener, but we will emit LoadingState
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateListener<String>(
            listenable: provider,
            dataStateListener: (_, __) {},
            child: const SizedBox(),
          ),
        ),
      );

      provider.emit(const LoadingState<String>());
      await tester.pump();
    });

    testWidgets(
      'uses the latest resolved message when listeners fire after locale changes',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );

        addTearDown(provider.dispose);

        var locale = 'en';
        late StateSetter changeLocale;

        final loadingMessages = <String?>[];
        final emptyMessages = <String?>[];
        final errorMessages = <String?>[];

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
                    child: ViewStateListener<String>(
                      listenable: provider,
                      loadingStateListener: (context, details) {
                        expect(
                          context
                              .findAncestorWidgetOfExactType<
                                TestLocaleInherited
                              >()
                              ?.locale,
                          locale,
                        );
                        loadingMessages.add(details.message);
                      },
                      emptyStateListener: (context, details) {
                        expect(
                          context
                              .findAncestorWidgetOfExactType<
                                TestLocaleInherited
                              >()
                              ?.locale,
                          locale,
                        );
                        emptyMessages.add(details.message);
                      },
                      errorStateListener: (context, details) {
                        expect(
                          context
                              .findAncestorWidgetOfExactType<
                                TestLocaleInherited
                              >()
                              ?.locale,
                          locale,
                        );
                        errorMessages.add(details.errorInfo.message);
                      },
                      child: const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // First event uses English.
        provider.emit(const LoadingState<String>('profile.loading'));
        await tester.pump();

        expect(loadingMessages, ['en:profile.loading']);

        // Changing locale alone must not invoke the listener again.
        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(loadingMessages, ['en:profile.loading']);

        // The next loading event uses the latest locale.
        provider.emit(const LoadingState<String>('profile.refreshing'));
        await tester.pump();

        expect(loadingMessages, [
          'en:profile.loading',
          'fr:profile.refreshing',
        ]);

        // The empty-state listener uses the latest locale.
        changeLocale(() {
          locale = 'es';
        });
        await tester.pump();

        expect(emptyMessages, isEmpty);

        provider.emit(const EmptyState<String>('profile.empty'));
        await tester.pump();

        expect(emptyMessages, ['es:profile.empty']);

        // The error-state listener uses the latest locale.
        changeLocale(() {
          locale = 'de';
        });
        await tester.pump();

        expect(errorMessages, isEmpty);

        provider.emit(
          ErrorState<String>(
            StateError('Request failed'),
            StackTrace.current,
            errorInfo: const ErrorInfo(
              message: 'error.network',
              code: 'network_error',
            ),
          ),
        );
        await tester.pump();

        expect(errorMessages, ['de:error.network']);

        // Resolving a message must not mutate the stored original message.
        final storedState = provider.state as ErrorState<String>;

        expect(storedState.errorInfo.message, 'error.network');
        expect(storedState.errorInfo.code, 'network_error');
      },
    );

    // -----------------------------------------------------------------------
    // 9. Diagnostics
    // -----------------------------------------------------------------------
    testWidgets('debugFillProperties includes all relevant properties', (
      tester,
    ) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateListener<String>(
        listenable: TestViewStateNotifier<String>(),
        dataStateListener: (_, __) {},
        loadingStateListener: (_, __) {},
        emptyStateListener: (_, __) {},
        errorStateListener: (_, __) {},
        initialStateListener: (_) {},
        listenWhen: (_, __) => true,
        callListenerOnInit: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((e) => e.contains('listenable')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
        description.any(
          (e) => e.contains('callListenerOnInit') && e.contains('true'),
        ),
        isTrue,
      );

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
