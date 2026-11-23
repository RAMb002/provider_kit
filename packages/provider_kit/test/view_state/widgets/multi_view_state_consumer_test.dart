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

    testWidgets('forwards rebuildWhen and listenWhen independently', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('initial'),
      );

      final builderValues = <String>[];
      final listenerValues = <String>[];

      await tester.pumpWidget(
        buildConsumer(
          providers: () => provider.watch,
          rebuildWhen: (_, current) =>
              current is DataState<String> && current.data == 'builder-only',
          listenWhen: (_, current) =>
              current is DataState<String> && current.data == 'listener-only',
          dataBuilder: (_, state, __) {
            builderValues.add(state.data);
            return Text(state.data);
          },
          dataStateListener: (_, state) {
            listenerValues.add(state.data);
          },
        ),
      );

      expect(builderValues, ['initial']);
      expect(listenerValues, isEmpty);

      provider.emit(const DataState<String>('builder-only'));
      await tester.pump();

      expect(builderValues, ['initial', 'builder-only']);
      expect(listenerValues, isEmpty);

      provider.emit(const DataState<String>('listener-only'));
      await tester.pump();

      expect(builderValues, ['initial', 'builder-only']);
      expect(listenerValues, ['listener-only']);
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
