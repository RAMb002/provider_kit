import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

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

    testWidgets('listenWhen filters state-specific listener callbacks', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      final receivedStates = <String>[];

      await tester.pumpWidget(
        buildListener(
          providers: singleProvider(provider),
          listenWhen: (_, current) =>
              current is DataState<String> && current.data == 'accepted',
          dataStateListener: (_, state) {
            receivedStates.add(state.data);
          },
        ),
      );

      provider.emit(const DataState<String>('ignored'));
      await tester.pump();

      expect(receivedStates, isEmpty);

      provider.emit(const DataState<String>('accepted'));
      await tester.pump();

      expect(receivedStates, ['accepted']);
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
