import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

const incrementProvider0ButtonKey = Key('multi_increment_p0');
const multiIncrementProvider0Key =
    Key('multi_increment_p0'); 
const multiResetButtonKey = Key('multi_reset_btn');
const multiNoopButtonKey = Key('multi_noop_btn');

class MultiListenerTestApp extends StatefulWidget {
  const MultiListenerTestApp({
    super.key,
    required this.initialProviders,
    this.newProviders, 
    required this.onListenerCalled,
    this.listenWhen,
  });

  final List<CounterProvider> initialProviders;
  final List<CounterProvider>? newProviders;
  final void Function(BuildContext context, List<int> states) onListenerCalled;
  final bool Function(List<int> previous, List<int> current)? listenWhen;

  @override
  State<MultiListenerTestApp> createState() => _MultiListenerTestAppState();
}

class _MultiListenerTestAppState extends State<MultiListenerTestApp> {
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
            MultiStateListener<int>(
              providers: _activeProviders,
              listenWhen: widget.listenWhen,
              listener: widget.onListenerCalled,
              child: const SizedBox(),
            ),
            // Button 1: Increments the current first provider
            TextButton(
              key: incrementProvider0ButtonKey,
              onPressed: () {
                if (_activeProviders.isNotEmpty) {
                  _activeProviders.first.increment();
                }
              },
              child: const Text('Increment'),
            ),
            // Button 2: Swaps to a completely different provider list
            TextButton(
              key: multiResetButtonKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.newProviders ?? [];
                });
              },
              child: const Text('Swap List'),
            ),
            // Button 3: Triggers a rebuild passing the original list reference
            TextButton(
              key: multiNoopButtonKey,
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
  group('MultiStateListener', () {
    // =========================================================================
    // SECTION 1: CORE FLUTTER HIERARCHY & FRAMEWORK CONTRACTS
    // =========================================================================

    testWidgets('throws AssertionError when child is not specified',
        (tester) async {
      const expectedMessage =
          'MultiStateListener<int> used outside of MultiStateListener must specify a child';

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: MyProvider().providersOne,
          listener: (_, __) {},
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>()
            .having((e) => e.message, 'message', expectedMessage),
      );
    });

    testWidgets('renders child when specified', (tester) async {
      const targetKey = Key('multi_listener_child');
      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: MyProvider().providersOne,
          listener: (_, __) {},
          child: const SizedBox(key: targetKey),
        ),
      );
      expect(find.byKey(targetKey), findsOneWidget);
    });

    testWidgets('works with empty providers list', (tester) async {
      int listenerCallCount = 0;
      List<int>? receivedStates;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: const [],
          listener: (_, states) {
            listenerCallCount++;
            receivedStates = states;
          },
          child: const SizedBox(),
        ),
      );

      await tester.pump();
      expect(listenerCallCount, 0);
      expect(receivedStates, null);
    });

    // =========================================================================
    // SECTION 2: INITIALIZATION TIMINGS & LIFECYCLES
    // =========================================================================

    testWidgets('does not call listener on initialization by default',
        (tester) async {
      final states = <List<int>>[];
      final providers = MyProvider().providersOne;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          shouldCallListenerOnInit: false,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      await tester.pump();
      expect(states, isEmpty);
    });

    testWidgets(
        'calls listener on initialization when shouldCallListenerOnInit is true',
        (tester) async {
      final states = <List<int>>[];
      final expectedStates = [
        [0, 10]
      ];
      final providers = MyProvider().providersOne;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          shouldCallListenerOnInit: true,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      await tester.pump();
      expect(states, expectedStates);
    });

    testWidgets('listener receives current states when called during init',
        (tester) async {
      List<int>? initStates;
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(9);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider1, provider2],
          shouldCallListenerOnInit: true,
          listener: (_, states) => initStates = states,
          child: const SizedBox(),
        ),
      );

      await tester.pump();
      expect(initStates, [5, 9]);
    });

    // =========================================================================
    // SECTION 3: STATE EMISSIONS & DATA ORDER GUARANTEES
    // =========================================================================

    testWidgets(
        'triggers listener with updated snapshot when a single provider emits a change',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;
      const expectedStates = [
        [1, 10],
      ];

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      providers.first.increment();
      await tester.pump();
      expect(states, expectedStates);
    });

    testWidgets(
        'provides correct state list in the listener (order matches providers)',
        (tester) async {
      List<int>? receivedStates;
      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(7);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider1, provider2],
          listener: (_, statesList) => receivedStates = statesList,
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();
      expect(receivedStates, [6, 7]);

      provider2.increment();
      await tester.pump();
      expect(receivedStates, [6, 8]);
    });

    testWidgets(
        'triggers listener sequentially for every individual provider update in the collection',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;
      const expectedStates = [
        [1, 10],
        [1, 20]
      ];

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, expectedStates);
    });

    testWidgets(
        'triggers listener for every individual state change in the provider list',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;
      const expectedStates = [
        [1, 10],
        [1, 20],
        [2, 20],
        [2, 30]
      ];

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, expectedStates);
    });

    // =========================================================================
    // SECTION 4: RUNTIME PROVIDER TRANSITIONS & LIST UPDATES
    // =========================================================================

    testWidgets(
      'updates when the provider is changed at runtime to a different provider from the list and '
      'unsubscribes from the old provider that is removed',
      (tester) async {
        final states = <List<int>>[];
        int listenerCallCount = 0;
        final providerA = CounterProvider(0);
        final providerB = CounterProvider(10);
        final providerC = CounterProvider(100);

        var activeProviders = [providerA, providerB];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MultiStateListener<int>(
                providers: activeProviders,
                listener: (_, statesList) {
                  listenerCallCount++;
                  states.add(statesList);
                },
                child: GestureDetector(
                  key: const Key('swap_provider_trigger'),
                  onTap: () {
                    setState(() {
                      activeProviders = [providerC, providerB];
                    });
                  },
                ),
              );
            },
          ),
        );

        expect(states, isEmpty);
        expect(listenerCallCount, 0);

        activeProviders.first.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
        ]);
        expect(listenerCallCount, 1);

        providerB.increment();
        await tester.pump();
        expect(states, [
          [1, 10],
          [1, 11],
        ]);
        expect(listenerCallCount, 2);
        await tester.tap(find.byKey(const Key('swap_provider_trigger')));
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
        ]);

        expect(listenerCallCount, 2);

        providerA.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
        ]);

        expect(listenerCallCount, 2);

        providerC.increment();
        providerB.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
          [101, 11],
          [101, 12],
        ]);
        expect(listenerCallCount, 4);
      },
    );

    testWidgets(
      'does not update when the provider is changed at runtime to same provider '
      'and stays subscribed to current provider',
      (tester) async {
        final states = <List<int>>[];
        const rebuildKey = Key('rebuild_same_providers_trigger');
        int listenerCallCount = 0;

        final providerA = CounterProvider(0);
        final providerB = CounterProvider(10);

        var activeProviders = [providerA, providerB];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MultiStateListener<int>(
                providers: activeProviders,
                listener: (_, statesList) {
                  listenerCallCount++;
                  states.add(statesList);
                },
                child: GestureDetector(
                  key: rebuildKey,
                  onTap: () {
                    setState(() {
                      activeProviders = [providerA, providerB];
                    });
                  },
                ),
              );
            },
          ),
        );

        expect(states, isEmpty);
        expect(listenerCallCount, 0);

        providerA.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
        ]);

        expect(listenerCallCount, 1);

        await tester.tap(find.byKey(rebuildKey));
        await tester.pump();

        expect(states, [
          [1, 10],
        ]);

        expect(listenerCallCount, 1);

        providerA.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [2, 10],
        ]);

        expect(listenerCallCount, 2);
      },
    );

    testWidgets(
        'updates subscription when providers list changes to a different list',
        (tester) async {
      final states = <List<int>>[];
      int listenerCallCount = 0;

      final provider1 = CounterProvider(0);
      final provider2 = CounterProvider(10);
      final provider3 = CounterProvider(20);

      final incrementFinder = find.byKey(incrementProvider0ButtonKey);
      final resetFinder = find.byKey(multiResetButtonKey);

      await tester.pumpWidget(
        MultiListenerTestApp(
          listenWhen: (previous, current) => true,
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          onListenerCalled: (_, statesList) {
            listenerCallCount++;
            states.add(statesList);
          },
        ),
      );

      expect(states, isEmpty);
      expect(listenerCallCount, 0);

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenerCallCount, 1);
      expect(states, [
        [1, 10],
      ]);

      await tester.tap(resetFinder);
      await tester.pump();

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenerCallCount, 2);
      expect(states, [
        [1, 10],
        [21],
      ]);

      provider1.increment();
      await tester.pump();

      expect(listenerCallCount, 2);
      expect(states, [
        [1, 10],
        [21],
      ]);
    });

    testWidgets(
        'does not reattach when providers list is replaced with an equal list (no-op)',
        (tester) async {
      final states = <List<int>>[];
      int listenerCallCount = 0;

      final provider = CounterProvider(0);

      final incrementFinder = find.byKey(incrementProvider0ButtonKey);
      final noopFinder = find.byKey(multiNoopButtonKey);

      await tester.pumpWidget(
        MultiListenerTestApp(
          initialProviders: [provider],
          onListenerCalled: (_, statesList) {
            listenerCallCount++;
            states.add(statesList);
          },
        ),
      );

      expect(states, isEmpty);
      expect(listenerCallCount, 0);

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenerCallCount, 1);
      expect(states, [
        [1],
      ]);

      await tester.tap(noopFinder);
      await tester.pump();

      expect(listenerCallCount, 1);
      expect(states, [
        [1],
      ]);

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenerCallCount, 2);
      expect(states, [
        [1],
        [2],
      ]);
    });

    // =========================================================================
    // SECTION 5: CONDITIONAL FILTERS & INTERCEPTIONS (listenWhen)
    // =========================================================================

    testWidgets('calls listenWhen with previous and current state lists',
        (tester) async {
      List<int>? latestPrevious;
      List<int>? latestCurrent;
      int listenWhenCallCount = 0;
      int listenerCallCount = 0;
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider1, provider2],
          listenWhen: (previous, current) {
            listenWhenCallCount++;
            latestPrevious = previous;
            latestCurrent = current;
            return true;
          },
          listener: (_, __) => listenerCallCount++,
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();

      expect(listenWhenCallCount, 1);
      expect(latestPrevious, [0, 10]);
      expect(latestCurrent, [1, 10]);
      expect(listenerCallCount, 1);
    });

    testWidgets('calls listener only when listenWhen returns true',
        (tester) async {
      final states = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);
      int listenWhenCallCount = 0;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider1, provider2],
          listenWhen: (previous, current) {
            listenWhenCallCount++;
            return current[0] % 2 == 0 && current[1] % 2 == 0;
          },
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();
      expect(states, isEmpty);
      expect(listenWhenCallCount, 1);

      provider1.increment();
      await tester.pump();
      expect(states, [
        [2, 10]
      ]);
      expect(listenWhenCallCount, 2);

      provider2.increment();
      await tester.pump();
      expect(states, [
        [2, 10]
      ]);
      expect(listenWhenCallCount, 3);

      provider2.increment();
      await tester.pump();
      expect(states, [
        [2, 10],
        [2, 12]
      ]);
      expect(listenWhenCallCount, 4);
    });

    testWidgets(
        'listenWhen receives correct previous and current after multiple state changes',
        (tester) async {
      final previousStates = <List<int>>[];
      final currentStates = <List<int>>[];
      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider1, provider2],
          listenWhen: (previous, current) {
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
          listener: (_, __) {},
          child: const SizedBox(),
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

    testWidgets(
        'does not call listener when listenWhen returns false on single state change in each given providers',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;
      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listenWhen: (_, __) => false,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, isEmpty);
    });

    testWidgets(
        'calls listener when listenWhen returns true on single state change in each given providers',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listenWhen: (_, __) => true,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, [
        [1, 10],
        [1, 20]
      ]);
    });

    testWidgets(
        'does not call listener when listenWhen returns false on multiple state change in each given providers',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;
      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listenWhen: (_, __) => false,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, isEmpty);
      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, isEmpty);
    });

    testWidgets(
        'calls listener when listenWhen returns true on multiple state change in each given providers',
        (tester) async {
      final states = <List<int>>[];
      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: providers,
          listenWhen: (_, __) => true,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, [
        [1, 10],
        [1, 20]
      ]);

      provider.incrementProviders(providers);
      await tester.pump();
      expect(states, [
        [1, 10],
        [1, 20],
        [2, 20],
        [2, 30]
      ]);
    });

    testWidgets(
        'calls listener with correct previous states when providers list changes',
        (tester) async {
      List<int>? previousStates;
      List<int>? currentStates;
      int listenWhenCalls = 0;

      final provider1 = CounterProvider(10);
      final provider2 = CounterProvider(20);
      final provider3 = CounterProvider(30);

      final incrementFinder = find.byKey(incrementProvider0ButtonKey);
      final resetFinder = find.byKey(multiResetButtonKey);

      await tester.pumpWidget(
        MultiListenerTestApp(
          initialProviders: [provider1, provider2],
          newProviders: [provider3],
          listenWhen: (previous, current) {
            listenWhenCalls++;
            previousStates = previous;
            currentStates = current;
            return true;
          },
          onListenerCalled: (_, __) {},
        ),
      );

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenWhenCalls, 1);
      expect(previousStates, [10, 20]);
      expect(currentStates, [11, 20]);

      await tester.tap(resetFinder);
      await tester.pump();

      await tester.tap(incrementFinder);
      await tester.pump();

      expect(listenWhenCalls, 2);
      expect(previousStates, [30]);
      expect(currentStates, [31]);
    });

// =========================================================================
    // SECTION 4B: ADVANCED ARCHITECTURAL & EDGE-CASE COVERS (MISSING SCENARIOS)
    // =========================================================================

    testWidgets(
        '1. safe to trigger navigation/dialogs inside listener (deferred execution)',
        (tester) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiStateListener<int>(
              providers: [provider],
              listener: (context, _) {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(title: Text('Alert')),
                );
              },
              child: const SizedBox(),
            ),
          ),
        ),
      );

      provider.increment();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
        '2. detects changes when the providers list is mutated in-place',
        (tester) async {
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(2);
      final providersList = [providerA];
      final states = <List<int>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    MultiStateListener<int>(
                      providers: providersList,
                      listener: (_, current) => states.add(current),
                      child: const SizedBox(),
                    ),
                    TextButton(
                      key: const Key('mutate_in_place_btn'),
                      onPressed: () => setState(() {
                        providersList[0] =
                            providerB; // Same list reference, different internal index item
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

      await tester.tap(find.byKey(const Key('mutate_in_place_btn')));
      await tester.pump();

      providerA.increment();
      await tester.pump();
      expect(states, isEmpty);

      providerB.increment();
      await tester.pump();
      expect(states, [
        [3]
      ]);
    });

    testWidgets(
        '3. does not fire listener on runtime list swap even if shouldCallListenerOnInit is true',
        (tester) async {
      final states = <List<int>>[];
      final providerA = CounterProvider(1);
      final providerB = CounterProvider(5);
      var currentProviders = [providerA];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  key: const Key('swap_trigger_tap'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => currentProviders = [providerB]),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: MultiStateListener<int>(
                      providers: currentProviders,
                      shouldCallListenerOnInit:
                          true, // Only applies to initState!
                      listener: (_, current) => states.add(current),
                      child: const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(states, [
        [1]
      ]);

      await tester.tap(find.byKey(const Key('swap_trigger_tap')));
      await tester.pumpAndSettle();

      expect(states, [
        [1]
      ]);

      providerB.increment();
      await tester.pumpAndSettle();

      expect(states, [
        [1],
        [6]
      ]);
    });

    testWidgets(
        '4. deep equality works with custom complex object states via listenWhen fallback',
        (tester) async {
      final states = <List<String>>[];

      final provider1 = StateNotifier<List<String>>(['initial']);
      final provider2 = StateNotifier<List<String>>(['data']);

      await tester.pumpWidget(
        MultiStateListener<List<String>>(
          providers: [provider1, provider2],
          listenWhen: (previous, current) {
            return previous[0].first.length != current[0].first.length;
          },
          listener: (_, current) => states.add(current[0]),
          child: const SizedBox(),
        ),
      );

      provider1.state = ['initial'];
      await tester.pumpAndSettle();
      expect(states, isEmpty);

      provider1.state = ['changed_longer_string'];
      await tester.pumpAndSettle();

      expect(states, [
        ['changed_longer_string']
      ]);
    });

    testWidgets(
        '5. documents that concurrent provider updates trigger separate sequential notifications',
        (tester) async {
      final states = <List<int>>[];
      final providerA = CounterProvider(0);
      final providerB = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [providerA, providerB],
          listener: (_, current) => states.add(current),
          child: const SizedBox(),
        ),
      );

      providerA.increment();
      providerB.increment();
      await tester.pump();

      expect(states, [
        [1, 10],
        [1, 11]
      ]);
    });

    testWidgets(
        '6. explicitly drops internal listener hooks and counts down to zero on clean removal',
        (tester) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: [provider],
          listener: (_, __) {},
          child: const SizedBox(),
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =========================================================================
    // SECTION 6: FLUTTER INSPECTOR DIAGNOSTICS & REFLECTIONS
    // =========================================================================

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiStateListener<int>(
        providers: [CounterProvider(), CounterProvider(5)],
        listener: (_, __) {},
        listenWhen: (prev, curr) => prev != curr,
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
        reason:
            'Properties description should expose the providers list configuration. Found: $description',
      );
      expect(description.any((e) => e.contains('listener')), isTrue);
      expect(description.any((e) => e.contains('listenWhen')), isTrue);
      expect(
          description.any((e) =>
              e.contains('shouldCallListenerOnInit') && e.contains('true')),
          isTrue);
    });
  });
}
