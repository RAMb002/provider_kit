import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';

// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider keys.
// -----------------------------------------------------------------------------

const _defaultInitialKey = Key('default_initial');

const _defaultLoadingKey = Key('default_loading');

const _defaultEmptyKey = Key('default_empty');

const _defaultErrorKey = Key('default_error');

void main() {
  group('MultiViewStateConsumer', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    Widget withDefaultProviderWidget(Widget child) {
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

    Widget buildConsumer<T>({
      required MultiStateProviders<T> providers,
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
    }) {
      Widget widget = wrap(
        MultiViewStateConsumer<T>(
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
          callListenerOnInit: callListenerOnInit,
          isSliver: isSliver,
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
          dataBuilder: (state) {
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
          dataBuilder: (state) {
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
      'invokes the corresponding builder and listener when provider enters each state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int initialBuilderCalls = 0;
        int loadingBuilderCalls = 0;
        int emptyBuilderCalls = 0;
        int errorBuilderCalls = 0;
        int dataBuilderCalls = 0;

        int initialListenerCalls = 0;
        int loadingListenerCalls = 0;
        int emptyListenerCalls = 0;
        int errorListenerCalls = 0;
        int dataListenerCalls = 0;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            initialBuilder: (_) {
              initialBuilderCalls++;
              return const SizedBox();
            },
            loadingBuilder: (_, __, ___) {
              loadingBuilderCalls++;
              return const SizedBox();
            },
            emptyBuilder: (_, __) {
              emptyBuilderCalls++;
              return const SizedBox();
            },
            errorBuilder: (_, __, ___, ____, _____) {
              errorBuilderCalls++;
              return const SizedBox();
            },
            dataBuilder: (_) {
              dataBuilderCalls++;
              return const SizedBox();
            },
            initialStateListener: () {
              initialListenerCalls++;
            },
            loadingStateListener: (_, __) {
              loadingListenerCalls++;
            },
            emptyStateListener: (_) {
              emptyListenerCalls++;
            },
            errorStateListener: (_, __, ___, ____) {
              errorListenerCalls++;
            },
            dataStateListener: (_) {
              dataListenerCalls++;
            },
          ),
        );

        // Initial DataState is rendered by the builder but does not
        // trigger the listener by default.
        expect(dataBuilderCalls, 1);
        expect(dataListenerCalls, 0);

        provider.emit(const InitialState<String>());

        await tester.pump();

        expect(initialBuilderCalls, 1);
        expect(initialListenerCalls, 1);

        provider.emit(const LoadingState<String>('loading', 0.4));

        await tester.pump();

        expect(loadingBuilderCalls, 1);
        expect(loadingListenerCalls, 1);

        provider.emit(const EmptyState<String>('empty'));

        await tester.pump();

        expect(emptyBuilderCalls, 1);
        expect(emptyListenerCalls, 1);

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );

        await tester.pump();

        expect(errorBuilderCalls, 1);
        expect(errorListenerCalls, 1);

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(dataBuilderCalls, 2);
        expect(dataListenerCalls, 1);
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
        bool? capturedBuilderIsSliver;

        ErrorInfo? capturedListenerErrorInfo;
        Object? capturedListenerError;
        StackTrace? capturedListenerStackTrace;
        VoidCallback? capturedListenerRetry;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
              capturedBuilderErrorInfo = errorInfo;
              capturedBuilderError = error;
              capturedBuilderStackTrace = stackTrace;
              capturedBuilderRetry = onRetry;
              capturedBuilderIsSliver = isSliver;

              return const SizedBox();
            },
            errorStateListener: (errorInfo, error, stackTrace, onRetry) {
              capturedListenerErrorInfo = errorInfo;
              capturedListenerError = error;
              capturedListenerStackTrace = stackTrace;
              capturedListenerRetry = onRetry;
            },
            dataBuilder: (_) => const SizedBox(),
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
        expect(capturedBuilderIsSliver, isTrue);

        expect(capturedListenerErrorInfo, same(expectedErrorInfo));
        expect(capturedListenerError, same(expectedError));
        expect(capturedListenerStackTrace, same(expectedStackTrace));
        expect(capturedListenerRetry, isNotNull);

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
        bool? capturedBuilderIsSliver;

        String? capturedListenerMessage;
        double? capturedListenerProgress;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            loadingBuilder: (message, progress, isSliver) {
              capturedBuilderMessage = message;
              capturedBuilderProgress = progress;
              capturedBuilderIsSliver = isSliver;

              return const SizedBox();
            },
            loadingStateListener: (message, progress) {
              capturedListenerMessage = message;
              capturedListenerProgress = progress;
            },
            dataBuilder: (_) => const SizedBox(),
            isSliver: true,
          ),
        );

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedBuilderMessage, 'Loading');
        expect(capturedBuilderProgress, 0.4);
        expect(capturedBuilderIsSliver, isTrue);

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
        bool? capturedBuilderIsSliver;

        String? capturedListenerMessage;

        await tester.pumpWidget(
          buildConsumer(
            providers: () => provider.watch,
            emptyBuilder: (message, isSliver) {
              capturedBuilderMessage = message;
              capturedBuilderIsSliver = isSliver;

              return const SizedBox();
            },
            emptyStateListener: (message) {
              capturedListenerMessage = message;
            },
            dataBuilder: (_) => const SizedBox(),
            isSliver: true,
          ),
        );

        provider.emit(const EmptyState<String>('Nothing found'));

        await tester.pump();

        expect(capturedBuilderMessage, 'Nothing found');
        expect(capturedBuilderIsSliver, isTrue);
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
            dataBuilder: (_) => const SizedBox(),
            dataStateListener: (_) {
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
            loadingBuilder: (_, __, ___) => const SizedBox(),
            dataBuilder: (_) => const SizedBox(),
            loadingStateListener: (message, progress) {
              capturedMessage = message;
              capturedProgress = progress;
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
          dataBuilder: (_) => const SizedBox(),
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

    // -------------------------------------------------------------------------
    // isSliver
    // -------------------------------------------------------------------------

    testWidgets('passes isSliver to every explicit non-data state builder', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      bool? initialIsSliver;
      bool? loadingIsSliver;
      bool? emptyIsSliver;
      bool? errorIsSliver;

      await tester.pumpWidget(
        buildConsumer(
          providers: () => provider.watch,
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
          isSliver: true,
        ),
      );

      expect(initialIsSliver, isTrue);

      provider.emit(const LoadingState<String>('loading'));

      await tester.pump();

      expect(loadingIsSliver, isTrue);

      provider.emit(const EmptyState<String>('empty'));

      await tester.pump();

      expect(emptyIsSliver, isTrue);

      provider.emit(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pump();

      expect(errorIsSliver, isTrue);
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
            initialStateBuilder: (_) => const SizedBox(),
            loadingStateBuilder: (_, __, isSliver) {
              capturedIsSliver = isSliver;
              return const SizedBox();
            },
            emptyStateBuilder: (_, __) => const SizedBox(),
            errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
            child: wrap(
              MultiViewStateConsumer<ViewState<String>>(
                providers: () => provider.watch,
                dataBuilder: (_) => const SizedBox(),
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

    testWidgets('subscribes to every provider accessed through watch', (
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
          dataBuilder: (_) {
            builderCalls++;
            return const SizedBox();
          },
          dataStateListener: (_) {
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
      'subscribes only once when the same provider is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int builderCalls = 0;
        int listenerCalls = 0;

        await tester.pumpWidget(
          buildConsumer<({ViewState<String> first, ViewState<String> second})>(
            providers: () => (first: provider.watch, second: provider.watch),
            dataBuilder: (_) {
              builderCalls++;
              return const SizedBox();
            },
            dataStateListener: (_) {
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
      'throws AssertionError when providers does not watch any state source',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            MultiViewStateConsumer<ViewState<String>>(
              providers: () => const DataState<String>('data'),
              dataBuilder: (_) => const SizedBox(),
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
            MultiViewStateConsumer<String>(
              providers: () => field.watch,
              dataBuilder: (_) => const SizedBox(),
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

    testWidgets('switches subscriptions when the watched provider changes', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      MultiStateProviders<ViewState<String>> providers = () => provider1.watch;

      int builderCalls = 0;
      int listenerCalls = 0;

      String? capturedValue;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: <Widget>[
                  MultiViewStateConsumer<ViewState<String>>(
                    providers: providers,
                    dataBuilder: (state) {
                      builderCalls++;
                      capturedValue = state.data;

                      return Text(state.data);
                    },
                    dataStateListener: (_) {
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
      'does not duplicate provider notifications after parent rebuild with the same dependency',
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
                    MultiViewStateConsumer<ViewState<String>>(
                      providers: () => provider.watch,
                      dataBuilder: (_) {
                        builderCalls++;
                        return const SizedBox();
                      },
                      dataStateListener: (_) {
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
          dataBuilder: (_) => const SizedBox(),
          dataStateListener: (_) {},
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

        MultiViewStateConsumer<({ViewState<int> value})>(
          providers: () => (value: provider.watch),
          initialBuilder: (_) => const SizedBox(),
          loadingBuilder: (_, __, ___) => const SizedBox(),
          emptyBuilder: (_, __) => const SizedBox(),
          errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          dataBuilder: (_) => const SizedBox(),
          initialStateListener: () {},
          loadingStateListener: (_, __) {},
          emptyStateListener: (_) {},
          errorStateListener: (_, __, ___, ____) {},
          dataStateListener: (_) {},
          rebuildWhen: (_, __) => true,
          listenWhen: (_, __) => true,
          callListenerOnInit: true,
          isSliver: true,
        ).debugFillProperties(diagnostics);

        final description = diagnostics.properties
            .where((node) => !node.isFiltered(DiagnosticLevel.info))
            .map((node) => node.toString())
            .toList();

        expect(description.any((value) => value.contains('providers')), isTrue);

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
