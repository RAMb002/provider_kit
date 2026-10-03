import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/view_state_notifiers.dart';

typedef TwoStates = ({ViewState<String> first, ViewState<String> second});
// -----------------------------------------------------------------------------
// Default ViewStateWidgetsProvider keys.
// -----------------------------------------------------------------------------

const _defaultInitialKey = Key('default_initial');

const _defaultLoadingKey = Key('default_loading');

const _defaultEmptyKey = Key('default_empty');

const _defaultErrorKey = Key('default_error');

void main() {
  group('MultiViewStateBuilder', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    Widget wrap(Widget child) {
      return Directionality(textDirection: TextDirection.ltr, child: child);
    }

    Widget defaultProviderWidget(Widget child) {
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

    Widget buildBuilder<T>({
      required MultiStateProviders<T> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<T> dataBuilder,
      RebuildWhen<T>? rebuildWhen,
      bool isSliver = false,
      bool withDefaultProvider = false,
    }) {
      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: MultiViewStateBuilder<T>(
          providers: providers,
          initialBuilder: initialBuilder,
          loadingBuilder: loadingBuilder,
          emptyBuilder: emptyBuilder,
          errorBuilder: errorBuilder,
          dataBuilder: dataBuilder,
          rebuildWhen: rebuildWhen,
          isSliver: isSliver,
        ),
      );

      if (withDefaultProvider) {
        widget = defaultProviderWidget(widget);
      }

      return widget;
    }

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
          dataBuilder: (state) {
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
          dataBuilder: (state) {
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
      'invokes the corresponding builder when the watched provider enters each state',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        final renderedStates = <String>[];

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            initialBuilder: (isSliver) {
              renderedStates.add('initial:$isSliver');
              return const SizedBox();
            },
            loadingBuilder: (message, progress, isSliver) {
              renderedStates.add('loading:$message:$progress:$isSliver');
              return const SizedBox();
            },
            emptyBuilder: (message, isSliver) {
              renderedStates.add('empty:$message:$isSliver');
              return const SizedBox();
            },
            errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
              renderedStates.add('error:${errorInfo.message}:$isSliver');
              return const SizedBox();
            },
            dataBuilder: (state) {
              renderedStates.add('data:${state.data}');
              return const SizedBox();
            },
          ),
        );

        expect(renderedStates, ['data:data']);

        provider.emit(const InitialState<String>());

        await tester.pump();

        expect(renderedStates.last, 'initial:false');

        provider.emit(const LoadingState<String>('Loading', 0.5));

        await tester.pump();

        expect(renderedStates.last, 'loading:Loading:0.5:false');

        provider.emit(const EmptyState<String>('Empty'));

        await tester.pump();

        expect(renderedStates.last, 'empty:Empty:false');

        provider.emit(
          ErrorState<String>(
            StateError('error'),
            StackTrace.current,
            errorInfo: const ErrorInfo(message: 'Error'),
          ),
        );

        await tester.pump();

        expect(renderedStates.last, 'error:Error:false');

        provider.emit(const DataState<String>('updated'));

        await tester.pump();

        expect(renderedStates.last, 'data:updated');
      },
    );

    // =========================================================================
    // BUILDER PARAMETERS
    // =========================================================================

    testWidgets(
      'errorBuilder receives error details retry callback and isSliver unchanged',
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

        bool? capturedIsSliver;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
            errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
              capturedErrorInfo = errorInfo;
              capturedError = error;
              capturedStackTrace = stackTrace;
              capturedOnRetry = onRetry;
              capturedIsSliver = isSliver;

              return const SizedBox();
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
              retryCalls++;
            },
          ),
        );

        await tester.pump();

        expect(capturedErrorInfo, same(expectedErrorInfo));
        expect(capturedError, same(expectedError));
        expect(capturedStackTrace, same(expectedStackTrace));
        expect(capturedOnRetry, isNotNull);
        expect(capturedIsSliver, isTrue);

        capturedOnRetry!();

        expect(retryCalls, 1);
      },
    );

    testWidgets(
      'loadingBuilder receives message progress and isSliver unchanged',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        String? capturedMessage;

        double? capturedProgress;

        bool? capturedIsSliver;

        await tester.pumpWidget(
          buildBuilder(
            providers: () => provider.watch,
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

        provider.emit(const LoadingState<String>('Loading', 0.4));

        await tester.pump();

        expect(capturedMessage, 'Loading');
        expect(capturedProgress, 0.4);
        expect(capturedIsSliver, isTrue);

        provider.emit(const LoadingState<String>('Loading without progress'));

        await tester.pump();

        expect(capturedMessage, 'Loading without progress');
        expect(capturedProgress, isNull);
        expect(capturedIsSliver, isTrue);
      },
    );

    testWidgets('emptyBuilder receives the message and isSliver unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState<String>('data'),
      );

      String? capturedMessage;

      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          emptyBuilder: (message, isSliver) {
            capturedMessage = message;
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      provider.emit(const EmptyState<String>('Nothing found'));

      await tester.pump();

      expect(capturedMessage, 'Nothing found');
      expect(capturedIsSliver, isTrue);
    });

    testWidgets('initialBuilder receives the isSliver flag unchanged', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const InitialState<String>(),
      );

      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: () => provider.watch,
          initialBuilder: (isSliver) {
            capturedIsSliver = isSliver;

            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedIsSliver, isTrue);
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
          dataBuilder: (_) => const SizedBox(),
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
          dataBuilder: (_) => const SizedBox(),
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
          dataBuilder: (_) => const SizedBox(),
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
          dataBuilder: (_) => const SizedBox(),
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
            loadingBuilder: (_, __, ___) {
              renderedStates.add('loading');
              return const SizedBox(key: Key('custom_loading'));
            },
            emptyBuilder: (_, __) {
              renderedStates.add('empty');
              return const SizedBox(key: Key('custom_empty'));
            },
            errorBuilder: (_, __, ___, ____, _____) {
              renderedStates.add('error');
              return const SizedBox(key: Key('custom_error'));
            },
            dataBuilder: (_) {
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

    // =========================================================================
    // DEPENDENCY TRACKING
    // =========================================================================

    testWidgets('subscribes to every provider accessed through watch', (
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
          dataBuilder: (_) {
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
      'subscribes only once when the same provider is watched multiple times',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataBuilds = 0;

        await tester.pumpWidget(
          wrap(
            MultiViewStateBuilder<TwoStates>(
              providers: () => (first: provider.watch, second: provider.watch),
              dataBuilder: (_) {
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
            MultiViewStateBuilder<String>(
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

    testWidgets(
      'throws AssertionError when providers does not watch any state source',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            MultiViewStateBuilder<ViewState<String>>(
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

    // =========================================================================
    // RUNTIME DEPENDENCY REPLACEMENT
    // =========================================================================

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

      int dataBuilds = 0;

      String? capturedValue;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: <Widget>[
                  MultiViewStateBuilder<ViewState<String>>(
                    providers: providers,
                    dataBuilder: (state) {
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
      'does not duplicate provider notifications after rebuilding with the same dependency',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('data'),
        );

        int dataBuilds = 0;

        Widget buildWidget() {
          return buildBuilder(
            providers: () => provider.watch,
            dataBuilder: (state) {
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
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =========================================================================
    // DIAGNOSTICS
    // =========================================================================

    testWidgets(
      'debugFillProperties exposes MultiViewStateBuilder properties',
      (tester) async {
        final diagnostics = DiagnosticPropertiesBuilder();

        final provider = TestViewStateNotifier<int>(const DataState<int>(1));

        MultiViewStateBuilder<({ViewState<int> value})>(
          providers: () => (value: provider.watch),
          initialBuilder: (_) => const SizedBox(),
          loadingBuilder: (_, __, ___) => const SizedBox(),
          emptyBuilder: (_, __) => const SizedBox(),
          errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
          rebuildWhen: (_, __) => true,
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
      },
    );
  });
}
