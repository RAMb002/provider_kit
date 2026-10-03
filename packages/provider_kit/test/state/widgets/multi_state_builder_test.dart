import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';
import 'package:provider_kit/src/state/state_field.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/widgets.dart';

const incrementProvider0Key = Key('multi_builder_increment_p0');
const multiBuilderResetKey = Key('multi_builder_reset_btn');
const multiBuilderNoopKey = Key('multi_builder_noop_btn');
const builderOutputKey = Key('builder_output');

class MultiBuilderTestApp extends StatefulWidget {
  const MultiBuilderTestApp({
    super.key,
    required this.initialProviders,
    required this.newProviders,
    required this.builder,
    this.rebuildWhen,
  });

  final List<CounterProvider> initialProviders;
  final List<CounterProvider> newProviders;

  final StateWidgetBuilder<List<int>> builder;

  final RebuildWhen<List<int>>? rebuildWhen;

  @override
  State<MultiBuilderTestApp> createState() => _MultiBuilderTestAppState();
}

class _MultiBuilderTestAppState extends State<MultiBuilderTestApp> {
  late List<CounterProvider> _activeProviders;

  @override
  void initState() {
    super.initState();
    _activeProviders = widget.initialProviders;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            MultiStateBuilder<List<int>>(
              providers: () => [
                for (final provider in _activeProviders) provider.watch,
              ],
              rebuildWhen: widget.rebuildWhen,
              builder: widget.builder,
              child: const SizedBox(key: Key('multi_builder_child')),
            ),
            TextButton(
              key: incrementProvider0Key,
              onPressed: () {
                if (_activeProviders.isNotEmpty) {
                  _activeProviders.first.increment();
                }
              },
              child: const Text('Increment'),
            ),
            TextButton(
              key: multiBuilderResetKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.newProviders;
                });
              },
              child: const Text('Swap Providers'),
            ),
            TextButton(
              key: multiBuilderNoopKey,
              onPressed: () {
                setState(() {
                  _activeProviders = _activeProviders;
                });
              },
              child: const Text('No-Op Rebuild'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('MultiStateBuilder', () {
    // =========================================================================
    // SECTION 1: CORE RENDERING & CHILD HANDLING
    // =========================================================================

    testWidgets('renders builder output and passes child', (tester) async {
      const childKey = Key('builder_child');

      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            builder: (_, state, child) {
              return Row(
                children: [
                  child!,
                  Text('${state[0]}-${state[1]}', key: builderOutputKey),
                ],
              );
            },
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byKey(builderOutputKey), findsOneWidget);
      expect(find.text('0-10'), findsOneWidget);
    });

    testWidgets('builder receives arbitrary combined state type', (
      tester,
    ) async {
      final provider = CounterProvider(5);

      ({int count, bool loading})? receivedState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<({int count, bool loading})>(
            providers: () => (count: provider.watch, loading: false),
            builder: (_, state, __) {
              receivedState = state;

              return Text('${state.count}-${state.loading}');
            },
          ),
        ),
      );

      expect(receivedState, (count: 5, loading: false));
      expect(find.text('5-false'), findsOneWidget);
    });

    testWidgets('child widget is preserved across state rebuilds', (
      tester,
    ) async {
      const childKey = Key('child_preserved');

      int childBuildCount = 0;
      int builderBuildCount = 0;

      final provider = CounterProvider();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<int>(
            providers: () => provider.watch,
            builder: (_, state, child) {
              builderBuildCount++;

              return Column(children: [child!, Text('State: $state')]);
            },
            child: StatefulBuilder(
              key: childKey,
              builder: (_, __) {
                childBuildCount++;
                return const Text('Child');
              },
            ),
          ),
        ),
      );

      expect(builderBuildCount, 1);
      expect(childBuildCount, 1);

      provider.increment();
      await tester.pump();

      expect(builderBuildCount, 2);
      expect(childBuildCount, 1);
    });

    // =========================================================================
    // SECTION 2: INITIAL BUILD & STATE
    // =========================================================================

    testWidgets('builder receives initial combined state', (tester) async {
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(9);

      List<int>? receivedState;

      await tester.pumpWidget(
        MultiStateBuilder<List<int>>(
          providers: () => [provider1.watch, provider2.watch],
          builder: (_, state, __) {
            receivedState = state;
            return const SizedBox();
          },
        ),
      );

      expect(receivedState, [5, 9]);
    });

    testWidgets('initial builder is called exactly once', (tester) async {
      final provider = CounterProvider();

      int buildCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) {
            buildCount++;
            return const SizedBox();
          },
        ),
      );

      expect(buildCount, 1);
    });

    // =========================================================================
    // SECTION 3: REBUILD BEHAVIOR
    // =========================================================================

    testWidgets('rebuilds when a watched state source changes', (tester) async {
      final provider = CounterProvider();

      final states = <int>[];

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );

      expect(states, [0]);

      provider.increment();
      await tester.pump();

      expect(states, [0, 1]);
    });

    testWidgets('rebuilds when any watched state source changes', (
      tester,
    ) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      final states = <List<int>>[];

      await tester.pumpWidget(
        MultiStateBuilder<List<int>>(
          providers: () => [provider1.watch, provider2.watch],
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );

      expect(states, [
        [0, 10],
      ]);

      provider1.increment();
      await tester.pump();

      expect(states, [
        [0, 10],
        [1, 10],
      ]);

      provider2.increment();
      await tester.pump();

      expect(states, [
        [0, 10],
        [1, 10],
        [1, 11],
      ]);
    });

    testWidgets(
      'batches multiple synchronous provider updates into a single build',
      (tester) async {
        final provider1 = CounterProvider();
        final provider2 = CounterProvider(10);

        final states = <List<int>>[];

        await tester.pumpWidget(
          MultiStateBuilder<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            builder: (_, state, __) {
              states.add(state);
              return const SizedBox();
            },
          ),
        );

        expect(states, [
          [0, 10],
        ]);

        provider1.increment();
        provider2.increment();

        await tester.pump();

        expect(states, [
          [0, 10],
          [1, 11],
        ]);
      },
    );

    testWidgets('rebuilds separately when updates happen in separate frames', (
      tester,
    ) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      final states = <List<int>>[];

      await tester.pumpWidget(
        MultiStateBuilder<List<int>>(
          providers: () => [provider1.watch, provider2.watch],
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );

      expect(states, [
        [0, 10],
      ]);

      provider1.increment();
      await tester.pump();

      provider2.increment();
      await tester.pump();

      expect(states, [
        [0, 10],
        [1, 10],
        [1, 11],
      ]);
    });

    // =========================================================================
    // SECTION 4: REBUILD FILTERING
    // =========================================================================

    testWidgets('rebuildWhen receives previous and current state', (
      tester,
    ) async {
      final provider = CounterProvider();

      final previousStates = <int>[];
      final currentStates = <int>[];

      int rebuildWhenCallCount = 0;
      int buildCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          rebuildWhen: (previous, current) {
            rebuildWhenCallCount++;
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
          builder: (_, __, ___) {
            buildCount++;
            return const SizedBox();
          },
        ),
      );

      expect(buildCount, 1);
      expect(rebuildWhenCallCount, 0);

      provider.increment();
      await tester.pump();

      provider.increment();
      await tester.pump();

      expect(rebuildWhenCallCount, 2);
      expect(previousStates, [0, 1]);
      expect(currentStates, [1, 2]);
      expect(buildCount, 3);
    });

    testWidgets('defers rebuild when a watched source changes during build', (
      tester,
    ) async {
      final field = StateField(0);
      final states = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<int>(
            providers: () => field.watch,
            builder: (_, state, child) {
              states.add(state);

              return Column(children: [Text('$state'), child!]);
            },
            child: StateChangeDuringInit(
              onInit: () {
                field.state = 1;
              },
            ),
          ),
        ),
      );

      // Initial build completed; the rebuild was deferred.
      expect(states, [0]);

      await tester.pump();

      expect(states, [0, 1]);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('coalesces multiple rebuild requests during the same build', (
      tester,
    ) async {
      final field = StateField(0);
      final states = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<int>(
            providers: () => field.watch,
            builder: (_, state, child) {
              states.add(state);

              return Column(children: [Text('$state'), child!]);
            },
            child: StateChangeDuringInit(
              onInit: () {
                field.state = 1;
                field.state = 2;
                field.state = 3;
              },
            ),
          ),
        ),
      );

      expect(states, [0]);

      await tester.pump();

      // Only one deferred rebuild, using the latest state.
      expect(states, [0, 3]);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('rebuilds only when rebuildWhen returns true', (tester) async {
      final provider = CounterProvider();

      final states = <int>[];
      int rebuildWhenCallCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          rebuildWhen: (previous, current) {
            rebuildWhenCallCount++;

            // Rebuild only for even values.
            return current.isEven;
          },
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );

      expect(states, [0]);
      expect(rebuildWhenCallCount, 0);

      provider.increment(); // 1
      await tester.pump();

      expect(states, [0]);

      provider.increment(); // 2
      await tester.pump();

      expect(states, [0, 2]);

      provider.increment(); // 3
      await tester.pump();

      expect(states, [0, 2]);

      provider.increment(); // 4
      await tester.pump();

      expect(states, [0, 2, 4]);
      expect(rebuildWhenCallCount, 4);
    });

    testWidgets(
      'rebuildWhen baseline advances even when previous rebuild is skipped',
      (tester) async {
        final provider = CounterProvider();

        final previousStates = <int>[];
        final currentStates = <int>[];

        await tester.pumpWidget(
          MultiStateBuilder<int>(
            providers: () => provider.watch,
            rebuildWhen: (previous, current) {
              previousStates.add(previous);
              currentStates.add(current);

              return current == 2;
            },
            builder: (_, __, ___) => const SizedBox(),
          ),
        );

        provider.increment(); // 1
        await tester.pump();

        provider.increment(); // 2
        await tester.pump();

        expect(previousStates, [0, 1]);
        expect(currentStates, [1, 2]);
      },
    );

    testWidgets('does not call rebuildWhen during the initial build', (
      tester,
    ) async {
      final provider = CounterProvider();

      int rebuildWhenCallCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          rebuildWhen: (_, __) {
            rebuildWhenCallCount++;
            return true;
          },
          builder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(rebuildWhenCallCount, 0);
    });

    // =========================================================================
    // SECTION 5: DEPENDENCY COLLECTION
    // =========================================================================

    testWidgets('collects providers once during initial build', (tester) async {
      final provider = CounterProvider();

      int collectionCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () {
            collectionCount++;
            return provider.watch;
          },
          builder: (_, __, ___) => const SizedBox(),
        ),
      );

      expect(collectionCount, 1);
    });

    testWidgets('collects providers once for each dependency notification', (
      tester,
    ) async {
      final provider = CounterProvider();

      int collectionCount = 0;
      int buildCount = 0;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () {
            collectionCount++;

            return provider.watch;
          },
          builder: (_, __, ___) {
            buildCount++;
            return const SizedBox();
          },
        ),
      );

      expect(collectionCount, 1);
      expect(buildCount, 1);

      provider.increment();
      await tester.pump();

      expect(collectionCount, 2);
      expect(buildCount, 2);
    });

    testWidgets('does not duplicate subscriptions when parent rebuilds', (
      tester,
    ) async {
      final provider = CounterProvider();

      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) {
              return Column(
                children: [
                  MultiStateBuilder<int>(
                    providers: () => provider.watch,
                    builder: (_, state, __) {
                      buildCount++;

                      return Text('$state');
                    },
                  ),
                  TextButton(
                    key: multiBuilderNoopKey,
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

      expect(buildCount, 1);

      await tester.tap(find.byKey(multiBuilderNoopKey));
      await tester.pump();

      expect(buildCount, 2);

      provider.increment();
      await tester.pump();

      // One dependency notification should produce exactly one builder
      // rebuild. A duplicated listener would cause an additional build.
      expect(buildCount, 3);
      expect(find.text('1'), findsOneWidget);
    });

    // =========================================================================
    // SECTION 6: RUNTIME DEPENDENCY TRANSITIONS
    // =========================================================================

    testWidgets('updates subscriptions when watched sources change', (
      tester,
    ) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(20);

      final buildLog = <List<int>>[];

      await tester.pumpWidget(
        MultiBuilderTestApp(
          initialProviders: [provider1],
          newProviders: [provider2],
          builder: (_, state, __) {
            buildLog.add(state);
            return const SizedBox();
          },
        ),
      );

      expect(buildLog, [
        [0],
      ]);

      provider1.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
      ]);

      await tester.tap(find.byKey(multiBuilderResetKey));
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
      ]);

      // The old provider should no longer be subscribed.
      provider1.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
      ]);

      // The new provider should be subscribed.
      provider2.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
        [21],
      ]);
    });

    testWidgets(
      'new dependency state becomes the baseline after dependency swap',
      (tester) async {
        final provider1 = CounterProvider(10);
        final provider2 = CounterProvider(30);

        final previousStates = <List<int>>[];
        final currentStates = <List<int>>[];

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider1],
            newProviders: [provider2],
            rebuildWhen: (previous, current) {
              previousStates.add(previous);
              currentStates.add(current);
              return true;
            },
            builder: (_, __, ___) => const SizedBox(),
          ),
        );

        await tester.tap(find.byKey(multiBuilderResetKey));
        await tester.pump();

        // Replacing dependencies establishes the new state as the baseline;
        // rebuildWhen is not called for the widget configuration change.
        expect(previousStates, isEmpty);
        expect(currentStates, isEmpty);

        provider2.increment();
        await tester.pump();

        expect(previousStates, [
          [30],
        ]);

        expect(currentStates, [
          [31],
        ]);
      },
    );

    testWidgets(
      'builder reflects new dependency state even when rebuildWhen returns false',
      (tester) async {
        final provider1 = CounterProvider(10);
        final provider2 = CounterProvider(30);

        final buildLog = <List<int>>[];

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider1],
            newProviders: [provider2],
            rebuildWhen: (_, __) => false,
            builder: (_, state, __) {
              buildLog.add(state);
              return const SizedBox();
            },
          ),
        );

        expect(buildLog, [
          [10],
        ]);

        await tester.tap(find.byKey(multiBuilderResetKey));
        await tester.pump();

        // A widget configuration change is still reflected by the next build.
        // rebuildWhen only controls state-change rebuilds.
        expect(buildLog, [
          [10],
          [30],
        ]);

        provider2.increment();
        await tester.pump();

        expect(buildLog, [
          [10],
          [30],
        ]);
      },
    );

    testWidgets(
      'parent rebuild with unchanged dependencies does not recreate subscriptions',
      (tester) async {
        final provider = CounterProvider();

        final buildLog = <List<int>>[];

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider],
            newProviders: [provider],
            builder: (_, state, __) {
              buildLog.add(state);
              return const SizedBox();
            },
          ),
        );

        expect(buildLog, [
          [0],
        ]);

        await tester.tap(find.byKey(multiBuilderNoopKey));
        await tester.pump();

        // Parent rebuild causes the builder to run again, but should not add
        // another listener to the same dependency.
        expect(buildLog, [
          [0],
          [0],
        ]);

        provider.increment();
        await tester.pump();

        // One provider notification should result in exactly one additional
        // builder invocation.
        expect(buildLog, [
          [0],
          [0],
          [1],
        ]);
      },
    );

    testWidgets(
      'throws AssertionError when no watched state source is collected',
      (tester) async {
        await tester.pumpWidget(
          MultiStateBuilder<int>(
            providers: () => 0,
            builder: (_, state, __) {
              return Text('$state');
            },
          ),
        );

        expect(tester.takeException(), isA<AssertionError>());
      },
    );

    // =========================================================================
    // SECTION 7: CLEANUP
    // =========================================================================

    testWidgets('detaches listeners when widget is removed from the tree', (
      tester,
    ) async {
      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) => const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =========================================================================
    // SECTION 8: FLUTTER INSPECTOR DIAGNOSTICS
    // =========================================================================

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiStateBuilder<int>(
        providers: () => CounterProvider().watch,
        rebuildWhen: (previous, current) => previous != current,
        child: const SizedBox(),
        builder: (_, __, ___) => const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any((value) => value.contains('providers')),
        isTrue,
        reason: 'Should expose providers configuration. Found: $description',
      );

      expect(description.any((value) => value.contains('rebuildWhen')), isTrue);

      expect(description.any((value) => value.contains('child')), isTrue);

      expect(description.any((value) => value.contains('builder')), isTrue);
    });
  });
}
