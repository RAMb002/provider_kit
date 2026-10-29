import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/future_notifier.dart';
import '../../shared/mocks/view_state_notifiers.dart';
import '../../shared/view_state_message_resolver_helpers.dart';

// -----------------------------------------------------------------------------
// Helper to provide default ViewStateWidgetsProvider keys once.
// -----------------------------------------------------------------------------
const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

Widget _withDefaultProvider(Widget child) {
  return ViewStateWidgetsProvider(
    initialStateBuilder: (_, __) => const SizedBox(key: _defaultInitialKey),
    loadingStateBuilder: (_, __, ___) =>
        const SizedBox(key: _defaultLoadingKey),
    emptyStateBuilder: (_, __, ___) => const SizedBox(key: _defaultEmptyKey),
    errorStateBuilder: (_, __, ___) => const SizedBox(key: _defaultErrorKey),
    child: child,
  );
}

void main() {
  group('ViewStateBuilder', () {
    // -----------------------------------------------------------------------
    // 1. Basic Rendering & Builder Calls
    // -----------------------------------------------------------------------

    // Helper to pump a ViewStateBuilder with optional local builders and provider.
    Widget buildBuilder({
      required TestViewStateNotifier<String> provider,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required DataStateBuilder<String> dataBuilder,
      RebuildWhen<ViewState<String>>? rebuildWhen,
      bool isSliver = false,
      bool withDefaultProvider = false,
      Widget? child,
    }) {
      final builder = ViewStateBuilder<String>(
        listenable: provider,
        initialBuilder: initialBuilder,
        loadingBuilder: loadingBuilder,
        emptyBuilder: emptyBuilder,
        errorBuilder: errorBuilder,
        dataBuilder: dataBuilder,
        rebuildWhen: rebuildWhen,
        isSliver: isSliver,
        child: child,
      );

      Widget widget = Directionality(
        textDirection: TextDirection.ltr,
        child: builder,
      );

      if (withDefaultProvider) {
        widget = _withDefaultProvider(widget);
      }
      return widget;
    }

    // ----------------------------------------------------------------
    // 1.1 DataBuilder (required)
    // ----------------------------------------------------------------
    testWidgets('dataBuilder is required and called for DataState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const DataState('Hello'));
      String? capturedData;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_, data, __) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, 'Hello');
    });

    testWidgets(
      'reuses the same child without rebuilding it when data changes',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('first'),
        );

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
          buildBuilder(
            provider: provider,
            child: staticChild,
            dataBuilder: (_, data, child) {
              dataBuilderCallCount++;
              receivedChildren.add(child);

              return Column(children: [Text(data), if (child != null) child]);
            },
          ),
        );

        expect(find.text('first'), findsOneWidget);
        expect(find.text('static child'), findsOneWidget);
        expect(dataBuilderCallCount, 1);
        expect(childBuildCount, 1);
        expect(identical(receivedChildren.first, staticChild), isTrue);

        // Changing the data rebuilds the data builder.
        provider.emit(const DataState<String>('second'));
        await tester.pump();

        expect(find.text('first'), findsNothing);
        expect(find.text('second'), findsOneWidget);

        // The original child is reused and its Builder doesn't rebuild.
        expect(dataBuilderCallCount, 2);
        expect(childBuildCount, 1);
        expect(receivedChildren, hasLength(2));
        expect(
          receivedChildren.every((child) => identical(child, staticChild)),
          isTrue,
        );
      },
    );

    // ----------------------------------------------------------------
    // 1.2 InitialBuilder
    // ----------------------------------------------------------------
    testWidgets('calls initialBuilder when state is InitialState', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialBuilt = false;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          initialBuilder: (_) {
            initialBuilt = true;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(initialBuilt, true);
    });

    // ----------------------------------------------------------------
    // 1.3 LoadingBuilder
    // ----------------------------------------------------------------
    testWidgets('calls loadingBuilder with correct parameters', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const LoadingState('Loading', 0.7),
      );
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          loadingBuilder: (_, details) {
            capturedMessage = details.message;
            capturedProgress = details.progress;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'Loading');
      expect(capturedProgress, 0.7);
    });

    // ----------------------------------------------------------------
    // 1.4 EmptyBuilder
    // ----------------------------------------------------------------
    testWidgets('calls emptyBuilder with message', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const EmptyState('No data'),
      );
      String? capturedMessage;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          emptyBuilder: (_, details) {
            capturedMessage = details.message;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'No data');
    });

    // ----------------------------------------------------------------
    // 1.5 ErrorBuilder
    // ----------------------------------------------------------------
    testWidgets('calls errorBuilder with correct parameters', (tester) async {
      final error = Exception('boom');
      final stackTrace = StackTrace.current;

      const errorInfo = ErrorInfo(message: 'Error', code: 'boom');

      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(
          error,
          stackTrace,
          errorInfo: errorInfo,
          onRetry: () {},
        ),
      );

      ErrorInfo? capturedErrorInfo;
      VoidCallback? capturedOnRetry;
      Object? capturedError;
      StackTrace? capturedStackTrace;
      String? capturedMessage;
      String? capturedCode;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          errorBuilder: (_, details) {
            capturedErrorInfo = details.errorInfo;
            capturedOnRetry = details.onRetry;
            capturedError = details.error;
            capturedStackTrace = details.stackTrace;
            capturedMessage = details.message;
            capturedCode = details.code;
            return const SizedBox();
          },
          dataBuilder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(capturedErrorInfo, same(errorInfo));
      expect(capturedError, same(error));
      expect(capturedStackTrace, same(stackTrace));
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedMessage, 'Error');
      expect(capturedCode, 'boom');
    });

    // -----------------------------------------------------------------------
    // 2. Fallback to ViewStateWidgetsProvider when local builder is null
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from ViewStateWidgetsProvider', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(const EmptyState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
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
        ErrorState<String>(Exception('Error'), StackTrace.current),
      );

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_, __, ___) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    testWidgets(
      'throws assertion when state is not DataState and no specific builder or ViewStateWidgetProvider is available',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<String>(
              listenable: provider,
              // No initialBuilder, no ViewStateWidgetsProvider
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        // The assertion is from ViewStateWidgetsProvider.of
        expect(tester.takeException(), isA<AssertionError>());
      },
    );

    testWidgets(
      'updates the localized message when locale changes without a state change',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('profile.loading'),
        );
        addTearDown(provider.dispose);

        var locale = 'en';
        late StateSetter changeLocale;
        var loadingBuilderCallCount = 0;

        final originalState = provider.state;

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
                    child: ViewStateBuilder<String>(
                      listenable: provider,
                      loadingBuilder: (context, details) {
                        loadingBuilderCallCount++;
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
        final callsBeforeLocaleChange = loadingBuilderCallCount;

        // Change the inherited locale without emitting a new state.
        changeLocale(() {
          locale = 'fr';
        });
        await tester.pump();

        expect(find.text('en:profile.loading'), findsNothing);
        expect(find.text('fr:profile.loading'), findsOneWidget);

        // The builder must react to the inherited locale change.
        expect(loadingBuilderCallCount, greaterThan(callsBeforeLocaleChange));

        // No state transition occurred.
        expect(identical(provider.state, originalState), isTrue);
      },
    );

    testWidgets(
      'calls only the matching state builder and provides a usable context',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          const InitialState<String>(),
        );

        final calledBuilders = <String>[];

        void expectContext(BuildContext context) {
          expect(
            context
                .findAncestorWidgetOfExactType<TestLocaleInherited>()
                ?.locale,
            'en',
          );
        }

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: TestLocaleInherited(
              locale: 'en',
              child: ViewStateBuilder<String>(
                listenable: provider,
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
                dataBuilder: (context, data, child) {
                  expectContext(context);
                  calledBuilders.add('data');
                  return Text(data);
                },
              ),
            ),
          ),
        );

        expect(calledBuilders, ['initial']);

        provider.emit(const LoadingState<String>('loading'));
        await tester.pump();
        expect(calledBuilders, ['initial', 'loading']);

        provider.emit(const EmptyState<String>('empty'));
        await tester.pump();
        expect(calledBuilders, ['initial', 'loading', 'empty']);

        provider.emit(
          ErrorState<String>(
            StateError('Something went wrong'),
            StackTrace.current,
          ),
        );
        await tester.pump();
        expect(calledBuilders, ['initial', 'loading', 'empty', 'error']);

        provider.emit(const DataState<String>('loaded'));
        await tester.pump();
        expect(calledBuilders, [
          'initial',
          'loading',
          'empty',
          'error',
          'data',
        ]);

        expect(find.text('loaded'), findsOneWidget);
      },
    );
    // -----------------------------------------------------------------------
    // 3. onRetry resolution
    // -----------------------------------------------------------------------
    testWidgets(
      'errorBuilder receives onRetry from FutureNotifier when not explicitly set',
      (tester) async {
        final exception = Exception('Test');
        final provider = MockFutureNotifier<String>(
          buildImpl: () => throw exception,
        );
        addTearDown(provider.dispose);
        await tester.pumpAndSettle();

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(capturedOnRetry, isNotNull);
        capturedOnRetry!();
        expect(provider.refreshCalls, 1);
      },
    );

    testWidgets(
      'errorBuilder receives explicit onRetry from ErrorState, overriding the notifier retry callback',
      (tester) async {
        final provider = MockFutureNotifier<String>(
          buildImpl: () => throw Exception('Test'),
        );
        await tester.pumpAndSettle();
        var retryCalls = 0;

        VoidCallback? capturedOnRetry;
        void explicitOnRetry() {
          retryCalls++;
        }

        // Emit a new ErrorState with explicit onRetry
        provider.state = ErrorState<String>(
          Exception('Error'),
          StackTrace.current,
          onRetry: explicitOnRetry,
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        expect(capturedOnRetry, explicitOnRetry);
        capturedOnRetry!();

        expect(retryCalls, 1);
      },
    );

    testWidgets(
      'errorBuilder receives null onRetry when listenable is not a FutureNotifier',
      (tester) async {
        final provider = TestViewStateNotifier<String>(
          ErrorState<String>(Exception('Error'), StackTrace.current),
        );

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<String>(
              listenable: provider,
              errorBuilder: (_, details) {
                capturedOnRetry = details.onRetry;
                return const SizedBox();
              },
              dataBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        );

        // Since listenable is not FutureNotifier, onRetry should be null.
        expect(capturedOnRetry, isNull);
      },
    );

    testWidgets('invokes explicit ErrorState onRetry callback', (tester) async {
      final provider = MockFutureNotifier<String>(
        buildImpl: () => throw Exception('Test'),
      );

      await tester.pumpAndSettle();

      var retryCalls = 0;

      provider.state = ErrorState<String>(
        StateError('Error'),
        StackTrace.current,
        onRetry: () => retryCalls++,
      );

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<String>(
            listenable: provider,
            errorBuilder: (_, details) {
              capturedOnRetry = details.onRetry;
              return const SizedBox();
            },
            dataBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, isNotNull);

      capturedOnRetry!();

      expect(retryCalls, 1);
    });

    testWidgets(
      'uses context notifier refresh when ErrorState has no onRetry callback',
      (tester) async {
        var buildCalls = 0;

        final provider = MockFutureNotifier<String>(
          buildImpl: () => 'data${++buildCalls}',
        );

        addTearDown(provider.dispose);

        VoidCallback? capturedOnRetry;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChangeNotifierProvider<MockFutureNotifier<String>>.value(
              value: provider,
              child: ViewStateBuilder.of<MockFutureNotifier<String>, String>(
                errorBuilder: (_, details) {
                  capturedOnRetry = details.onRetry;
                  return const SizedBox();
                },
                dataBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        );

        // Finish the initial build.
        await tester.pumpAndSettle();

        expect(provider.state, const DataState<String>('data1'));
        expect(buildCalls, 1);

        // Simulate an ErrorState without a retry callback.
        provider.state = ErrorState<String>(
          Exception('Test'),
          StackTrace.current,
          onRetry: null,
        );

        await tester.pump();

        expect(capturedOnRetry, isNotNull);

        // The widget should fall back to the provider's refresh method.
        capturedOnRetry!();

        expect(provider.refreshCalls, 1);

        // Verify that the refresh actually runs and succeeds.
        await tester.pumpAndSettle();

        expect(buildCalls, 2);
        expect(provider.state, const DataState<String>('data2'));
      },
    );
    // -----------------------------------------------------------------------
    // 4. rebuildWhen filtering
    // -----------------------------------------------------------------------
    testWidgets('rebuildWhen controls whether builder is called', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('initial'),
      );
      int buildCount = 0;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_, data, __) {
            buildCount++;
            return const SizedBox();
          },
          rebuildWhen: (previous, current) {
            if (current is DataState<String>) {
              return current.data.length > 3;
            }
            return true;
          },
        ),
      );

      expect(buildCount, 1);

      provider.emit(const DataState<String>('abc'));
      await tester.pump();
      expect(buildCount, 1);

      provider.emit(const DataState<String>('abcd'));
      await tester.pump();
      expect(buildCount, 2);

      provider.emit(const DataState<String>('xy'));
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets(
      'rebuildWhen receives correct previous and current states across transitions',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const InitialState());
        List<ViewState<String>> previousList = [];
        List<ViewState<String>> currentList = [];

        await tester.pumpWidget(
          buildBuilder(
            withDefaultProvider: true,
            provider: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
            rebuildWhen: (previous, current) {
              previousList.add(previous);
              currentList.add(current);
              return true;
            },
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

        provider.emit(
          ErrorState<String>(StateError('error'), StackTrace.current),
        );
        await tester.pump();

        expect(previousList.length, 3);
        expect(previousList[2], const DataState<String>('data'));
        expect(currentList[2], isA<ErrorState<String>>());
      },
    );

    // -----------------------------------------------------------------------
    // 5. isSliver flag propagation
    // -----------------------------------------------------------------------

    testWidgets(
      'default widgets from ViewStateWidgetsProvider receive isSliver',
      (tester) async {
        final provider = TestViewStateNotifier<String>(const LoadingState());
        bool? isSliverPassed;

        // Override provider's loading builder to capture isSliver.
        await tester.pumpWidget(
          ViewStateWidgetsProvider(
            initialStateBuilder: (_, __) => const SizedBox(),
            loadingStateBuilder: (_, __, isSliver) {
              isSliverPassed = isSliver;
              return const SizedBox();
            },
            emptyStateBuilder: (_, __, ___) => const SizedBox(),
            errorStateBuilder: (_, __, ___) => const SizedBox(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ViewStateBuilder<String>(
                listenable: provider,
                isSliver: true,
                dataBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
        );

        expect(isSliverPassed, true);
      },
    );

    // -----------------------------------------------------------------------
    // 6. Listenable resolution (explicit vs context)
    // -----------------------------------------------------------------------
    testWidgets('uses explicit listenable when provided', (tester) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('explicit'),
      );
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<String>(
            listenable: provider,
            dataBuilder: (_, data, __) {
              capturedData = data;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedData, 'explicit');
    });

    testWidgets('reads listenable from context using ViewStateBuilder.of', (
      tester,
    ) async {
      final provider = TestViewStateNotifier<String>(
        const DataState('context'),
      );
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateBuilder.of<TestViewStateNotifier<String>, String>(
              dataBuilder: (_, data, __) {
                capturedData = data;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedData, 'context');
    });

    // -----------------------------------------------------------------------
    // 7. Provider change at runtime
    // -----------------------------------------------------------------------
    testWidgets(
      'switches to new listenable when listenable parameter changes',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));
        String? capturedData;

        Widget buildFrame(TestViewStateNotifier<String> provider) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<String>(
              listenable: provider,
              dataBuilder: (_, data, __) {
                capturedData = data;
                return const SizedBox();
              },
            ),
          );
        }

        await tester.pumpWidget(buildFrame(provider1));
        expect(capturedData, 'one');

        await tester.pumpWidget(buildFrame(provider2));
        expect(capturedData, 'two');

        provider1.emit(const DataState('three'));
        await tester.pump();
        expect(capturedData, 'two'); // unchanged
      },
    );

    // -----------------------------------------------------------------------
    // 8. Cleanup (listener removal)
    // -----------------------------------------------------------------------
    testWidgets('detaches listener when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<String>(
            listenable: provider,
            dataBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // -----------------------------------------------------------------------
    // 9. Diagnostics
    // -----------------------------------------------------------------------
    testWidgets('debugFillProperties includes all relevant properties', (
      tester,
    ) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateBuilder<String>(
        listenable: TestViewStateNotifier<String>(),
        dataBuilder: (_, __, ___) => const SizedBox(),
        initialBuilder: (_) => const SizedBox(),
        loadingBuilder: (_, __) => const SizedBox(),
        emptyBuilder: (_, __) => const SizedBox(),
        errorBuilder: (_, __) => const SizedBox(),
        rebuildWhen: (_, __) => true,
        isSliver: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((e) => e.contains('listenable')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('initialBuilder')), isTrue);
      expect(description.any((e) => e.contains('loadingBuilder')), isTrue);
      expect(description.any((e) => e.contains('emptyBuilder')), isTrue);
      expect(description.any((e) => e.contains('errorBuilder')), isTrue);
      expect(description.any((e) => e.contains('dataBuilder')), isTrue);
      expect(
        description.any((e) => e.contains('isSliver') && e.contains('true')),
        isTrue,
      );
      expect(description.any((e) => e.contains('child')), isTrue);
    });
  });
}
