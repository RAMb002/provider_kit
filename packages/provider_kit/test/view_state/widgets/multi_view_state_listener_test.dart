import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

typedef TwoStates = ({ViewState<String> first, ViewState<String> second});

void main() {
  group('ViewStateListener.multi', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    MultiStateListenables<ViewState<String>> singleProvider(
      ViewStateNotifier<String> provider,
    ) {
      return () => provider.watch;
    }

    MultiStateListenables<TwoStates> twoProviders(
      ViewStateNotifier<String> provider1,
      ViewStateNotifier<String> provider2,
    ) {
      return () => (first: provider1.watch, second: provider2.watch);
    }

    Widget buildListener({
      required MultiStateListenables<ViewState<String>> providers,
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
        ViewStateListener.multi(
          listenables: providers,
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
      required MultiStateListenables<TwoStates> providers,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<TwoStates>? dataStateListener,
      ListenWhen<TwoStates>? listenWhen,
      bool callListenerOnInit = false,
      Widget? child,
    }) {
      return wrap(
        ViewStateListener.multi(
          listenables: providers,
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

    // -------------------------------------------------------------------------
    // Rendering & child
    // -------------------------------------------------------------------------

    testWidgets('renders the provided child', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

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
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        ViewStateListener.multi(listenables: singleProvider(provider)),
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

    // -------------------------------------------------------------------------
    // State-specific callback wiring
    // -------------------------------------------------------------------------

    testWidgets(
      'invokes the corresponding listener when the listenable enters each state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );

        int initialCalls = 0;
        int loadingCalls = 0;
        int emptyCalls = 0;
        int errorCalls = 0;
        int dataCalls = 0;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            initialStateListener: (_) {
              initialCalls++;
            },
            loadingStateListener: (_, __) {
              loadingCalls++;
            },
            emptyStateListener: (_, __) {
              emptyCalls++;
            },
            errorStateListener: (_, __) {
              errorCalls++;
            },
            dataStateListener: (_, __) {
              dataCalls++;
            },
          ),
        );

        expect(dataCalls, 0);
        expect(initialCalls, 0);
        expect(loadingCalls, 0);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);

        provider.emit(const InitialState<String>());
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 0);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(const LoadingState<String>('Loading', 0.4));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 0);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(const EmptyState<String>('Empty'));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 0);
        expect(dataCalls, 0);

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 1);
        expect(dataCalls, 0);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(initialCalls, 1);
        expect(loadingCalls, 1);
        expect(emptyCalls, 1);
        expect(errorCalls, 1);
        expect(dataCalls, 1);
      },
    );

    testWidgets(
      'errorStateListener receives ErrorState arguments unchanged and invokes retry callback',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        final Object expectedError = Exception('original error');
        final StackTrace expectedStackTrace = StackTrace.current;

        const ErrorInfo expectedErrorInfo = ErrorInfo(
          message: 'Mapped error',
          code: 'mapped_error',
        );

        bool retryCalled = false;

        ErrorInfo? capturedErrorInfo;
        Object? capturedError;
        StackTrace? capturedStackTrace;
        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            errorStateListener: (_, details) {
              capturedErrorInfo = details.errorInfo;
              capturedError = details.error;
              capturedStackTrace = details.stackTrace;
              capturedOnRetry = details.onRetry;
            },
          ),
        );

        provider.emit(
          ErrorState<String>(
            expectedError,
            expectedStackTrace,
            errorInfo: expectedErrorInfo,
            onRetry: () {
              retryCalled = true;
            },
          ),
        );

        await tester.pump();

        expect(capturedErrorInfo, same(expectedErrorInfo));
        expect(capturedError, same(expectedError));
        expect(capturedStackTrace, same(expectedStackTrace));
        expect(capturedOnRetry, isNotNull);

        capturedOnRetry!();

        expect(retryCalled, isTrue);
      },
    );

    testWidgets(
      'loadingStateListener receives loading message and nullable progress unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            loadingStateListener: (_, details) {
              capturedMessage = details.message;
              capturedProgress = details.progress;
            },
          ),
        );

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.4);

        provider.emit(const LoadingState<String>('Loading without progress'));

        await tester.pump();

        expect(capturedMessage, 'Loading without progress');
        expect(capturedProgress, isNull);
      },
    );

    testWidgets(
      'emptyStateListener receives the EmptyState message unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            emptyStateListener: (_, details) {
              capturedMessage = details.message;
            },
          ),
        );

        provider.emit(const EmptyState<String>('Nothing found'));

        await tester.pump();

        expect(capturedMessage, 'Nothing found');
      },
    );

    testWidgets(
      'uses the latest resolved messages when multi-listener callbacks fire after locale changes',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );
        addTearDown(provider.dispose);

        var locale = 'en';
        late StateSetter changeLocale;

        final loadingMessages = <String?>[];
        final emptyMessages = <String?>[];

        String? errorMessage;
        String? errorCode;

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
                    child: ViewStateListener.multi(
                      listenables: singleProvider(provider),
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
                        errorMessage = details.message;
                        errorCode = details.code;
                      },
                      child: const SizedBox(),
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

        expect(loadingMessages, ['en:profile.loading']);

        // Changing locale alone does not trigger another listener callback.
        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(loadingMessages, ['en:profile.loading']);

        // The next loading event uses French.
        provider.emit(const LoadingState<String>('profile.refreshing'));
        await tester.pump();

        expect(loadingMessages, [
          'en:profile.loading',
          'fr:profile.refreshing',
        ]);

        // The empty-state listener also uses the latest locale.
        changeLocale(() {
          locale = 'es';
        });
        await tester.pump();

        expect(emptyMessages, isEmpty);

        provider.emit(const EmptyState<String>('profile.empty'));
        await tester.pump();

        expect(emptyMessages, ['es:profile.empty']);

        // The error listener uses the latest locale and preserves the error code.
        changeLocale(() {
          locale = 'de';
        });
        await tester.pump();

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

        expect(errorMessage, 'de:error.network');
        expect(errorCode, 'network_error');

        // Resolving the message must not modify the original stored ErrorInfo.
        final storedState = provider.state as ErrorState<String>;
        expect(storedState.errorInfo.message, 'error.network');
        expect(storedState.errorInfo.code, 'network_error');
      },
    );

    testWidgets('dataStateListener receives the DataState unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      ViewState<String>? capturedState;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_, state) {
            capturedState = state;
          },
        ),
      );

      const updatedState = DataState<String>('updated');

      provider.emit(updatedState);

      await tester.pump();

      expect(capturedState, same(updatedState));
    });

    // -------------------------------------------------------------------------
    // Initialization behavior
    // -------------------------------------------------------------------------

    testWidgets('does not call listeners on initialization by default', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_, __) {
            dataCalls++;
          },
        ),
      );

      await tester.pump();

      expect(dataCalls, 0);
    });

    testWidgets(
      'callListenerOnInit invokes the listener with the current state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('Loading', 0.5),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildListener(
            providers: singleProvider(provider),
            callListenerOnInit: true,
            loadingStateListener: (_, details) {
              capturedMessage = details.message;
              capturedProgress = details.progress;
            },
          ),
        );

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.5);
      },
    );

    // -------------------------------------------------------------------------
    // Dependency tracking
    // -------------------------------------------------------------------------

    testWidgets('subscribes to every listenable accessed through watch', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        buildTwoProviderListener(
          providers: twoProviders(provider1, provider2),
          dataStateListener: (_, __) {
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

    testWidgets(
      'subscribes only once when the same listenable is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataCalls = 0;

        await tester.pumpWidget(
          wrap(
            ViewStateListener.multi(
              listenables: () =>
                  (first: provider.watch, second: provider.watch),
              dataStateListener: (_, __) {
                dataCalls++;
              },
              child: const SizedBox(),
            ),
          ),
        );

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(dataCalls, 1);
      },
    );

    testWidgets(
      'throws StateError when a watched dependency is not a ViewStateNotifier',
      (tester) async {
        final field = StateField<String>('data');

        await tester.pumpWidget(
          wrap(
            ViewStateListener.multi(
              listenables: () => field.watch,
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

    // -------------------------------------------------------------------------
    // Runtime dependency changes
    // -------------------------------------------------------------------------

    testWidgets('switches subscriptions when the watched listenable changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      MultiStateListenables<ViewState<String>> providers = singleProvider(
        provider1,
      );

      int dataCalls = 0;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  ViewStateListener.multi(
                    listenables: providers,
                    dataStateListener: (_, __) {
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
      'does not duplicate listenable notifications after rebuilding with the same dependency',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataCalls = 0;

        Widget buildFrame() {
          return buildListener(
            providers: singleProvider(provider),
            dataStateListener: (_, __) {
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

    // -------------------------------------------------------------------------
    // Cleanup
    // -------------------------------------------------------------------------

    testWidgets('detaches listenable listeners when the widget is removed', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          dataStateListener: (_, __) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // -------------------------------------------------------------------------
    // Diagnostics
    // -------------------------------------------------------------------------

    testWidgets(
      'debugFillProperties exposes MultiViewStateListener properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        ViewStateListener.multi(
          listenables: singleProvider(provider),
          initialStateListener: (_) {},
          loadingStateListener: (_, __) {},
          emptyStateListener: (_, __) {},
          errorStateListener: (_, __) {},
          dataStateListener: (_, __) {},
          listenWhen: (_, __) => true,
          callListenerOnInit: true,
          child: const SizedBox(),
        ).debugFillProperties(diagnostics);

        final description = diagnostics.properties
            .where((node) => !node.isFiltered(DiagnosticLevel.info))
            .map((node) => node.toString())
            .toList();

        expect(
          description.any((value) => value.contains('listenables')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('listenWhen')),
          isTrue,
        );

        expect(
          description.any(
            (value) =>
                value.contains('callListenerOnInit') && value.contains('true'),
          ),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('initialStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('loadingStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('emptyStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('errorStateListener')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('dataStateListener')),
          isTrue,
        );
      },
    );
  });
}
