import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider keys.
// -----------------------------------------------------------------------------

const _defaultInitialKey = Key('default_initial');

const _defaultLoadingKey = Key('default_loading');

const _defaultEmptyKey = Key('default_empty');

const _defaultErrorKey = Key('default_error');

void main() {
  group('ViewStateConsumer.multi', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    Widget withDefaultProviderWidget(Widget child) {
      return ViewStateWidgetsProvider(
        initialStateBuilder: (_, __) => const SizedBox(key: _defaultInitialKey),
        loadingStateBuilder: (_, __, ___) =>
            const SizedBox(key: _defaultLoadingKey),
        emptyStateBuilder: (_, __, ___) =>
            const SizedBox(key: _defaultEmptyKey),
        errorStateBuilder: (_, __, ___) =>
            const SizedBox(key: _defaultErrorKey),
        child: child,
      );
    }

    Widget buildConsumer<T>({
      required MultiStateListenables<T> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<T>? dataStateListener,
      RebuildWhen<T>? rebuildWhen,
      ListenWhen<T>? listenWhen,
      bool callListenerOnInit = false,
      bool isSliver = false,
      bool withDefaultProvider = false,
      Widget? child,
    }) {
      Widget widget = wrap(
        ViewStateConsumer<T>.multi(
          listenables: providers,
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
        ),
      );

      if (withDefaultProvider) {
        widget = withDefaultProviderWidget(widget);
      }

      return widget;
    }

    // -------------------------------------------------------------------------
    // Basic Rendering
    // -------------------------------------------------------------------------

    testWidgets('renders dataBuilder output', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      bool builderCalled = false;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => provider.watch,
          dataBuilder: (_, state, __) {
            builderCalled = true;

            expect(state, same(provider.state));
            expect(state.data, 'data');

            return Text(state.data, key: const Key('data_output'));
          },
        ),
      );

      expect(builderCalled, isTrue);
      expect(find.byKey(const Key('data_output')), findsOneWidget);
      expect(find.text('data'), findsOneWidget);
    });

    testWidgets(
      'reuses the same child without rebuilding it when combined data changes',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(
          const DataState<String>('first'),
        );
        final provider2 = TestViewStateNotifier<String>(
          const DataState<String>('peer'),
        );
        addTearDown(provider1.dispose);
        addTearDown(provider2.dispose);

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
          buildConsumer<({ViewState<String> first, ViewState<String> second})>(
            providers: () => (first: provider1.watch, second: provider2.watch),
            child: staticChild,
            dataBuilder: (_, state, child) {
              dataBuilderCallCount++;
              receivedChildren.add(child);

              return Column(
                children: [
                  Text('${state.first.data}-${state.second.data}'),
                  if (child != null) child,
                ],
              );
            },
          ),
        );

        expect(find.text('first-peer'), findsOneWidget);
        expect(find.text('static child'), findsOneWidget);
        expect(dataBuilderCallCount, 1);
        expect(childBuildCount, 1);
        expect(identical(receivedChildren.first, staticChild), isTrue);

        provider1.emit(const DataState<String>('second'));
        await tester.pump();

        expect(find.text('first-peer'), findsNothing);
        expect(find.text('second-peer'), findsOneWidget);
        expect(dataBuilderCallCount, 2);

        // The same child is passed again without rebuilding its subtree.
        expect(childBuildCount, 1);
        expect(receivedChildren, hasLength(2));
        expect(
          receivedChildren.every((child) => identical(child, staticChild)),
          isTrue,
        );
      },
    );

    testWidgets('supports a list as the combined state', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      await tester.pumpWidget(
        buildConsumer<List<ViewState<String>>>(
          providers: () => [provider1.watch, provider2.watch],
          dataBuilder: (_, state, __) {
            expect(state, hasLength(2));
            expect(state[0], same(provider1.state));
            expect(state[1], same(provider2.state));

            return Text('${state[0].data}-${state[1].data}');
          },
        ),
      );

      expect(find.text('one-two'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Builder + Listener Integration
    // -------------------------------------------------------------------------

    testWidgets(
      'invokes only the matching builder and listener with usable contexts',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
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
              providers: () => provider.watch,
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
              dataBuilder: (context, state, child) {
                expectContext(context);
                calledBuilders.add('data');
                return const SizedBox();
              },
              initialStateListener: (context) {
                expectContext(context);
                calledListeners.add('initial');
              },
              loadingStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('loading');
              },
              emptyStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('empty');
              },
              errorStateListener: (context, details) {
                expectContext(context);
                calledListeners.add('error');
              },
              dataStateListener: (context, data) {
                expectContext(context);
                calledListeners.add('data');
              },
              callListenerOnInit: false,
            ),
          ),
        );

        // Initial data state: builder runs, listener does not.
        expect(calledBuilders, ['data']);
        expect(calledListeners, isEmpty);

        provider.emit(const InitialState<String>());
        await tester.pump();

        expect(calledBuilders, ['data', 'initial']);
        expect(calledListeners, ['initial']);

        provider.emit(const LoadingState<String>('loading', 0.4));
        await tester.pump();

        expect(calledBuilders, ['data', 'initial', 'loading']);
        expect(calledListeners, ['initial', 'loading']);

        provider.emit(const EmptyState<String>('empty'));
        await tester.pump();

        expect(calledBuilders, ['data', 'initial', 'loading', 'empty']);
        expect(calledListeners, ['initial', 'loading', 'empty']);

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(calledBuilders, [
          'data',
          'initial',
          'loading',
          'empty',
          'error',
        ]);
        expect(calledListeners, ['initial', 'loading', 'empty', 'error']);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(calledBuilders, [
          'data',
          'initial',
          'loading',
          'empty',
          'error',
          'data',
        ]);
        expect(calledListeners, [
          'initial',
          'loading',
          'empty',
          'error',
          'data',
        ]);
      },
    );

    testWidgets(
      'uses the latest resolved messages in builders and listeners after locale changes',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );
        addTearDown(provider.dispose);

        var locale = 'en';
        late StateSetter changeLocale;

        final builderMessages = <String?>[];
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
                    child: ViewStateConsumer.multi(
                      listenables: () => provider.watch,
                      loadingBuilder: (context, details) {
                        builderMessages.add(details.message);
                        return Text(details.message ?? '');
                      },
                      emptyBuilder: (context, details) {
                        return Text(details.message ?? '');
                      },
                      errorBuilder: (context, details) {
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
                      dataBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // First loading event uses English.
        provider.emit(const LoadingState<String>('profile.loading'));
        await tester.pump();

        expect(find.text('en:profile.loading'), findsOneWidget);
        expect(builderMessages, ['en:profile.loading']);
        expect(loadingMessages, ['en:profile.loading']);

        // Locale change updates the builder, but does not replay the listener.
        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(find.text('en:profile.loading'), findsNothing);
        expect(find.text('fr:profile.loading'), findsOneWidget);
        expect(builderMessages, ['en:profile.loading', 'fr:profile.loading']);
        expect(loadingMessages, ['en:profile.loading']);

        // The next loading event uses French in both callbacks.
        provider.emit(const LoadingState<String>('profile.refreshing'));
        await tester.pump();

        expect(find.text('fr:profile.refreshing'), findsOneWidget);
        expect(builderMessages, [
          'en:profile.loading',
          'fr:profile.loading',
          'fr:profile.refreshing',
        ]);
        expect(loadingMessages, [
          'en:profile.loading',
          'fr:profile.refreshing',
        ]);

        // The empty-state builder and listener use Spanish.
        changeLocale(() {
          locale = 'es';
        });
        await tester.pump();

        provider.emit(const EmptyState<String>('profile.empty'));
        await tester.pump();

        expect(find.text('es:profile.empty'), findsOneWidget);
        expect(emptyMessages, ['es:profile.empty']);

        // The error-state builder and listener use German.
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

        expect(find.text('de:error.network'), findsOneWidget);
        expect(errorMessage, 'de:error.network');
        expect(errorCode, 'network_error');

        // Localization must not mutate the original stored error information.
        final storedState = provider.state as ErrorState<String>;
        expect(storedState.errorInfo.message, 'error.network');
        expect(storedState.errorInfo.code, 'network_error');
      },
    );
    // -------------------------------------------------------------------------
    // Builder Parameters
    // -------------------------------------------------------------------------

    testWidgets(
      'errorBuilder and errorStateListener receive error details unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        final expectedError = StateError('original error');

        final expectedStackTrace = StackTrace.current;

        const expectedErrorInfo = ErrorInfo(
          message: 'Mapped error',
          code: 'mapped_error',
        );

        bool retryCalled = false;

        ErrorInfo? capturedBuilderErrorInfo;
        Object? capturedBuilderError;
        StackTrace? capturedBuilderStackTrace;
        VoidCallback? capturedBuilderRetry;

        ErrorInfo? capturedListenerErrorInfo;
        Object? capturedListenerError;
        StackTrace? capturedListenerStackTrace;
        VoidCallback? capturedListenerRetry;

        String? capturedBuilderMessage;
        String? capturedBuilderCode;
        String? capturedListenerMessage;
        String? capturedListenerCode;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            errorBuilder: (_, details) {
              capturedBuilderErrorInfo = details.errorInfo;
              capturedBuilderError = details.error;
              capturedBuilderStackTrace = details.stackTrace;
              capturedBuilderRetry = details.onRetry;
              capturedBuilderMessage = details.message;
              capturedBuilderCode = details.code;

              return const SizedBox();
            },
            errorStateListener: (_, details) {
              capturedListenerErrorInfo = details.errorInfo;
              capturedListenerError = details.error;
              capturedListenerStackTrace = details.stackTrace;
              capturedListenerRetry = details.onRetry;
              capturedListenerMessage = details.message;
              capturedListenerCode = details.code;
            },
            dataBuilder: (_, __, ___) => const SizedBox(),
            isSliver: true,
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

        expect(capturedBuilderErrorInfo, same(expectedErrorInfo));
        expect(capturedBuilderError, same(expectedError));
        expect(capturedBuilderStackTrace, same(expectedStackTrace));
        expect(capturedBuilderRetry, isNotNull);

        expect(capturedListenerErrorInfo, same(expectedErrorInfo));
        expect(capturedListenerError, same(expectedError));
        expect(capturedListenerStackTrace, same(expectedStackTrace));
        expect(capturedListenerRetry, isNotNull);

        expect(capturedBuilderMessage, expectedErrorInfo.message);
        expect(capturedBuilderCode, expectedErrorInfo.code);
        expect(capturedListenerMessage, expectedErrorInfo.message);
        expect(capturedListenerCode, expectedErrorInfo.code);

        capturedBuilderRetry!();

        expect(retryCalled, isTrue);
      },
    );

    testWidgets(
      'loadingBuilder and loadingStateListener receive nullable progress unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedBuilderMessage;
        double? capturedBuilderProgress;

        String? capturedListenerMessage;
        double? capturedListenerProgress;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            loadingBuilder: (_, details) {
              capturedBuilderMessage = details.message;
              capturedBuilderProgress = details.progress;

              return const SizedBox();
            },
            loadingStateListener: (_, details) {
              capturedListenerMessage = details.message;
              capturedListenerProgress = details.progress;
            },
            dataBuilder: (_, __, ___) => const SizedBox(),
            isSliver: true,
          ),
        );

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedBuilderMessage, 'Loading');
        expect(capturedBuilderProgress, 0.4);

        expect(capturedListenerMessage, 'Loading');
        expect(capturedListenerProgress, 0.4);

        provider.emit(const LoadingState<String>('Loading without progress'));

        await tester.pump();

        expect(capturedBuilderMessage, 'Loading without progress');
        expect(capturedBuilderProgress, isNull);
        expect(capturedListenerMessage, 'Loading without progress');
        expect(capturedListenerProgress, isNull);
      },
    );

    testWidgets(
      'emptyBuilder and emptyStateListener receive message unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedBuilderMessage;

        String? capturedListenerMessage;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            emptyBuilder: (_, details) {
              capturedBuilderMessage = details.message;
              return const SizedBox();
            },
            emptyStateListener: (_, details) {
              capturedListenerMessage = details.message;
            },
            dataBuilder: (_, __, ___) => const SizedBox(),
            isSliver: true,
          ),
        );

        provider.emit(const EmptyState<String>('Nothing found'));

        await tester.pump();

        expect(capturedBuilderMessage, 'Nothing found');
        expect(capturedListenerMessage, 'Nothing found');
      },
    );

    // -------------------------------------------------------------------------
    // Initialization
    // -------------------------------------------------------------------------

    testWidgets(
      'does not call listener on initialization when callListenerOnInit is false',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int listenerCalls = 0;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            dataBuilder: (_, __, ___) => const SizedBox(),
            dataStateListener: (_, __) {
              listenerCalls++;
            },
          ),
        );

        await tester.pump();

        expect(listenerCalls, 0);
      },
    );

    testWidgets(
      'callListenerOnInit invokes the listener with the current combined state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('Initial loading', 0.5),
        );

        String? capturedMessage;
        double? capturedProgress;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            loadingBuilder: (_, __) => const SizedBox(),
            dataBuilder: (_, __, ___) => const SizedBox(),
            loadingStateListener: (_, details) {
              capturedMessage = details.message;
              capturedProgress = details.progress;
            },
            callListenerOnInit: true,
          ),
        );

        await tester.pump();

        expect(capturedMessage, 'Initial loading');
        expect(capturedProgress, 0.5);
      },
    );

    // -------------------------------------------------------------------------
    // Default ViewStateWidgetsProvider
    // -------------------------------------------------------------------------

    testWidgets('uses default state widgets from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      await tester.pumpWidget(
        buildConsumer(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
      provider.emit(const LoadingState<String>('loading'));

      await tester.pump();
      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
      provider.emit(const EmptyState<String>('empty'));

      await tester.pump();
      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
      provider.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pump();
      expect(find.byKey(_defaultErrorKey), findsOneWidget);
      provider.emit(const DataState<String>('data'));

      await tester.pump();
      expect(find.byKey(_defaultInitialKey), findsNothing);
      expect(find.byKey(_defaultLoadingKey), findsNothing);
      expect(find.byKey(_defaultEmptyKey), findsNothing);
      expect(find.byKey(_defaultErrorKey), findsNothing);
    });

    testWidgets(
      'default state widgets receive isSliver when used by the consumer',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('loading'),
        );

        bool? capturedIsSliver;

        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_, __) => const SizedBox(),
            loadingStateBuilder: (_, __, isSliver) {
              capturedIsSliver = isSliver;
              return const SizedBox();
            },
            emptyStateBuilder: (_, __, ___) => const SizedBox(),
            errorStateBuilder: (_, __, ___) => const SizedBox(),
            child: wrap(
              ViewStateConsumer.multi(
                listenables: () => provider.watch,
                dataBuilder: (_, __, ___) => const SizedBox(),
                isSliver: true,
              ),
            ),
          ),
        );

        expect(capturedIsSliver, isTrue);
      },
    );

    // -------------------------------------------------------------------------
    // Dependency Tracking
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

      int builderCalls = 0;
      int listenerCalls = 0;

      await tester.pumpWidget(
        buildConsumer<({ViewState<String> first, ViewState<String> second})>(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_, __, ___) {
            builderCalls++;
            return const SizedBox();
          },
          dataStateListener: (_, __) {
            listenerCalls++;
          },
        ),
      );

      expect(builderCalls, 1);
      expect(listenerCalls, 0);

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(builderCalls, 2);
      expect(listenerCalls, 1);

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(builderCalls, 3);
      expect(listenerCalls, 2);
    });

    testWidgets(
      'subscribes only once when the same listenable is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int builderCalls = 0;
        int listenerCalls = 0;

        await tester.pumpWidget(
          buildConsumer<({ViewState<String> first, ViewState<String> second})>(
            providers: () => (first: provider.watch, second: provider.watch),
            dataBuilder: (_, __, ___) {
              builderCalls++;
              return const SizedBox();
            },
            dataStateListener: (_, __) {
              listenerCalls++;
            },
          ),
        );

        expect(builderCalls, 1);
        expect(listenerCalls, 0);

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(builderCalls, 2);
        expect(listenerCalls, 1);
      },
    );

    testWidgets(
      'throws AssertionError when listenables does not watch any state source',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            ViewStateConsumer.multi(
              listenables: () => const DataState<String>('data'),
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<AssertionError>().having(
            (AssertionError error) => error.message,
            'message',
            allOf(
              contains('requires at least one watched state source'),
              contains('.watch'),
            ),
          ),
        );
      },
    );

    testWidgets(
      'throws StateError when a watched dependency is not a ViewStateNotifier',
      (tester) async {
        final field = StateField<String>('data');

        await tester.pumpWidget(
          wrap(
            ViewStateConsumer.multi(
              listenables: () => field.watch,
              dataBuilder: (_, __, ___) => const SizedBox(),
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
    // Runtime Dependency Replacement
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

      MultiStateListenables<ViewState<String>> providers = () =>
          provider1.watch;

      int builderCalls = 0;
      int listenerCalls = 0;

      String? capturedValue;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: <Widget>[
                  ViewStateConsumer.multi(
                    listenables: providers,
                    dataBuilder: (_, state, ___) {
                      builderCalls++;
                      capturedValue = state.data;

                      return Text(state.data);
                    },
                    dataStateListener: (_, __) {
                      listenerCalls++;
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        providers = () => provider2.watch;
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

      expect(builderCalls, 1);
      expect(listenerCalls, 0);
      expect(capturedValue, 'one');

      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(builderCalls, 2);
      expect(listenerCalls, 1);
      expect(capturedValue, 'one-new');

      await tester.tap(find.text('Switch'));

      await tester.pump();

      expect(builderCalls, 3);
      expect(listenerCalls, 1);
      expect(capturedValue, 'two');

      provider1.emit(const DataState<String>('one-after-switch'));

      await tester.pump();

      expect(builderCalls, 3);
      expect(listenerCalls, 1);
      expect(capturedValue, 'two');

      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();

      expect(builderCalls, 4);
      expect(listenerCalls, 2);
      expect(capturedValue, 'two-new');
    });

    testWidgets(
      'does not duplicate listenable notifications after parent rebuild with the same dependency',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int builderCalls = 0;
        int listenerCalls = 0;

        await tester.pumpWidget(
          wrap(
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: <Widget>[
                    ViewStateConsumer.multi(
                      listenables: () => provider.watch,
                      dataBuilder: (_, __, ___) {
                        builderCalls++;
                        return const SizedBox();
                      },
                      dataStateListener: (_, __) {
                        listenerCalls++;
                      },
                    ),
                    TextButton(
                      key: const Key('rebuild_parent'),
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Rebuild Parent'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        expect(builderCalls, 1);
        expect(listenerCalls, 0);

        await tester.tap(find.byKey(const Key('rebuild_parent')));

        await tester.pump();

        // The parent rebuild itself legitimately causes the consumer builder
        // to run once. The listener must not run.
        expect(builderCalls, 2);
        expect(listenerCalls, 0);

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        // Exactly one provider notification -> exactly one consumer rebuild
        // and exactly one listener invocation.
        expect(builderCalls, 3);
        expect(listenerCalls, 1);
      },
    );

    // -------------------------------------------------------------------------
    // Cleanup
    // -------------------------------------------------------------------------

    testWidgets('detaches dependency listeners when the consumer is removed', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildConsumer(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
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
      'debugFillProperties exposes all MultiViewStateConsumer properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<int>(const DataState<int>(1));

        ViewStateConsumer.multi(
          listenables: () => (value: provider.watch),
          initialBuilder: (_) => const SizedBox(),
          loadingBuilder: (_, __) => const SizedBox(),
          emptyBuilder: (_, __) => const SizedBox(),
          errorBuilder: (_, __) => const SizedBox(),
          dataBuilder: (_, __, ___) => const SizedBox(),
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
          description.any((value) => value.contains('rebuildWhen')),
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
          description.any((value) => value.contains('initialBuilder')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('loadingBuilder')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('emptyBuilder')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('errorBuilder')),
          isTrue,
        );

        expect(
          description.any((value) => value.contains('dataBuilder')),
          isTrue,
        );

        expect(
          description.any(
            (value) => value.contains('isSliver') && value.contains('true'),
          ),
          isTrue,
        );

        expect(description.any((e) => e.contains('child')), isTrue);

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
