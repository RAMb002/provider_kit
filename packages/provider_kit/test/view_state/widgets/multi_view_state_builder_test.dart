import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

typedef TwoStates = ({ViewState<String> first, ViewState<String> second});
// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider keys.
// -----------------------------------------------------------------------------

const _defaultInitialKey = Key('default_initial');

const _defaultLoadingKey = Key('default_loading');

const _defaultEmptyKey = Key('default_empty');

const _defaultErrorKey = Key('default_error');

void main() {
  group('ViewStateBuilder.multi', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    Widget defaultProviderWidget(Widget child) {
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

    Widget buildBuilder<T>({
      required MultiStateListenables<T> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      RebuildWhen<T>? rebuildWhen,
      bool isSliver = false,
      bool withDefaultProvider = false,
      Widget? child,
    }) {
      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: ViewStateBuilder.multi(
          listenables: providers,
          initialBuilder: initialBuilder,
          loadingBuilder: loadingBuilder,
          emptyBuilder: emptyBuilder,
          errorBuilder: errorBuilder,
          dataBuilder: dataBuilder,
          rebuildWhen: rebuildWhen,
          isSliver: isSliver,
          child: child,
        ),
      );

      if (withDefaultProvider) {
        widget = defaultProviderWidget(widget);
      }

      return widget;
    }

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
          buildBuilder<TwoStates>(
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

        // The same child widget is passed again, without rebuilding its subtree.
        expect(childBuildCount, 1);
        expect(receivedChildren, hasLength(2));
        expect(
          receivedChildren.every((child) => identical(child, staticChild)),
          isTrue,
        );
      },
    );

    // =========================================================================
    // DATA BUILDING
    // =========================================================================

    testWidgets('renders dataBuilder with the exact combined state', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<int>(const DataState<int>(10));

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('hello'),
      );

      ({ViewState<int> count, ViewState<String> name})? capturedState;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (count: provider1.watch, name: provider2.watch),
          dataBuilder: (_, state, __) {
            capturedState = state;

            return Text('${state.count.data}-${state.name.data}');
          },
        ),
      );

      expect(capturedState, isNotNull);
      expect(capturedState!.count, same(provider1.state));
      expect(capturedState!.name, same(provider2.state));
      expect(find.text('10-hello'), findsOneWidget);
    });

    testWidgets('supports a list as the combined state', (tester) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      List<ViewState<String>>? capturedState;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => [provider1.watch, provider2.watch],
          dataBuilder: (_, state, __) {
            capturedState = state;

            return Text('${state[0].data}-${state[1].data}');
          },
        ),
      );

      expect(capturedState, isNotNull);
      expect(capturedState, hasLength(2));
      expect(capturedState![0], same(provider1.state));
      expect(capturedState![1], same(provider2.state));
      expect(find.text('one-two'), findsOneWidget);
    });

    // =========================================================================
    // STATE BUILDER DISPATCH
    // =========================================================================

    testWidgets(
      'invokes only the corresponding builder and provides a usable context',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );
        addTearDown(provider.dispose);

        final renderedStates = <String>[];

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
            child: buildBuilder(
              providers: () => provider.watch,
              initialBuilder: (context) {
                expectContext(context);
                renderedStates.add('initial');
                return const SizedBox();
              },
              loadingBuilder: (context, details) {
                expectContext(context);
                renderedStates.add(
                  'loading:${details.message}:${details.progress}',
                );
                return const SizedBox();
              },
              emptyBuilder: (context, details) {
                expectContext(context);
                renderedStates.add('empty:${details.message}');
                return const SizedBox();
              },
              errorBuilder: (context, details) {
                expectContext(context);
                renderedStates.add('error:${details.message}');
                return const SizedBox();
              },
              dataBuilder: (context, state, child) {
                expectContext(context);
                renderedStates.add('data:${state.data}');
                return const SizedBox();
              },
            ),
          ),
        );

        expect(renderedStates, ['data:data']);

        provider.emit(const InitialState<String>());
        await tester.pump();
        expect(renderedStates, ['data:data', 'initial']);

        provider.emit(const LoadingState<String>('Loading', 0.5));
        await tester.pump();
        expect(renderedStates, ['data:data', 'initial', 'loading:Loading:0.5']);

        provider.emit(const EmptyState<String>('Empty'));
        await tester.pump();
        expect(renderedStates, [
          'data:data',
          'initial',
          'loading:Loading:0.5',
          'empty:Empty',
        ]);

        provider.emit(
          ErrorState<String>(
            StateError('error'),
            StackTrace.current,
            errorInfo: const ErrorInfo(message: 'Error'),
          ),
        );
        await tester.pump();
        expect(renderedStates, [
          'data:data',
          'initial',
          'loading:Loading:0.5',
          'empty:Empty',
          'error:Error',
        ]);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();
        expect(renderedStates, [
          'data:data',
          'initial',
          'loading:Loading:0.5',
          'empty:Empty',
          'error:Error',
          'data:updated',
        ]);
      },
    );
    // =========================================================================
    // BUILDER PARAMETERS
    // =========================================================================

    testWidgets(
      'errorBuilder receives error details retry callback unchanged',
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

        int retryCalls = 0;

        ErrorInfo? capturedErrorInfo;
        Object? capturedError;
        StackTrace? capturedStackTrace;
        VoidCallback? capturedOnRetry;
        String? captureErrorMessage;
        String? capturedErrorCode;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            errorBuilder: (_, details) {
              capturedErrorInfo = details.errorInfo;
              capturedError = details.error;
              capturedStackTrace = details.stackTrace;
              capturedOnRetry = details.onRetry;
              captureErrorMessage = details.message;
              capturedErrorCode = details.code;
              return const SizedBox();
            },
            dataBuilder: (_, __, ___) => const SizedBox(),
          ),
        );

        provider.emit(
          ErrorState<String>(
            expectedError,
            expectedStackTrace,
            errorInfo: expectedErrorInfo,
            onRetry: () {
              retryCalls++;
            },
          ),
        );

        await tester.pump();

        expect(capturedErrorInfo, same(expectedErrorInfo));
        expect(capturedError, same(expectedError));
        expect(capturedStackTrace, same(expectedStackTrace));
        expect(capturedOnRetry, isNotNull);
        expect(captureErrorMessage, expectedErrorInfo.message);
        expect(capturedErrorCode, expectedErrorInfo.code);

        capturedOnRetry!();

        expect(retryCalls, 1);
      },
    );

    testWidgets('loadingBuilder receives message and progress unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          loadingBuilder: (_, details) {
            capturedMessage = details.message;
            capturedProgress = details.progress;

            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
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
    });

    testWidgets('emptyBuilder receives the message unchanged', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      String? capturedMessage;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          emptyBuilder: (_, details) {
            capturedMessage = details.message;

            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider.emit(const EmptyState<String>('Nothing found'));

      await tester.pump();

      expect(capturedMessage, 'Nothing found');
    });

    // =========================================================================
    // DEFAULT WIDGET FALLBACKS
    // =========================================================================

    testWidgets('uses default initial widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState<String>('loading'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const EmptyState<String>('empty'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(StateError('error'), StackTrace.current),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    testWidgets(
      'uses explicit state builders instead of ViewStateWidgetsProvider defaults',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );

        final renderedStates = <String>[];

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            initialBuilder: (_) {
              renderedStates.add('initial');
              return const SizedBox(key: Key('custom_initial'));
            },
            loadingBuilder: (_, __) {
              renderedStates.add('loading');
              return const SizedBox(key: Key('custom_loading'));
            },
            emptyBuilder: (_, __) {
              renderedStates.add('empty');
              return const SizedBox(key: Key('custom_empty'));
            },
            errorBuilder: (_, __) {
              renderedStates.add('error');
              return const SizedBox(key: Key('custom_error'));
            },
            dataBuilder: (_, __, ___) {
              renderedStates.add('data');
              return const SizedBox(key: Key('custom_data'));
            },
            withDefaultProvider: true,
          ),
        );

        expect(renderedStates.last, 'initial');
        expect(find.byKey(const Key('custom_initial')), findsOneWidget);
        expect(find.byKey(_defaultInitialKey), findsNothing);
        provider.emit(const LoadingState<String>('loading'));

        await tester.pump();

        expect(renderedStates.last, 'loading');
        expect(find.byKey(const Key('custom_loading')), findsOneWidget);
        expect(find.byKey(_defaultLoadingKey), findsNothing);
        provider.emit(const EmptyState<String>('empty'));

        await tester.pump();

        expect(renderedStates.last, 'empty');
        expect(find.byKey(const Key('custom_empty')), findsOneWidget);
        expect(find.byKey(_defaultEmptyKey), findsNothing);
        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );

        await tester.pump();

        expect(renderedStates.last, 'error');
        expect(find.byKey(const Key('custom_error')), findsOneWidget);
        expect(find.byKey(_defaultErrorKey), findsNothing);
        provider.emit(const DataState<String>('data'));

        await tester.pump();

        expect(renderedStates.last, 'data');
        expect(find.byKey(const Key('custom_data')), findsOneWidget);
      },
    );

    testWidgets('default ViewStateWidgetsProvider builders receive isSliver', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState<String>('loading'),
      );
      bool? capturedIsSliver;

      await tester.pumpWidget(
        ViewStateWidgetsProvider(
          initialStateBuilder: testDefaultInitialStateBuilder,
          loadingStateBuilder: (_, __, isSliver) {
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          emptyStateBuilder: testDefaultEmptyStateBuilder,
          errorStateBuilder: testDefaultErrorStateBuilder,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder.multi(
              listenables: () => provider.watch,
              isSliver: true,
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(capturedIsSliver, isTrue);
    });

    // =========================================================================
    // DEPENDENCY TRACKING
    // =========================================================================

    testWidgets('subscribes to every listenable accessed through watch', (
      tester,
    ) async {
      final provider1 = TestViewStateNotifier<String>(
        const DataState<String>('one'),
      );

      final provider2 = TestViewStateNotifier<String>(
        const DataState<String>('two'),
      );

      int dataBuilds = 0;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => (first: provider1.watch, second: provider2.watch),
          dataBuilder: (_, __, ___) {
            dataBuilds++;
            return const SizedBox();
          },
        ),
      );

      expect(dataBuilds, 1);
      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataBuilds, 2);
      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();
      expect(dataBuilds, 3);
    });

    testWidgets(
      'subscribes only once when the same listenable is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataBuilds = 0;

        await tester.pumpWidget(
          wrap(
            ViewStateBuilder.multi(
              listenables: () =>
                  (first: provider.watch, second: provider.watch),
              dataBuilder: (_, __, ___) {
                dataBuilds++;

                return const SizedBox();
              },
            ),
          ),
        );

        expect(dataBuilds, 1);

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(dataBuilds, 2);
      },
    );

    testWidgets(
      'throws StateError when a watched dependency is not a ViewStateNotifier',
      (tester) async {
        final field = StateField<String>('data');

        await tester.pumpWidget(
          wrap(
            ViewStateBuilder.multi(
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

    testWidgets(
      'throws AssertionError when listenables does not watch any state source',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            ViewStateBuilder.multi(
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

    // =========================================================================
    // RUNTIME DEPENDENCY REPLACEMENT
    // =========================================================================

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

      int dataBuilds = 0;

      String? capturedValue;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: <Widget>[
                  ViewStateBuilder.multi(
                    listenables: providers,
                    dataBuilder: (_, state, __) {
                      dataBuilds++;
                      capturedValue = state.data;

                      return Text(state.data);
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

      expect(dataBuilds, 1);
      expect(capturedValue, 'one');
      provider1.emit(const DataState<String>('one-new'));

      await tester.pump();

      expect(dataBuilds, 2);
      expect(capturedValue, 'one-new');

      await tester.tap(find.text('Switch'));
      await tester.pump();

      expect(capturedValue, 'two');
      provider1.emit(const DataState<String>('one-after-switch'));

      await tester.pump();
      expect(capturedValue, 'two');
      provider2.emit(const DataState<String>('two-new'));

      await tester.pump();
      expect(capturedValue, 'two-new');
    });

    testWidgets(
      'does not duplicate listenable notifications after rebuilding with the same dependency',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataBuilds = 0;

        Widget buildWidget() {
          return buildBuilder(
            providers: () => provider.watch,
            dataBuilder: (_, state, __) {
              dataBuilds++;

              return Text(state.data);
            },
          );
        }

        await tester.pumpWidget(buildWidget());
        expect(dataBuilds, 1);

        provider.emit(const DataState<String>('first'));
        await tester.pump();
        expect(dataBuilds, 2);

        await tester.pumpWidget(buildWidget());

        expect(dataBuilds, 3);
        provider.emit(const DataState<String>('second'));

        await tester.pump();
        expect(dataBuilds, 4);
      },
    );
    // =========================================================================
    // CLEANUP
    // =========================================================================

    testWidgets('detaches dependencies when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    testWidgets(
      'updates the localized message when locale changes without a state change',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('profile.loading'),
        );
        addTearDown(provider.dispose);

        final originalState = provider.state;
        var locale = 'en';
        late StateSetter changeLocale;
        final renderedMessages = <String?>[];

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
                    child: ViewStateBuilder.multi(
                      listenables: () => provider.watch,
                      loadingBuilder: (context, details) {
                        renderedMessages.add(details.message);
                        return Text(details.message ?? '');
                      },
                      dataBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('en:profile.loading'), findsOneWidget);
        expect(renderedMessages, ['en:profile.loading']);

        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(find.text('en:profile.loading'), findsNothing);
        expect(find.text('fr:profile.loading'), findsOneWidget);
        expect(renderedMessages, ['en:profile.loading', 'fr:profile.loading']);

        // A locale change updates presentation, not the underlying view state.
        expect(identical(provider.state, originalState), isTrue);
      },
    );

    // =========================================================================
    // DIAGNOSTICS
    // =========================================================================

    testWidgets(
      'debugFillProperties exposes MultiViewStateBuilder properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<int>(const DataState<int>(1));

        ViewStateBuilder.multi(
          listenables: () => (value: provider.watch),
          initialBuilder: (_) => const SizedBox(),
          loadingBuilder: (_, __) => const SizedBox(),
          emptyBuilder: (_, __) => const SizedBox(),
          errorBuilder: (_, __) => const SizedBox(),
          dataBuilder: (_, __, ___) => const SizedBox(),
          isSliver: true,
          child: const SizedBox(),
          rebuildWhen: (_, __) => true,
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
      },
    );
  });
}
