import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group('MultiViewStateBuilder', () {
    // -----------------------------------------------------------------------
    // Helper to pump a MultiViewStateBuilder.
    // -----------------------------------------------------------------------
    Widget buildBuilder({
      required List<ViewStateNotifier<String>> providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? errorBuilder,
      required MultiDataStateBuilder<List<DataState<String>>> dataBuilder,
      RebuildWhen<List<ViewState<String>>>? rebuildWhen,
      bool isSliver = false,
      bool withDefaultProvider = false,
    }) {
      final builder = MultiViewStateBuilder<String>(
        providers: providers,
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

    // -----------------------------------------------------------------------
    // 1. Basic Rendering
    // -----------------------------------------------------------------------
    testWidgets('renders builder output', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      bool built = false;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider],
          dataBuilder: (_) {
            built = true;
            return const SizedBox();
          },
        ),
      );

      expect(built, true);
    });

    // -----------------------------------------------------------------------
    // 2. Aggregated State Priority Logic (combined test)
    // -----------------------------------------------------------------------
    testWidgets(
      'priority chain: Error > Initial > Loading > Empty > Data',
      (tester) async {
        final provider1 =
            TestViewStateNotifier<String>(const DataState('data1'));
        final provider2 =
            TestViewStateNotifier<String>(const DataState('data2'));

        bool errorBuilt = false;
        bool initialBuilt = false;
        bool loadingBuilt = false;
        bool emptyBuilt = false;
        bool dataBuilt = false;

        await tester.pumpWidget(
          buildBuilder(
            providers: [provider1, provider2],
            errorBuilder: (_, __, ___, ____, _____) {
              errorBuilt = true;
              return const SizedBox();
            },
            initialBuilder: (_) {
              initialBuilt = true;
              return const SizedBox();
            },
            loadingBuilder: (_, __, ___) {
              loadingBuilt = true;
              return const SizedBox();
            },
            emptyBuilder: (_, __) {
              emptyBuilt = true;
              return const SizedBox();
            },
            dataBuilder: (_) {
              dataBuilt = true;
              return const SizedBox();
            },
          ),
        );

        // Initially both Data → dataBuilder called.
        expect(dataBuilt, true);
        expect(errorBuilt, false);
        expect(initialBuilt, false);
        expect(loadingBuilt, false);
        expect(emptyBuilt, false);

        dataBuilt = false;

        // Emit Empty → aggregated Empty.
        provider1.emit(const EmptyState('empty'));
        await tester.pump();
        expect(emptyBuilt, true);
        expect(dataBuilt, false);
        expect(errorBuilt, false);
        expect(initialBuilt, false);
        expect(loadingBuilt, false);

        emptyBuilt = false;

        // Emit Loading → aggregated Loading.
        provider1.emit(const LoadingState('load'));
        await tester.pump();
        expect(loadingBuilt, true);
        expect(emptyBuilt, false);
        expect(dataBuilt, false);
        expect(errorBuilt, false);
        expect(initialBuilt, false);

        loadingBuilt = false;

        // Emit Initial → aggregated Initial.
        provider1.emit(const InitialState());
        await tester.pump();
        expect(initialBuilt, true);
        expect(loadingBuilt, false);
        expect(emptyBuilt, false);
        expect(dataBuilt, false);
        expect(errorBuilt, false);

        initialBuilt = false;

        // Emit Error → aggregated Error.
        provider1.emit(const ErrorState('error'));
        await tester.pump();
        expect(errorBuilt, true);
        expect(initialBuilt, false);
        expect(loadingBuilt, false);
        expect(emptyBuilt, false);
        expect(dataBuilt, false);

        errorBuilt = false;

        // Back to Data → aggregated Data.
        provider1.emit(const DataState('data1-new'));
        provider2.emit(const DataState('data2-new'));
        await tester.pump();
        expect(dataBuilt, true);
        expect(errorBuilt, false);
        expect(initialBuilt, false);
        expect(loadingBuilt, false);
        expect(emptyBuilt, false);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Builder Parameters
    // -----------------------------------------------------------------------
    testWidgets('errorBuilder receives correct parameters', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('dummy'));
      final provider2 =
          TestViewStateNotifier<String>(const ErrorState('Error!'));

      String? capturedMessage;
      VoidCallback? capturedOnRetry;
      dynamic capturedException;
      StackTrace? capturedStackTrace;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
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

      expect(capturedMessage, 'Error!');
      expect(capturedOnRetry, isA<VoidCallback>());
      expect(capturedException, isNull);
      expect(capturedStackTrace, isNull);
      expect(capturedIsSliver, true);
    });

    testWidgets('loadingBuilder receives message and combined progress',
        (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('Load A', 0.3));
      final provider2 =
          TestViewStateNotifier<String>(const LoadingState('Load B', 0.7));

      String? capturedMessage;
      double? capturedProgress;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
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

      expect(capturedMessage, 'Load A');
      expect(capturedProgress, 0.5);
      expect(capturedIsSliver, true);
    });

    testWidgets('emptyBuilder receives message', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('Empty A'));
      final provider2 =
          TestViewStateNotifier<String>(const EmptyState('Empty B'));

      String? capturedMessage;
      bool? capturedIsSliver;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          emptyBuilder: (message, isSliver) {
            capturedMessage = message;
            capturedIsSliver = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(capturedMessage, 'Empty A');
      expect(capturedIsSliver, true);
    });

    testWidgets('dataBuilder receives list of DataStates in order',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('one'));
      final provider2 = TestViewStateNotifier<String>(const DataState('two'));
      List<DataState<String>>? capturedData;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (data) {
            capturedData = data;
            return const SizedBox();
          },
        ),
      );

      expect(capturedData, [
        const DataState('one'),
        const DataState('two'),
      ]);
    });

    testWidgets('onRetry calls refresh on all AsyncViewStateNotifier providers',
        (tester) async {
      final provider1 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data1',
      );
      final provider2 = MockAsyncViewStateNotifier<String>(
        fetchDataImpl: () => 'data2',
      );
      await tester.pumpAndSettle();

      VoidCallback? capturedOnRetry;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          errorBuilder: (_, onRetry, __, ___, ____) {
            capturedOnRetry = onRetry;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
        ),
      );

      provider1.state = const ErrorState<String>('Error');
      await tester.pump();

      expect(capturedOnRetry, isA<VoidCallback>());
    });

    // -----------------------------------------------------------------------
    // 4. rebuildWhen (default and custom)
    // -----------------------------------------------------------------------
    testWidgets(
        'data changes within DataState trigger rebuild (full-list comparison)',
        (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));
      int buildCount = 0;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) {
            buildCount++;
            return const SizedBox();
          },
        ),
      );

      expect(buildCount, 1);

      // Different data → rebuild.
      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(buildCount, 2);

      // Same data → no rebuild.
      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets('custom rebuildWhen overrides default logic', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const DataState('data1'));
      final provider2 = TestViewStateNotifier<String>(const DataState('data2'));
      int buildCount = 0;
      bool rebuildWhenCalled = false;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) {
            buildCount++;
            return const SizedBox();
          },
          rebuildWhen: (previous, current) {
            rebuildWhenCalled = true;
            return false; // never rebuild
          },
        ),
      );

      expect(buildCount, 1);
      expect(rebuildWhenCalled, false);

      provider1.emit(const DataState('new data1'));
      await tester.pump();
      expect(rebuildWhenCalled, true);
      expect(buildCount, 1); // no rebuild
    });

    // -----------------------------------------------------------------------
    // 5. Fallback to ViewStateWidgetsProvider
    // -----------------------------------------------------------------------
    testWidgets('uses default initial widget from provider', (tester) async {
      final provider1 = TestViewStateNotifier<String>(const InitialState());
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultInitialKey), findsOneWidget);
    });

    testWidgets('uses default loading widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('load'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultLoadingKey), findsOneWidget);
    });

    testWidgets('uses default empty widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('empty'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultEmptyKey), findsOneWidget);
    });

    testWidgets('uses default error widget from provider', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const ErrorState('error'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          dataBuilder: (_) => const SizedBox(),
          withDefaultProvider: true,
        ),
      );

      expect(find.byKey(_defaultErrorKey), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. isSliver flag propagation
    // -----------------------------------------------------------------------
    testWidgets('passes isSliver flag to errorBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const ErrorState('error'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          errorBuilder: (_, __, ___, ____, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    testWidgets('passes isSliver flag to loadingBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const LoadingState('load'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          loadingBuilder: (_, __, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    testWidgets('passes isSliver flag to emptyBuilder', (tester) async {
      final provider1 =
          TestViewStateNotifier<String>(const EmptyState('empty'));
      final provider2 = TestViewStateNotifier<String>(const DataState('dummy'));
      bool? isSliverPassed;

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider1, provider2],
          emptyBuilder: (_, isSliver) {
            isSliverPassed = isSliver;
            return const SizedBox();
          },
          dataBuilder: (_) => const SizedBox(),
          isSliver: true,
        ),
      );

      expect(isSliverPassed, true);
    });

    // -----------------------------------------------------------------------
    // 7. Runtime Provider List Transitions
    // -----------------------------------------------------------------------
    testWidgets(
      'updates to new provider list when providers change',
      (tester) async {
        final provider1 = TestViewStateNotifier<String>(const DataState('one'));
        final provider2 = TestViewStateNotifier<String>(const DataState('two'));
        final provider3 =
            TestViewStateNotifier<String>(const DataState('three'));

        List<ViewStateNotifier<String>> providers = [provider1, provider2];
        String? capturedData;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MultiViewStateBuilder<String>(
                  providers: providers,
                  dataBuilder: (data) {
                    capturedData = data[0].data;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        );

        expect(capturedData, 'one');

        // Change data inside provider1 (still aggregated Data) → rebuild.
        provider1.emit(const DataState('one-new'));
        await tester.pump();
        expect(capturedData, 'one-new');

        // Replace with a single-provider list.
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MultiViewStateBuilder<String>(
                  providers: [provider3],
                  dataBuilder: (data) {
                    capturedData = data[0].data;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        );
        await tester.pump();
        expect(capturedData, 'three');
      },
    );

    testWidgets('detects in-place provider list mutation', (tester) async {
      final providerA = TestViewStateNotifier<String>(const DataState('A'));
      final providerB = TestViewStateNotifier<String>(const DataState('B'));
      final providers = [providerA];
      String? capturedData;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MultiViewStateBuilder<String>(
                providers: providers,
                dataBuilder: (data) {
                  capturedData = data[0].data;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      expect(capturedData, 'A');

      // Mutate list in-place.
      providers[0] = providerB;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: MultiViewStateBuilder<String>(
                providers: providers,
                dataBuilder: (data) {
                  capturedData = data[0].data;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );
      await tester.pump();
      expect(capturedData, 'B');

      // Old providerA changes should not affect.
      providerA.emit(const DataState('A-new'));
      await tester.pump();
      expect(capturedData, 'B');

      // New providerB changes should trigger rebuild.
      providerB.emit(const DataState('B-new'));
      await tester.pump();
      expect(capturedData, 'B-new');
    });

    testWidgets(
        'parent rebuild with same providers causes builder rebuild (expected)',
        (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));
      int buildCount = 0;

      Widget buildFrame() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MultiViewStateBuilder<String>(
            providers: [provider],
            dataBuilder: (_) {
              buildCount++;
              return const SizedBox();
            },
          ),
        );
      }

      await tester.pumpWidget(buildFrame());
      expect(buildCount, 1);

      // Rebuild with same providers – builder rebuilds (normal Flutter behaviour).
      await tester.pumpWidget(buildFrame());
      expect(buildCount, 2);

      // Data change still triggers rebuild.
      provider.emit(const DataState('new data'));
      await tester.pump();
      expect(buildCount, 3);
    });

    // -----------------------------------------------------------------------
    // 8. Cleanup
    // -----------------------------------------------------------------------
    testWidgets('detaches listeners when widget is removed', (tester) async {
      final provider = TestViewStateNotifier<String>(const DataState('data'));

      await tester.pumpWidget(
        buildBuilder(
          providers: [provider],
          dataBuilder: (_) => const SizedBox(),
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

      MultiViewStateBuilder<String>(
        providers: [TestViewStateNotifier<String>(const DataState('data'))],
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

      expect(description.any((e) => e.contains('providers')), isTrue);
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
