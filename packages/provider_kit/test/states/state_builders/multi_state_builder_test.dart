import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

const incrementProvider0Key = Key('multi_builder_increment_p0');
const multiBuilderResetKey = Key('multi_builder_reset_btn');
const multiBuilderNoopKey = Key('multi_builder_noop_btn');
const builderOutputKey = Key('builder_output');

class MultiBuilderTestApp extends StatefulWidget {
  const MultiBuilderTestApp({
    super.key,
    required this.initialProviders,
    this.newProviders,
    required this.builder,
    this.rebuildWhen,
  });

  final List<CounterProvider> initialProviders;
  final List<CounterProvider>? newProviders;
  final Widget Function(BuildContext context, List<int> states, Widget? child)
      builder;
  final bool Function(List<int> previous, List<int> current)? rebuildWhen;

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
            MultiStateBuilder<int>(
              providers: _activeProviders,
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
                  _activeProviders = widget.newProviders ?? [];
                });
              },
              child: const Text('Swap List'),
            ),
            TextButton(
              key: multiBuilderNoopKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.initialProviders;
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
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<int>(
            providers: MyProvider().providersOne,
            builder: (_, states, child) {
              return Row(
                children: [
                  child!,
                  Text('${states[0]}-${states[1]}', key: builderOutputKey),
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

    testWidgets('works with empty providers list', (tester) async {
      int buildCount = 0;
      List<int>? lastStates;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: const [],
          builder: (_, states, __) {
            buildCount++;
            lastStates = states;
            return const SizedBox();
          },
        ),
      );

      expect(buildCount, 1); // initial build
      expect(lastStates, isEmpty);
    });

    testWidgets('child widget is preserved across rebuilds', (tester) async {
      const childKey = Key('child_preserved');
      int childRebuildCount = 0;
      int builderBuildCount = 0;
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateBuilder<int>(
            providers: [provider],
            builder: (_, __, child) {
              builderBuildCount++;
              return Column(
                children: [
                  child!,
                  Text('Builder $builderBuildCount'),
                ],
              );
            },
            child: StatefulBuilder(
              key: childKey,
              builder: (_, __) {
                childRebuildCount++;
                return const Text('Child');
              },
            ),
          ),
        ),
      );

      // Initial build
      expect(builderBuildCount, 1);
      expect(childRebuildCount, 1);

      // Trigger rebuild via provider change
      provider.increment();
      await tester.pump();

      // Builder rebuilds, but child does not
      expect(builderBuildCount, 2);
      expect(childRebuildCount, 1);
    });

    // =========================================================================
    // SECTION 2: INITIAL BUILD & STATE ORDER
    // =========================================================================

    testWidgets('builder receives initial states on first build',
        (tester) async {
      List<int>? initStates;
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(9);

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: [provider1, provider2],
          builder: (_, states, __) {
            initStates = states;
            return const SizedBox();
          },
        ),
      );

      expect(initStates, [5, 9]);
    });

    testWidgets('states order matches providers list order', (tester) async {
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(7);
      List<int>? receivedStates;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: [provider1, provider2],
          builder: (_, states, __) {
            receivedStates = states;
            return const SizedBox();
          },
        ),
      );

      expect(receivedStates, [5, 7]);

      provider1.increment();
      await tester.pump();
      expect(receivedStates, [6, 7]);

      provider2.increment();
      await tester.pump();
      expect(receivedStates, [6, 8]);
    });

    // =========================================================================
    // SECTION 3: REBUILD BEHAVIOR ON STATE CHANGES
    // =========================================================================

    testWidgets('rebuilds when a single provider emits a change',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: providers,
          builder: (_, currentStates, __) {
            states.add(currentStates);
            return const SizedBox();
          },
        ),
      );

      // Initial build adds initial state
      expect(states, [
        [0, 10]
      ]);

      providers.first.increment();
      await tester.pump();

      expect(states, [
        [0, 10],
        [1, 10],
      ]);
    });

    testWidgets(
        'batches multiple synchronous provider updates into a single rebuild',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: providers,
          builder: (_, currentStates, __) {
            states.add(currentStates);
            return const SizedBox();
          },
        ),
      );

      expect(states, [
        [0, 10]
      ]);

      provider.incrementProviders(providers);
      await tester.pump();

      //build get batched since its a builder
      //otherwise the states would be [1, 10] and then [1, 20] in two separate rebuilds
      expect(states, [
        [0, 10],
        [1, 20],
      ]);
    });

    testWidgets(
      'rebuilds for each state change when updates happen in separate frames',
      (tester) async {
        final states = <List<int>>[];
        final provider = MyProvider();
        final providers = provider.providersOne;

        await tester.pumpWidget(
          MultiStateBuilder<int>(
            providers: providers,
            builder: (_, currentStates, __) {
              states.add(currentStates);
              return const SizedBox();
            },
          ),
        );

        expect(states, [
          [0, 10]
        ]);

        // Increment first provider, then pump to complete a frame
        providers.first.increment();
        await tester.pump(); // 👈 Forces a frame boundary

        // Increment second provider, then pump another frame
        providers.last.increment();
        await tester.pump(); // 👈 Another frame boundary

        // Both intermediate states appear
        expect(states, [
          [0, 10],
          [1, 10], // after first provider change
          [1, 20], // after second provider change
        ]);
      },
    );
    // =========================================================================
    // SECTION 4: REBUILD FILTERING (rebuildWhen)
    // =========================================================================

    testWidgets(
      'calls rebuildWhen with previous and current state lists (multiple updates)',
      (tester) async {
        final previousStates = <List<int>>[];
        final currentStates = <List<int>>[];
        int rebuildWhenCallCount = 0;
        int buildCount = 0;

        final provider = MyProvider();
        final providers = provider.providersOne;

        await tester.pumpWidget(
          MultiStateBuilder<int>(
            providers: providers,
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

        // Initial build
        expect(buildCount, 1);
        expect(rebuildWhenCallCount, 0);
        expect(previousStates, isEmpty);
        expect(currentStates, isEmpty);

        // Increment both providers synchronously (same microtask)
        provider.incrementProviders(providers);
        await tester.pump();

        // rebuildWhen is called for each provider change (two calls)
        expect(rebuildWhenCallCount, 2);

        // Capture the full sequence of previous and current states
        expect(previousStates, [
          [0, 10], // after first provider increment
          [1, 10], // after second provider increment
        ]);
        expect(currentStates, [
          [1, 10], // after first provider increment
          [1, 20], // after second provider increment
        ]);

        // Builder rebuilds only once (batched) with the final state [1, 20]
        expect(buildCount, 2); // initial + one rebuild

        // No additional rebuildWhen calls during the rebuild itself
        expect(rebuildWhenCallCount, 2);
      },
    );

    testWidgets('rebuilds only when rebuildWhen returns true', (tester) async {
      final states = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: [provider1, provider2],
          rebuildWhen: (previous, current) {
            // Rebuild only when both states are even
            return current[0] % 2 == 0 && current[1] % 2 == 0;
          },
          builder: (_, currentStates, __) {
            states.add(currentStates);
            return const SizedBox();
          },
        ),
      );

      // Initial build
      expect(states, [
        [0, 10]
      ]);

      provider1.increment(); // becomes 1 (odd)
      await tester.pump();
      expect(states, [
        [0, 10]
      ]); // no rebuild

      provider1.increment(); // becomes 2 (even)
      await tester.pump();
      expect(states, [
        [0, 10],
        [2, 10],
      ]); // rebuild

      provider2.increment(); // becomes 11 (odd)
      await tester.pump();
      expect(states, [
        [0, 10],
        [2, 10],
      ]); // no rebuild

      provider2.increment(); // becomes 12 (even)
      await tester.pump();
      expect(states, [
        [0, 10],
        [2, 10],
        [2, 12],
      ]); // rebuild
    });

    testWidgets(
        'rebuildWhen receives correct previous and current after multiple changes',
        (tester) async {
      final previousStates = <List<int>>[];
      final currentStates = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: [provider1, provider2],
          rebuildWhen: (previous, current) {
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
          builder: (_, __, ___) => const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();
      provider1.increment();
      await tester.pump();

      expect(previousStates, [
        [0, 10],
        [1, 10],
      ]);
      expect(currentStates, [
        [1, 10],
        [2, 10],
      ]);
    });

    // =========================================================================
    // SECTION 5: RUNTIME PROVIDER LIST TRANSITIONS
    // =========================================================================

    testWidgets(
        'updates subscription when providers list changes to a different list',
        (tester) async {
      final buildLog = <List<int>>[];
      final provider1 = CounterProvider(0);
      final provider2 = CounterProvider(10);
      final provider3 = CounterProvider(20);

      final incrementFinder = find.byKey(incrementProvider0Key);
      final resetFinder = find.byKey(multiBuilderResetKey);

      await tester.pumpWidget(
        MultiBuilderTestApp(
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
        ),
      );

      // Initial build
      expect(buildLog, [
        [0, 10]
      ]);

      // Increment first provider -> rebuild
      await tester.tap(incrementFinder);
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
      ]);

      // Swap to [provider3]
      await tester.tap(resetFinder);
      await tester.pump();
      // After swap, the builder should rebuild with the new list's states
      // Because the providers list changed, we detach from old and attach to new,
      // and setState is called with new states.
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
      ]);

      // Increment old provider1 should not trigger rebuild
      provider1.increment();
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
      ]);

      // Increment new provider3 should trigger rebuild
      provider3.increment();
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
        [21],
      ]);
    });

    testWidgets(
        'detects in-place provider list mutation (same list reference, different content)',
        (tester) async {
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(2);
      final providersList = [providerA];
      final buildLog = <List<int>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    MultiStateBuilder<int>(
                      providers: providersList,
                      builder: (_, states, __) {
                        buildLog.add(states);
                        return const SizedBox();
                      },
                    ),
                    TextButton(
                      key: const Key('mutate_in_place_btn'),
                      onPressed: () => setState(() {
                        providersList[0] = providerB;
                      }),
                      child: const Text('Mutate'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial build
      expect(buildLog, [
        [1]
      ]);

      // Mutate list in-place
      await tester.tap(find.byKey(const Key('mutate_in_place_btn')));
      await tester.pump();

      // The builder should rebuild with the new provider's state
      expect(buildLog, [
        [1],
        [2],
      ]);

      // Old providerA increments should not trigger rebuild
      providerA.increment();
      await tester.pump();
      expect(buildLog, [
        [1],
        [2],
      ]);

      // New providerB increments should trigger rebuild
      providerB.increment();
      await tester.pump();
      expect(buildLog, [
        [1],
        [2],
        [3],
      ]);
    });

    testWidgets(
      'does not reattach listeners when providers list replaced with an equal list (no-op)',
      (tester) async {
        final buildLog = <List<int>>[];
        final provider = CounterProvider(0);

        final incrementFinder = find.byKey(incrementProvider0Key);
        final noopFinder = find.byKey(multiBuilderNoopKey);

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider],
            builder: (_, states, __) {
              buildLog.add(states);
              return const SizedBox();
            },
          ),
        );

        // Initial build
        expect(buildLog, [
          [0]
        ]);

        // Increment → rebuild (state change)
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(buildLog, [
          [0],
          [1]
        ]);

        // No‑op: parent rebuilds (setState) but providers list is unchanged.
        // The parent rebuild causes the builder to be called again (expected).
        await tester.tap(noopFinder);
        await tester.pump();
        // Extra rebuild due to parent's setState, NOT because of a provider change.
        expect(buildLog, [
          [0],
          [1],
          [1]
        ]);

        // Increment again → rebuild (state change)
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(buildLog, [
          [0],
          [1],
          [1],
          [2]
        ]);
      },
    );

    testWidgets('detects provider list order change as different list',
        (tester) async {
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(2);
      final buildLog = <List<int>>[];
      final providers = [providerA, providerB]; // initial order

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  MultiStateBuilder<int>(
                    providers: providers,
                    builder: (_, states, __) {
                      buildLog.add(states);
                      return const SizedBox();
                    },
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      providers
                        ..clear()
                        ..addAll([providerB, providerA]);
                    }),
                    child: const Text('Swap Order'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(buildLog, [
        [1, 2]
      ]);

      await tester.tap(find.text('Swap Order'));
      await tester.pump();
      // Build log should now include [2, 1] (new order)
      expect(buildLog, [
        [1, 2],
        [2, 1]
      ]);
    });

    // =========================================================================
    // SECTION 6: EDGE CASES & CONCURRENT UPDATES
    // =========================================================================

    testWidgets(
      'builder updates to new provider states on list swap even when rebuildWhen returns false',
      (tester) async {
        final buildLog = <List<int>>[];
        final provider1 = CounterProvider(10);
        final provider2 = CounterProvider(20);
        final provider3 = CounterProvider(30);

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider1, provider2],
            newProviders: [provider3],
            rebuildWhen: (_, __) => false, // always false
            builder: (_, states, __) {
              buildLog.add(states);
              return const SizedBox();
            },
          ),
        );

        // Initial build
        expect(buildLog, [
          [10, 20]
        ]);

        // Swap to [provider3]
        await tester.tap(find.byKey(multiBuilderResetKey));
        await tester.pump();

        // Builder updates to new state despite rebuildWhen returning false
        expect(buildLog, [
          [10, 20],
          [30],
        ]);

        // Change new provider – should NOT rebuild (rebuildWhen false)
        provider3.increment();
        await tester.pump();
        expect(buildLog, [
          [10, 20],
          [30],
        ]);
      },
    );

    testWidgets(
      'rebuildWhen receives correct previous states after provider list swap',
      (tester) async {
        final previousStates = <List<int>>[];
        final currentStates = <List<int>>[];
        final provider1 = CounterProvider(10);
        final provider2 = CounterProvider(20);
        final provider3 = CounterProvider(30);

        await tester.pumpWidget(
          MultiBuilderTestApp(
            initialProviders: [provider1, provider2],
            newProviders: [provider3],
            rebuildWhen: (previous, current) {
              previousStates.add(previous);
              currentStates.add(current);
              return true;
            },
            builder: (_, __, ___) => const SizedBox(),
          ),
        );

        // Swap to [provider3]
        await tester.tap(find.byKey(multiBuilderResetKey));
        await tester.pump();

        // No rebuildWhen calls during swap (it's a list change, not a state change)
        expect(previousStates, isEmpty);
        expect(currentStates, isEmpty);

        // Change new provider
        provider3.increment();
        await tester.pump();

        // rebuildWhen should be called with correct previous (initial state of provider3)
        expect(previousStates, [
          [30],
        ]);
        expect(currentStates, [
          [31],
        ]);
      },
    );

    // =========================================================================
    // SECTION 7: CLEANUP & MEMORY LEAKS
    // =========================================================================

    testWidgets('detaches listeners when widget is removed from tree',
        (tester) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MultiStateBuilder<int>(
          providers: [provider],
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
        providers: [CounterProvider(), CounterProvider(5)],
        rebuildWhen: (prev, curr) => prev != curr,
        child: const SizedBox(),
        builder: (_, __, ___) => const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any(
            (e) => e.contains('providers') && e.contains('CounterProvider')),
        isTrue,
        reason:
            'Should expose providers list configuration. Found: $description',
      );
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(description.any((e) => e.contains('child')), isTrue);
    });
  });
}
