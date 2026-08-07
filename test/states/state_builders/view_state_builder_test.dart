import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/provider_kit.dart';
import '../../shared/mocks/view_state_notifiers.dart';

// -----------------------------------------------------------------------------
// Helper to provide default ViewStateWidgetsProvider keys once.
// -----------------------------------------------------------------------------
const _defaultInitialKey = Key('default_initial');
const _defaultLoadingKey = Key('default_loading');
const _defaultEmptyKey = Key('default_empty');
const _defaultErrorKey = Key('default_error');

Widget _withDefaultProvider(Widget child) {
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
    }) {
      final builder = ViewStateBuilder<TestViewStateNotifier<String>, String>(
        provider: provider,
        initialBuilder: initialBuilder,
        loadingBuilder: loadingBuilder,
        emptyBuilder: emptyBuilder,
        errorBuilder: errorBuilder,
        dataBuilder: dataBuilder,
        rebuildWhen: rebuildWhen,
        isSliver: isSliver,
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
    testWidgets('dataBuilder is required and called for DataState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('Hello'));
      String? capturedData;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (data) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, 'Hello');
    });

    // ----------------------------------------------------------------
    // 1.2 InitialBuilder
    // ----------------------------------------------------------------
    testWidgets('calls initialBuilder when state is InitialState',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialBuilt = false;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          initialBuilder: (_) {
            initialBuilt = true;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(initialBuilt, true);
    });

    // ----------------------------------------------------------------
    // 1.3 LoadingBuilder
    // ----------------------------------------------------------------
    testWidgets('calls loadingBuilder with correct parameters', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const LoadingState('Loading', 0.7));
      String? capturedMessage;
      double? capturedProgress;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          loadingBuilder: (message, progress, _) {
            capturedMessage = message;
            capturedProgress = progress;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'Loading');
      expect(capturedProgress, 0.7);
    });

    // ----------------------------------------------------------------
    // 1.4 EmptyBuilder
    // ----------------------------------------------------------------
    testWidgets('calls emptyBuilder with message', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const EmptyState('No data'));
      String? capturedMessage;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          emptyBuilder: (message, _) {
            capturedMessage = message;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      expect(capturedMessage, 'No data');
    });

    // ----------------------------------------------------------------
    // 1.5 ErrorBuilder
    // ----------------------------------------------------------------
    testWidgets('calls errorBuilder with correct parameters', (tester) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>(
            'Error', Exception('boom'), StackTrace.current, () {}),
      );
      String? capturedMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          errorBuilder: (message, onRetry, exception, stackTrace, isSliver) {
            capturedMessage = message;
            capturedOnRetry = onRetry;
            capturedException = exception;
            capturedStackTrace = stackTrace;
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedMessage, 'Error');
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedException, isA<Exception>());
      expect(capturedStackTrace, isNotNull);
      expect(capturedIsSliver, true);
    });

    // -----------------------------------------------------------------------
    // 2. Fallback to ViewStateWidgetsProvider when local builder is null
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(const EmptyState());

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from provider', (tester) async {
      final provider = TestViewStateNotifier<String>(
          ErrorState<String>('Error', Exception(), StackTrace.current, null));

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    testWidgets(
        'throws assertion when state is not DataState and no provider in context',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            // No initialBuilder, no ViewStateWidgetsProvider
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      // The assertion is from ViewStateWidgetsProvider.of
      expect(tester.takeException(), isA<AssertionError>());
    });

    // -----------------------------------------------------------------------
    // 3. onRetry resolution
    // -----------------------------------------------------------------------
    testWidgets(
        'errorBuilder receives onRetry from AsyncViewStateNotifier when not explicitly set',
        (tester) async {
      final exception = Exception('Test');
      final provider = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => throw exception,
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<MockAsyncViewStateNotifier<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, provider.refresh);
    });

    testWidgets(
        'errorBuilder receives onRetry from ErrorState when explicitly set (overrides provider)',
        (tester) async {
      final provider = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => throw Exception('Test'),
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;
      void explicitOnRetry() {}

      // Emit a new ErrorState with explicit onRetry
      provider.state =
          (ErrorState<String>('Error', null, null, explicitOnRetry));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<MockAsyncViewStateNotifier<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      expect(capturedOnRetry, explicitOnRetry);
    });

    testWidgets(
        'errorBuilder receives null onRetry when provider is not a AsyncViewStateNotifier',
        (tester) async {
      final provider = TestViewStateNotifier<String>(
        ErrorState<String>('Error', Exception(), StackTrace.current, null),
      );
      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            errorBuilder: (_, onRetry, __, ___, ____) {
              capturedOnRetry = onRetry;
              return const SizedBox();
            },
            dataBuilder: (_) => const SizedBox(),
          ),
        ),
      );

      // Since provider is not AsyncViewStateNotifier, onRetry should be null.
      expect(capturedOnRetry, isNull);
    });

    // -----------------------------------------------------------------------
    // 4. rebuildWhen filtering
    // -----------------------------------------------------------------------
    testWidgets('rebuildWhen controls whether builder is called',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('initial'));
      int buildCount = 0;

      await tester.pumpWidget(
        buildBuilder(
          provider: provider,
          dataBuilder: (data) {
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
          dataBuilder: (_) => const SizedBox(),
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

      provider.emit(const ErrorState<String>('error'));
      await tester.pump();

      expect(previousList.length, 3);
      expect(previousList[2], const DataState<String>('data'));
      expect(currentList[2], isA<ErrorState<String>>());
    });

    // -----------------------------------------------------------------------
    // 5. isSliver flag propagation
    // -----------------------------------------------------------------------
    testWidgets(
        'passes isSliver flag to all builders (initial, loading, empty, error)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const InitialState());
      bool initialIsSliver = false;
      bool loadingIsSliver = false;
      bool emptyIsSliver = false;
      bool errorIsSliver = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            isSliver: true,
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
          ),
        ),
      );

      expect(initialIsSliver, true);

      provider.emit(const LoadingState<String>());
      await tester.pump();
      expect(loadingIsSliver, true);

      provider.emit(const EmptyState<String>());
      await tester.pump();
      expect(emptyIsSliver, true);

      provider.emit(const ErrorState<String>('Error', null, null, null));
      await tester.pump();
      expect(errorIsSliver, true);
    });

    testWidgets('default widgets from provider receive isSliver',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const LoadingState());
      bool? isSliverPassed;

      // Override provider's loading builder to capture isSliver.
      await tester.pumpWidget(
        ViewStateWidgetsProvider(
          initialStateBuilder: (_) => const SizedBox(),
          loadingStateBuilder: (_, __, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          emptyStateBuilder: (_, __) => const SizedBox(),
          errorStateBuilder: (_, __, ___, ____, _____) => const SizedBox(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
              provider: provider,
              isSliver: true,
              dataBuilder: (_) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(isSliverPassed, true);
    });

    // -----------------------------------------------------------------------
    // 6. Provider resolution (explicit vs context)
    // -----------------------------------------------------------------------
    testWidgets('uses explicit provider when provided', (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('explicit'));
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (data) {
              capturedData = data;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedData, 'explicit');
    });

    testWidgets('reads provider from context when not provided',
        (tester) async {
      final provider =
          TestViewStateNotifier<String>(const DataState('context'));
      String? capturedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
            value: provider,
            child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
              dataBuilder: (data) {
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
    testWidgets('switches to new provider when provider parameter changes',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));
      String? capturedData;

      Widget buildFrame(TestViewStateNotifier<String>? provider) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (data) {
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
    });

    // -----------------------------------------------------------------------
    // 8. Cleanup (listener removal)
    // -----------------------------------------------------------------------
    testWidgets('detaches listener when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewStateBuilder<TestViewStateNotifier<String>, String>(
            provider: provider,
            dataBuilder: (_) => const SizedBox(),
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
    testWidgets('debugFillProperties includes all relevant properties',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      ViewStateBuilder<TestViewStateNotifier<String>, String>(
        provider: TestViewStateNotifier<String>(),
        dataBuilder: (_) => const SizedBox(),
        initialBuilder: (_) => const SizedBox(),
        loadingBuilder: (_, __, ___) => const SizedBox(),
        emptyBuilder: (_, __) => const SizedBox(),
        errorBuilder: (_, __, ___, ____, _____) => const SizedBox(),
        rebuildWhen: (_, __) => true,
        isSliver: true,
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((e) => e.contains('provider')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('initialBuilder')), isTrue);
      expect(description.any((e) => e.contains('loadingBuilder')), isTrue);
      expect(description.any((e) => e.contains('emptyBuilder')), isTrue);
      expect(description.any((e) => e.contains('errorBuilder')), isTrue);
      expect(description.any((e) => e.contains('dataBuilder')), isTrue);
      expect(
          description.any((e) => e.contains('isSliver') && e.contains('true')),
          isTrue);
    });
  });
}
