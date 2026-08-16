import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

// Standardized finder keys
const incrementConsumerProvider0Key = Key('multi_consumer_increment_p0');
const multiConsumerResetKey = Key('multi_consumer_reset_btn');
const multiConsumerNoopKey = Key('multi_consumer_noop_btn');
const consumerBuilderOutputKey = Key('consumer_builder_output');

/// Test app to manage provider list swapping and track both listener and builder calls.
class MultiConsumerTestApp extends StatefulWidget {
  const MultiConsumerTestApp({
    super.key,
    required this.initialProviders,
    this.newProviders,
    required this.builder,
    required this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.shouldCallListenerOnInit = false,
  });

  final List<CounterProvider> initialProviders;
  final List<CounterProvider>? newProviders;
  final Widget Function(BuildContext context, List<int> states, Widget? child)
      builder;
  final void Function(BuildContext context, List<int> states) listener;
  final bool Function(List<int> previous, List<int> current)? listenWhen;
  final bool Function(List<int> previous, List<int> current)? rebuildWhen;
  final bool shouldCallListenerOnInit;

  @override
  State<MultiConsumerTestApp> createState() => _MultiConsumerTestAppState();
}

class _MultiConsumerTestAppState extends State<MultiConsumerTestApp> {
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
            MultiStateConsumer<int>(
              providers: _activeProviders,
              builder: widget.builder,
              listener: widget.listener,
              listenWhen: widget.listenWhen,
              rebuildWhen: widget.rebuildWhen,
              shouldCallListenerOnInit: widget.shouldCallListenerOnInit,
              child: const SizedBox(key: Key('multi_consumer_child')),
            ),
            TextButton(
              key: incrementConsumerProvider0Key,
              onPressed: () {
                if (_activeProviders.isNotEmpty) {
                  _activeProviders.first.increment();
                }
              },
              child: const Text('Increment'),
            ),
            TextButton(
              key: multiConsumerResetKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.newProviders ?? [];
                });
              },
              child: const Text('Swap List'),
            ),
            TextButton(
              key: multiConsumerNoopKey,
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
  group('MultiStateConsumer', () {
    // =========================================================================
    // SECTION 1: CORE RENDERING & CHILD HANDLING
    // =========================================================================

    testWidgets('renders builder output and passes child', (tester) async {
      const childKey = Key('consumer_child');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateConsumer<int>(
            providers: MyProvider().providersOne,
            builder: (_, states, child) {
              return Row(
                children: [
                  child!,
                  Text('${states[0]}-${states[1]}',
                      key: consumerBuilderOutputKey),
                ],
              );
            },
            listener: (_, __) {},
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byKey(consumerBuilderOutputKey), findsOneWidget);
      expect(find.text('0-10'), findsOneWidget);
    });

    testWidgets('works with empty providers list', (tester) async {
      int buildCount = 0;
      int listenerCallCount = 0;
      List<int>? lastStates;

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: const [],
          builder: (_, states, __) {
            buildCount++;
            lastStates = states;
            return const SizedBox();
          },
          listener: (_, __) => listenerCallCount++,
        ),
      );

      expect(buildCount, 1); // initial build
      expect(lastStates, isEmpty);
      expect(listenerCallCount, 0); // listener not called
    });

    testWidgets('child widget is preserved across rebuilds', (tester) async {
      const childKey = Key('child_preserved');
      int childRebuildCount = 0;
      int builderBuildCount = 0;
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateConsumer<int>(
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
            listener: (_, __) {},
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
    // SECTION 2: INITIALIZATION (shouldCallListenerOnInit)
    // =========================================================================

    testWidgets(
        'does not call listener on initialization by default (builder still builds)',
        (tester) async {
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];
      final provider = CounterProvider(5);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider],
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listener: (_, states) => listenerLog.add(states),
          shouldCallListenerOnInit: false,
        ),
      );

      // Builder builds once with initial state
      expect(buildLog, [
        [5]
      ]);
      // Listener not called
      expect(listenerLog, isEmpty);
    });

    testWidgets(
        'calls listener on initialization when shouldCallListenerOnInit is true',
        (tester) async {
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];
      final provider = CounterProvider(5);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider],
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listener: (_, states) => listenerLog.add(states),
          shouldCallListenerOnInit: true,
        ),
      );

      // Builder builds once with initial state
      expect(buildLog, [
        [5]
      ]);
      // Listener called once with initial state
      expect(listenerLog, [
        [5]
      ]);
    });

    testWidgets('listener receives correct initial states when called on init',
        (tester) async {
      List<int>? initListenerStates;
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(9);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider1, provider2],
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, states) => initListenerStates = states,
          shouldCallListenerOnInit: true,
        ),
      );

      expect(initListenerStates, [5, 9]);
    });

    // =========================================================================
    // SECTION 3: STATE EMISSIONS & DATA ORDER
    // =========================================================================

    testWidgets('listener is called per change (not batched)', (tester) async {
      final listenerLog = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: providers,
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, states) => listenerLog.add(states),
          listenWhen: (_, __) => true,
        ),
      );

      // Synchronous updates
      provider.incrementProviders(providers);
      await tester.pump();

      // Listener called twice: first [1,10], then [1,20]
      expect(listenerLog, [
        [1, 10],
        [1, 20],
      ]);
    });

    testWidgets(
        'builder rebuilds only once for synchronous multiple updates (batched)',
        (tester) async {
      final buildLog = <List<int>>[];
      final listenerLog = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: providers,
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listener: (_, states) => listenerLog.add(states),
          listenWhen: (_, __) => true,
        ),
      );

      // Initial build
      expect(buildLog, [
        [0, 10]
      ]);
      expect(listenerLog, isEmpty);

      // Synchronous updates
      provider.incrementProviders(providers);
      await tester.pump();

      // Builder batched to final state [1,20]
      expect(buildLog, [
        [0, 10],
        [1, 20],
      ]);
      // Listener still called twice
      expect(listenerLog, [
        [1, 10],
        [1, 20],
      ]);
    });

    testWidgets(
        'states order matches providers list order (listener and builder)',
        (tester) async {
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(7);
      List<int>? listenerStates;
      List<int>? builderStates;

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider1, provider2],
          builder: (_, states, __) {
            builderStates = states;
            return const SizedBox();
          },
          listener: (_, states) => listenerStates = states,
        ),
      );

      expect(builderStates, [5, 7]);
      expect(listenerStates, isNull); // listener not called yet

      provider1.increment();
      await tester.pump();
      expect(builderStates, [6, 7]);
      expect(listenerStates, [6, 7]);

      provider2.increment();
      await tester.pump();
      expect(builderStates, [6, 8]);
      expect(listenerStates, [6, 8]);
    });

    // =========================================================================
    // SECTION 4: FILTERING (listenWhen & rebuildWhen)
    // =========================================================================

    testWidgets(
        'listenWhen controls listener calls, rebuildWhen controls rebuilds',
        (tester) async {
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider],
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listener: (_, states) => listenerLog.add(states),
          listenWhen: (_, current) => current[0] % 2 == 0, // only even
          rebuildWhen: (_, current) => current[0] % 2 == 1, // only odd
        ),
      );

      // Initial build
      expect(buildLog, [
        [0]
      ]);
      expect(listenerLog, isEmpty);

      provider.increment(); // 1 (odd)
      await tester.pump();
      // Listener not called (listenWhen false), builder rebuilt (rebuildWhen true)
      expect(listenerLog, isEmpty);
      expect(buildLog, [
        [0],
        [1],
      ]);

      provider.increment(); // 2 (even)
      await tester.pump();
      // Listener called, builder not rebuilt (rebuildWhen false)
      expect(listenerLog, [
        [2]
      ]);
      expect(buildLog, [
        [0],
        [1],
      ]);
    });

    testWidgets(
        'listenWhen receives correct previous/current states (same as listener)',
        (tester) async {
      final listenWhenPrevious = <List<int>>[];
      final listenWhenCurrent = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider1, provider2],
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          listenWhen: (previous, current) {
            listenWhenPrevious.add(previous);
            listenWhenCurrent.add(current);
            return true;
          },
        ),
      );

      provider1.increment();
      await tester.pump();
      provider1.increment();
      await tester.pump();

      expect(listenWhenPrevious, [
        [0, 10],
        [1, 10],
      ]);
      expect(listenWhenCurrent, [
        [1, 10],
        [2, 10],
      ]);
    });

    testWidgets(
        'rebuildWhen receives correct previous/current states (same as builder)',
        (tester) async {
      final rebuildWhenPrevious = <List<int>>[];
      final rebuildWhenCurrent = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider1, provider2],
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          rebuildWhen: (previous, current) {
            rebuildWhenPrevious.add(previous);
            rebuildWhenCurrent.add(current);
            return true;
          },
        ),
      );

      provider1.increment();
      await tester.pump();
      provider1.increment();
      await tester.pump();

      expect(rebuildWhenPrevious, [
        [0, 10],
        [1, 10],
      ]);
      expect(rebuildWhenCurrent, [
        [1, 10],
        [2, 10],
      ]);
    });

    // =========================================================================
    // SECTION 5: RUNTIME PROVIDER LIST TRANSITIONS
    // =========================================================================

    testWidgets(
        'updates subscriptions when providers list changes to a different list',
        (tester) async {
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];
      final provider1 = CounterProvider(0);
      final provider2 = CounterProvider(10);
      final provider3 = CounterProvider(20);

      final incrementFinder = find.byKey(incrementConsumerProvider0Key);
      final resetFinder = find.byKey(multiConsumerResetKey);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          listener: (_, states) => listenerLog.add(states),
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listenWhen: (_, __) => true,
        ),
      );

      // Initial build
      expect(buildLog, [
        [0, 10]
      ]);
      expect(listenerLog, isEmpty);

      // Increment first provider -> rebuild and listener call
      await tester.tap(incrementFinder);
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
      ]);
      expect(listenerLog, [
        [1, 10],
      ]);

      // Swap to [provider3]
      await tester.tap(resetFinder);
      await tester.pump();
      // Builder updates to new state, listener not called (no state change, just list change)
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
      ]);
      expect(listenerLog, [
        [1, 10],
      ]);

      // Increment old provider1 should not trigger anything
      provider1.increment();
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
      ]);
      expect(listenerLog, [
        [1, 10],
      ]);

      // Increment new provider3 -> listener called, builder rebuilds
      provider3.increment();
      await tester.pump();
      expect(buildLog, [
        [0, 10],
        [1, 10],
        [20],
        [21],
      ]);
      expect(listenerLog, [
        [1, 10],
        [21],
      ]);
    });

    testWidgets(
        'detects in-place provider list mutation (same list reference, different content)',
        (tester) async {
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(2);
      final providersList = [providerA];
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    MultiStateConsumer<int>(
                      providers: providersList,
                      builder: (_, states, __) {
                        buildLog.add(states);
                        return const SizedBox();
                      },
                      listener: (_, states) => listenerLog.add(states),
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
      expect(listenerLog, isEmpty);

      // Mutate list in-place
      await tester.tap(find.byKey(const Key('mutate_in_place_btn')));
      await tester.pump();

      // Builder updates to new state, listener not called
      expect(buildLog, [
        [1],
        [2],
      ]);
      expect(listenerLog, isEmpty);

      // Old providerA increments should not trigger anything
      providerA.increment();
      await tester.pump();
      expect(buildLog, [
        [1],
        [2],
      ]);
      expect(listenerLog, isEmpty);

      // New providerB increments -> listener called, builder rebuilds
      providerB.increment();
      await tester.pump();
      expect(buildLog, [
        [1],
        [2],
        [3],
      ]);
      expect(listenerLog, [
        [3],
      ]);
    });

    testWidgets(
        'does not reattach listeners when providers list replaced with an equal list (no-op)',
        (tester) async {
      final listenerLog = <List<int>>[];
      final buildLog = <List<int>>[];
      final provider = CounterProvider(0);

      final incrementFinder = find.byKey(incrementConsumerProvider0Key);
      final noopFinder = find.byKey(multiConsumerNoopKey);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider],
          listener: (_, states) => listenerLog.add(states),
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
      expect(listenerLog, isEmpty);

      // Increment → rebuild and listener call
      await tester.tap(incrementFinder);
      await tester.pump();
      expect(buildLog, [
        [0],
        [1],
      ]);
      expect(listenerLog, [
        [1],
      ]);

      // No‑op parent rebuild (providers list unchanged)
      await tester.tap(noopFinder);
      await tester.pump();
      // Builder rebuilds once (parent rebuild), listener not called
      expect(buildLog, [
        [0],
        [1],
        [1],
      ]);
      expect(listenerLog, [
        [1],
      ]);

      // Increment again → rebuild and listener call
      await tester.tap(incrementFinder);
      await tester.pump();
      expect(buildLog, [
        [0],
        [1],
        [1],
        [2],
      ]);
      expect(listenerLog, [
        [1],
        [2],
      ]);
    });

    testWidgets('detects provider list order change as different list',
        (tester) async {
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(2);
      final buildLog = <List<int>>[];
      final listenerLog = <List<int>>[];
      final providers = [providerA, providerB]; // initial order

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  MultiStateConsumer<int>(
                    providers: providers,
                    builder: (_, states, __) {
                      buildLog.add(states);
                      return const SizedBox();
                    },
                    listener: (_, states) => listenerLog.add(states),
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
      expect(listenerLog, isEmpty);

      await tester.tap(find.text('Swap Order'));
      await tester.pump();

      // Builder updates to new order, listener not called (no state change)
      expect(buildLog, [
        [1, 2],
        [2, 1],
      ]);
      expect(listenerLog, isEmpty);

      // Change providerA (now second) -> listener called, builder rebuilds
      providerA.increment();
      await tester.pump();
      expect(buildLog, [
        [1, 2],
        [2, 1],
        [2, 2],
      ]);
      expect(listenerLog, [
        [2, 2],
      ]);
    });

    // =========================================================================
    // SECTION 6: EDGE CASES & CONCURRENT UPDATES
    // =========================================================================

    testWidgets(
        'builder updates to new provider states on list swap even when rebuildWhen returns false',
        (tester) async {
      final buildLog = <List<int>>[];
      final listenerLog = <List<int>>[];
      final provider1 = CounterProvider(10);
      final provider2 = CounterProvider(20);
      final provider3 = CounterProvider(30);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          builder: (_, states, __) {
            buildLog.add(states);
            return const SizedBox();
          },
          listener: (_, states) => listenerLog.add(states),
          rebuildWhen: (_, __) => false, // never rebuild on state changes
          listenWhen: (_, __) => true,
        ),
      );

      // Initial build
      expect(buildLog, [
        [10, 20]
      ]);
      expect(listenerLog, isEmpty);

      // Swap to [provider3]
      await tester.tap(find.byKey(multiConsumerResetKey));
      await tester.pump();

      // Builder updates to new state despite rebuildWhen false (list swap forces rebuild)
      expect(buildLog, [
        [10, 20],
        [30],
      ]);
      expect(listenerLog, isEmpty);

      // Change new provider – listener called, builder NOT rebuilt (rebuildWhen false)
      provider3.increment();
      await tester.pump();
      expect(buildLog, [
        [10, 20],
        [30],
      ]);
      expect(listenerLog, [
        [31],
      ]);
    });

    testWidgets(
        'listener receives correct previous states after provider list swap',
        (tester) async {
      final listenWhenPrevious = <List<int>>[];
      final listenWhenCurrent = <List<int>>[];
      final provider1 = CounterProvider(10);
      final provider2 = CounterProvider(20);
      final provider3 = CounterProvider(30);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          listener: (_, __) {},
          builder: (_, __, ___) => const SizedBox(),
          listenWhen: (previous, current) {
            listenWhenPrevious.add(previous);
            listenWhenCurrent.add(current);
            return true;
          },
        ),
      );

      // Swap to [provider3]
      await tester.tap(find.byKey(multiConsumerResetKey));
      await tester.pump();

      // No listenWhen calls during swap (no state change)
      expect(listenWhenPrevious, isEmpty);
      expect(listenWhenCurrent, isEmpty);

      // Change new provider
      provider3.increment();
      await tester.pump();

      // listenWhen called with correct previous (initial state of provider3)
      expect(listenWhenPrevious, [
        [30],
      ]);
      expect(listenWhenCurrent, [
        [31],
      ]);
    });

    // =========================================================================
    // SECTION 7: CLEANUP & MEMORY LEAKS
    // =========================================================================

    testWidgets('detaches listeners when widget is removed from tree',
        (tester) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: [provider],
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    testWidgets(
      'safe to trigger navigation/dialogs inside listener (deferred execution)',
      (tester) async {
        final provider = CounterProvider(0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MultiStateConsumer<int>(
                providers: [provider],
                builder: (_, __, ___) => const SizedBox(),
                listener: (context, _) {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(title: Text('Alert')),
                  );
                },
                listenWhen: (_, __) => true,
              ),
            ),
          ),
        );

        // Trigger listener
        provider.increment();
        await tester.pump(); // process the deferred callback
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    // =========================================================================
    // SECTION 8: FLUTTER INSPECTOR DIAGNOSTICS
    // =========================================================================

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiStateConsumer<int>(
        providers: [CounterProvider(), CounterProvider(5)],
        builder: (_, __, ___) => const SizedBox(),
        listener: (_, __) {},
        listenWhen: (prev, curr) => prev != curr,
        rebuildWhen: (prev, curr) => prev != curr,
        shouldCallListenerOnInit: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any(
            (e) => e.contains('providers') && e.contains('CounterProvider')),
        isTrue,
        reason: 'Should expose providers list. Found: $description',
      );
      expect(description.any((e) => e.contains('listener')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(description.any((e) => e.contains('rebuildWhen')), isTrue);
      expect(
          description.any((e) =>
              e.contains('shouldCallListenerOnInit') && e.contains('true')),
          isTrue);
      expect(description.any((e) => e.contains('child')), isTrue);
    });
  });
}
