import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';
import 'package:provider_kit/src/state/notifiers/state_notifier.dart';
import 'package:provider_kit/src/state/state_field.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/widgets.dart';

const incrementProvider0ButtonKey = Key('multi_increment_p0');
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
            MultiStateListener<List<int>>(
              providers: () => [
                for (final provider in _activeProviders) provider.watch,
              ],
              listenWhen: widget.listenWhen,
              listener: widget.onListenerCalled,
              child: const SizedBox(),
            ),
            TextButton(
              key: incrementProvider0ButtonKey,
              onPressed: () {
                if (_activeProviders.isNotEmpty) {
                  _activeProviders.first.increment();
                }
              },
              child: const Text('Increment'),
            ),
            TextButton(
              key: multiResetButtonKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.newProviders ?? [];
                });
              },
              child: const Text('Swap List'),
            ),
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

@immutable
class _CombinedState {
  const _CombinedState({required this.first, required this.second});

  final int first;
  final bool second;

  @override
  bool operator ==(Object other) {
    return other is _CombinedState &&
        other.first == first &&
        other.second == second;
  }

  @override
  int get hashCode => Object.hash(first, second);
}

void main() {
  group('MultiStateListener', () {
    // =========================================================================
    // SECTION 1: CORE FLUTTER HIERARCHY & FRAMEWORK CONTRACTS
    // =========================================================================

    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      const expectedMessage =
          'MultiStateListener<int> used outside of MultiStateListener must specify a child';

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => provider.watch,
          listener: (_, __) {},
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          expectedMessage,
        ),
      );
    });

    testWidgets('renders child when specified', (tester) async {
      const targetKey = Key('multi_listener_child');
      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => provider.watch,
          listener: (_, __) {},
          child: const SizedBox(key: targetKey),
        ),
      );

      expect(find.byKey(targetKey), findsOneWidget);
    });

    // =========================================================================
    // SECTION 2: INITIALIZATION TIMINGS & LIFECYCLES
    // =========================================================================

    testWidgets('does not call listener on initialization by default', (
      tester,
    ) async {
      final states = <List<int>>[];
      final providers = MyProvider().providersOne;

      await tester.pumpWidget(
        MultiStateListener<List<int>>(
          providers: () => [for (final provider in providers) provider.watch],
          callListenerOnInit: false,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      await tester.pump();

      expect(states, isEmpty);
    });

    testWidgets(
      'calls listener on initialization when callListenerOnInit is true',
      (tester) async {
        final states = <List<int>>[];
        const expectedStates = [
          [0, 10],
        ];

        final providers = MyProvider().providersOne;

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [for (final provider in providers) provider.watch],
            callListenerOnInit: true,
            listener: (_, state) => states.add(state),
            child: const SizedBox(),
          ),
        );

        await tester.pump();

        expect(states, expectedStates);
      },
    );

    testWidgets(
      'calls initial listener before normal listener for a change before first frame',
      (tester) async {
        final field = StateField(0);
        final states = <int>[];

        await tester.pumpWidget(
          MultiStateListener<int>(
            providers: () => field.watch,
            callListenerOnInit: true,
            listener: (_, state) {
              states.add(state);
            },
            child: StateChangeDuringInit(
              onInit: () {
                field.state = 1;
              },
            ),
          ),
        );

        expect(states, [0, 1]);
      },
    );

    testWidgets(
      'delivers all listener notifications before the initial callback in order',
      (tester) async {
        final field = StateField(0);
        final states = <int>[];

        await tester.pumpWidget(
          MultiStateListener<int>(
            providers: () => field.watch,
            callListenerOnInit: true,
            listener: (_, state) {
              states.add(state);
            },
            child: StateChangeDuringInit(
              onInit: () {
                field.state = 1;
                field.state = 2;
                field.state = 3;
              },
            ),
          ),
        );

        expect(states, [0, 1, 2, 3]);
      },
    );

    testWidgets('queues state changes triggered by the initial listener', (
      tester,
    ) async {
      final field = StateField(0);
      final states = <int>[];

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => field.watch,
          callListenerOnInit: true,
          listener: (_, state) {
            states.add(state);

            if (state == 0) {
              field.state = 1;
            }
          },
          child: const SizedBox(),
        ),
      );

      await tester.pump();

      expect(states, [0, 1]);
    });

    testWidgets(
      'delivers later listener notifications normally after initialization',
      (tester) async {
        final field = StateField(0);
        final states = <int>[];

        await tester.pumpWidget(
          MultiStateListener<int>(
            providers: () => field.watch,
            callListenerOnInit: true,
            listener: (_, state) {
              states.add(state);
            },
            child: const SizedBox(),
          ),
        );

        expect(states, [0]);

        field.state = 1;
        await tester.pump();

        expect(states, [0, 1]);
      },
    );

    testWidgets(
      'listener receives current states when called during initialization',
      (tester) async {
        List<int>? initStates;

        final provider1 = CounterProvider(5);
        final provider2 = CounterProvider(9);

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            callListenerOnInit: true,
            listener: (_, states) => initStates = states,
            child: const SizedBox(),
          ),
        );

        await tester.pump();

        expect(initStates, [5, 9]);
      },
    );

    // =========================================================================
    // SECTION 3: STATE EMISSIONS & COMBINED STATE GUARANTEES
    // =========================================================================

    testWidgets(
      'triggers listener with updated combined state when one provider changes',
      (tester) async {
        final states = <List<int>>[];
        final provider = MyProvider();

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [
              for (final item in provider.providersOne) item.watch,
            ],
            listener: (_, statesList) => states.add(statesList),
            child: const SizedBox(),
          ),
        );

        provider.providersOne.first.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
        ]);
      },
    );

    testWidgets(
      'returns combined list in the same order as the providers callback',
      (tester) async {
        List<int>? receivedStates;

        final provider1 = CounterProvider(5);
        final provider2 = CounterProvider(7);

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            listener: (_, states) => receivedStates = states,
            child: const SizedBox(),
          ),
        );

        provider1.increment();
        await tester.pump();

        expect(receivedStates, [6, 7]);

        provider2.increment();
        await tester.pump();

        expect(receivedStates, [6, 8]);
      },
    );

    testWidgets(
      'triggers listener sequentially for every individual provider update',
      (tester) async {
        final states = <List<int>>[];
        final provider = MyProvider();

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [
              for (final item in provider.providersOne) item.watch,
            ],
            listener: (_, statesList) => states.add(statesList),
            child: const SizedBox(),
          ),
        );

        provider.incrementProviders(provider.providersOne);
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 20],
        ]);
      },
    );

    testWidgets(
      'triggers listener for every individual state change in the providers',
      (tester) async {
        final states = <List<int>>[];
        final provider = MyProvider();

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [
              for (final item in provider.providersOne) item.watch,
            ],
            listener: (_, statesList) => states.add(statesList),
            child: const SizedBox(),
          ),
        );

        provider.incrementProviders(provider.providersOne);
        await tester.pump();

        provider.incrementProviders(provider.providersOne);
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 20],
          [2, 20],
          [2, 30],
        ]);
      },
    );

    testWidgets('supports a record as the combined state', (tester) async {
      ({int first, int second})? receivedState;

      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(7);

      await tester.pumpWidget(
        MultiStateListener(
          providers: () => (first: provider1.watch, second: provider2.watch),
          listener: (_, state) {
            receivedState = state;
          },
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();

      expect(receivedState, (first: 6, second: 7));
    });

    testWidgets('supports a custom object as the combined state', (
      tester,
    ) async {
      _CombinedState? receivedState;

      final provider1 = CounterProvider(5);
      final provider2 = CounterProvider(7);

      await tester.pumpWidget(
        MultiStateListener(
          providers: () => _CombinedState(
            first: provider1.watch,
            second: provider2.watch.isEven,
          ),
          listener: (_, state) {
            receivedState = state;
          },
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();

      expect(receivedState, const _CombinedState(first: 6, second: false));
    });

    testWidgets('supports a list of states for collection-style usage', (
      tester,
    ) async {
      List<int>? receivedStates;

      final providers = [
        CounterProvider(),
        CounterProvider(10),
        CounterProvider(20),
      ];

      await tester.pumpWidget(
        MultiStateListener(
          providers: () => [for (final provider in providers) provider.watch],
          listener: (_, states) {
            receivedStates = states;
          },
          child: const SizedBox(),
        ),
      );

      providers[1].increment();
      await tester.pump();

      expect(receivedStates, [0, 11, 20]);
    });

    // =========================================================================
    // SECTION 4: DEPENDENCY TRACKING
    // =========================================================================

    testWidgets('asserts when no watched state source is collected', (
      tester,
    ) async {
      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => provider.state,
          listener: (_, __) {},
          child: const SizedBox(),
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    test(
      '.watch throws an assertion when used outside a MultiState collection',
      () {
        final provider = CounterProvider();

        expect(() => provider.watch, throwsA(isA<AssertionError>()));
      },
    );

    testWidgets('does not register the same dependency more than once', (
      tester,
    ) async {
      final states = <(int, int)>[];
      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateListener(
          providers: () => (first: provider.watch, second: provider.watch),
          listener: (_, state) {
            states.add((state.first, state.second));
          },
          child: const SizedBox(),
        ),
      );

      provider.increment();
      await tester.pump();

      expect(states, [(1, 1)]);
    });

    testWidgets(
      'updates dependencies when the dependency graph changes during a state change',
      (tester) async {
        final states = <int>[];

        final providerA = CounterProvider(0);
        final providerB = CounterProvider(100);

        await tester.pumpWidget(
          MultiStateListener<int>(
            providers: () {
              if (providerA.state.isEven) {
                return providerA.watch;
              }

              return providerB.watch;
            },
            listener: (_, current) {
              states.add(current);
            },
            child: const SizedBox(),
          ),
        );

        // Initially providerA is watched.
        providerA.increment(); // A: 0 -> 1
        await tester.pump();

        // The dependency switches from A to B.
        expect(states, [100]);

        // A is no longer watched, so this must not trigger the listener.
        providerA.increment(); // A: 1 -> 2
        await tester.pump();

        expect(states, [100]);

        // B is watched, so this triggers the listener.
        // During this callback, the dependency switches back to A.
        providerB.increment(); // B: 100 -> 101
        await tester.pump();

        expect(states, [100, 2]);

        // A is watched again.
        providerA.increment(); // A: 2 -> 3
        await tester.pump();

        expect(states, [100, 2, 101]);
      },
    );

    testWidgets(
      'uses newly collected dependencies when the providers callback changes',
      (tester) async {
        final states = <List<int>>[];

        final providerA = CounterProvider(0);
        final providerB = CounterProvider(10);
        final providerC = CounterProvider(100);

        var activeProviders = [providerA, providerB];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MultiStateListener<List<int>>(
                providers: () => [
                  for (final provider in activeProviders) provider.watch,
                ],
                listener: (_, current) {
                  states.add(current);
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

        providerA.increment();
        await tester.pump();

        providerB.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
        ]);

        await tester.tap(find.byKey(const Key('swap_provider_trigger')));
        await tester.pump();

        providerA.increment();
        await tester.pump();

        providerC.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
          [101, 11],
        ]);
      },
    );

    testWidgets(
      'updates dependencies even when the provider collection is mutated in place',
      (tester) async {
        final providerA = CounterProvider(1);
        final providerB = CounterProvider(2);

        final activeProviders = [providerA];

        final states = <List<int>>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      MultiStateListener<List<int>>(
                        providers: () => [
                          for (final provider in activeProviders)
                            provider.watch,
                        ],
                        listener: (_, current) {
                          states.add(current);
                        },
                        child: const SizedBox(),
                      ),
                      TextButton(
                        key: const Key('mutate_in_place_btn'),
                        onPressed: () {
                          setState(() {
                            activeProviders[0] = providerB;
                          });
                        },
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
          [3],
        ]);
      },
    );

    // =========================================================================
    // SECTION 5: RUNTIME PROVIDER TRANSITIONS & NO-OP REBUILDS
    // =========================================================================

    testWidgets(
      'unsubscribes from removed providers and subscribes to new providers',
      (tester) async {
        final states = <List<int>>[];
        var listenerCallCount = 0;

        final providerA = CounterProvider(0);
        final providerB = CounterProvider(10);
        final providerC = CounterProvider(100);

        await tester.pumpWidget(
          MultiListenerTestApp(
            initialProviders: [providerA, providerB],
            newProviders: [providerC, providerB],
            listenWhen: (_, __) => true,
            onListenerCalled: (_, statesList) {
              listenerCallCount++;
              states.add(statesList);
            },
          ),
        );

        providerA.increment();
        await tester.pump();

        providerB.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
        ]);
        expect(listenerCallCount, 2);

        await tester.tap(find.byKey(multiResetButtonKey));
        await tester.pump();

        providerA.increment();
        await tester.pump();

        expect(listenerCallCount, 2);

        providerC.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
          [1, 11],
          [101, 11],
        ]);
        expect(listenerCallCount, 3);
      },
    );

    testWidgets(
      'does not call listener when rebuilt with the same dependencies',
      (tester) async {
        final states = <List<int>>[];
        var listenerCallCount = 0;

        final providerA = CounterProvider(0);
        final providerB = CounterProvider(10);

        await tester.pumpWidget(
          MultiListenerTestApp(
            initialProviders: [providerA, providerB],
            onListenerCalled: (_, statesList) {
              listenerCallCount++;
              states.add(statesList);
            },
          ),
        );

        providerA.increment();
        await tester.pump();

        expect(states, [
          [1, 10],
        ]);
        expect(listenerCallCount, 1);

        await tester.tap(find.byKey(multiNoopButtonKey));
        await tester.pump();

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
      'does not call listener when dependencies change during widget update',
      (tester) async {
        final states = <List<int>>[];

        final providerA = CounterProvider(10);
        final providerB = CounterProvider(20);
        final providerC = CounterProvider(30);

        await tester.pumpWidget(
          MultiListenerTestApp(
            initialProviders: [providerA, providerB],
            newProviders: [providerC],
            listenWhen: (_, __) => true,
            onListenerCalled: (_, statesList) {
              states.add(statesList);
            },
          ),
        );

        providerA.increment();
        await tester.pump();

        expect(states, [
          [11, 20],
        ]);

        await tester.tap(find.byKey(multiResetButtonKey));
        await tester.pump();

        expect(states, [
          [11, 20],
        ]);

        providerC.increment();
        await tester.pump();

        expect(states, [
          [11, 20],
          [31],
        ]);
      },
    );

    // =========================================================================
    // SECTION 6: CONDITIONAL FILTERS & INTERCEPTIONS (listenWhen)
    // =========================================================================

    testWidgets('calls listenWhen with previous and current combined states', (
      tester,
    ) async {
      List<int>? latestPrevious;
      List<int>? latestCurrent;
      var listenWhenCallCount = 0;
      var listenerCallCount = 0;

      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateListener<List<int>>(
          providers: () => [provider1.watch, provider2.watch],
          listenWhen: (previous, current) {
            listenWhenCallCount++;
            latestPrevious = previous;
            latestCurrent = current;
            return true;
          },
          listener: (_, __) {
            listenerCallCount++;
          },
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

    testWidgets('calls listener only when listenWhen returns true', (
      tester,
    ) async {
      final states = <List<int>>[];
      var listenWhenCallCount = 0;

      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        MultiStateListener<List<int>>(
          providers: () => [provider1.watch, provider2.watch],
          listenWhen: (previous, current) {
            listenWhenCallCount++;
            return current[0].isEven && current[1].isEven;
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
        [2, 10],
      ]);
      expect(listenWhenCallCount, 2);

      provider2.increment();
      await tester.pump();

      expect(states, [
        [2, 10],
      ]);
      expect(listenWhenCallCount, 3);

      provider2.increment();
      await tester.pump();

      expect(states, [
        [2, 10],
        [2, 12],
      ]);
      expect(listenWhenCallCount, 4);
    });

    testWidgets(
      'listenWhen receives correct previous and current values after multiple changes',
      (tester) async {
        final previousStates = <List<int>>[];
        final currentStates = <List<int>>[];

        final provider1 = CounterProvider();
        final provider2 = CounterProvider(10);

        await tester.pumpWidget(
          MultiStateListener<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
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
      },
    );

    testWidgets('applies listenWhen before queuing listener notifications', (
      tester,
    ) async {
      final field = StateField(0);

      final states = <int>[];
      final transitions = <({int previous, int current})>[];

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => field.watch,
          callListenerOnInit: true,
          listenWhen: (previous, current) {
            transitions.add((previous: previous, current: current));

            return current.isEven;
          },
          listener: (_, state) {
            states.add(state);
          },
          child: StateChangeDuringInit(
            onInit: () {
              field.state = 1;
              field.state = 2;
              field.state = 3;
            },
          ),
        ),
      );

      expect(transitions, [
        (previous: 0, current: 1),
        (previous: 1, current: 2),
        (previous: 2, current: 3),
      ]);

      // Initial callback is always delivered.
      // Normal callbacks are filtered by listenWhen.
      expect(states, [0, 2]);
    });

    testWidgets(
      'updates its previous state even when listenWhen returns false',
      (tester) async {
        final previousValues = <int>[];
        final currentValues = <int>[];
        final states = <int>[];

        final provider = CounterProvider();

        await tester.pumpWidget(
          MultiStateListener<int>(
            providers: () => provider.watch,
            listenWhen: (previous, current) {
              previousValues.add(previous);
              currentValues.add(current);

              return current == 2;
            },
            listener: (_, current) {
              states.add(current);
            },
            child: const SizedBox(),
          ),
        );

        provider.increment();
        await tester.pump();

        provider.increment();
        await tester.pump();

        expect(previousValues, [0, 1]);
        expect(currentValues, [1, 2]);
        expect(states, [2]);
      },
    );

    testWidgets('does not call listener when listenWhen always returns false', (
      tester,
    ) async {
      final states = <List<int>>[];

      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateListener<List<int>>(
          providers: () => [for (final item in providers) item.watch],
          listenWhen: (_, __) => false,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();

      provider.incrementProviders(providers);
      await tester.pump();

      expect(states, isEmpty);
    });

    testWidgets('calls listener when listenWhen always returns true', (
      tester,
    ) async {
      final states = <List<int>>[];

      final provider = MyProvider();
      final providers = provider.providersOne;

      await tester.pumpWidget(
        MultiStateListener<List<int>>(
          providers: () => [for (final item in providers) item.watch],
          listenWhen: (_, __) => true,
          listener: (_, statesList) => states.add(statesList),
          child: const SizedBox(),
        ),
      );

      provider.incrementProviders(providers);
      await tester.pump();

      expect(states, [
        [1, 10],
        [1, 20],
      ]);
    });

    // =========================================================================
    // SECTION 7: COLLECTION EQUALITY
    // =========================================================================

    testWidgets(
      'uses deep equality for collection combined states by default',
      (tester) async {
        final receivedStates = <List<String>>[];

        final provider = StateNotifier<List<String>>(['initial']);

        await tester.pumpWidget(
          MultiStateListener<List<String>>(
            providers: () => provider.watch,
            listener: (_, current) {
              receivedStates.add(current);
            },
            child: const SizedBox(),
          ),
        );

        provider.state = ['initial'];
        await tester.pump();

        expect(receivedStates, isEmpty);

        provider.state = ['changed'];
        await tester.pump();

        expect(receivedStates, [
          ['changed'],
        ]);
      },
    );

    testWidgets('allows listenWhen to override default collection equality', (
      tester,
    ) async {
      final states = <List<String>>[];

      final provider = StateNotifier<List<String>>(['initial']);

      await tester.pumpWidget(
        MultiStateListener<List<String>>(
          providers: () => provider.watch,
          listenWhen: (previous, current) {
            return previous.first.length != current.first.length;
          },
          listener: (_, current) {
            states.add(current);
          },
          child: const SizedBox(),
        ),
      );

      provider.state = ['initial'];
      await tester.pump();

      expect(states, isEmpty);

      provider.state = ['changed_longer_string'];
      await tester.pump();

      expect(states, [
        ['changed_longer_string'],
      ]);
    });

    // =========================================================================
    // SECTION 8: LISTENER SAFETY & CALLBACK BEHAVIOR
    // =========================================================================

    testWidgets('is safe to trigger navigation or dialogs inside listener', (
      tester,
    ) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiStateListener<int>(
              providers: () => provider.watch,
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

    // =========================================================================
    // SECTION 9: INITIAL CALLBACK + RUNTIME DEPENDENCY CHANGES
    // =========================================================================

    testWidgets(
      'does not call listener again when dependencies change at runtime even when callListenerOnInit is true',
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
                    onTap: () {
                      setState(() {
                        currentProviders = [providerB];
                      });
                    },
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: MultiStateListener<List<int>>(
                        providers: () => [
                          for (final provider in currentProviders)
                            provider.watch,
                        ],
                        callListenerOnInit: true,
                        listener: (_, current) {
                          states.add(current);
                        },
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
          [1],
        ]);

        await tester.tap(find.byKey(const Key('swap_trigger_tap')));
        await tester.pumpAndSettle();

        expect(states, [
          [1],
        ]);

        providerB.increment();
        await tester.pumpAndSettle();

        expect(states, [
          [1],
          [6],
        ]);
      },
    );

    // =========================================================================
    // SECTION 10: LISTENER DISPOSAL
    // =========================================================================

    testWidgets('removes dependency listeners when widget is disposed', (
      tester,
    ) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MultiStateListener<int>(
          providers: () => provider.watch,
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
    // SECTION 11: FLUTTER INSPECTOR & DIAGNOSTICS
    // =========================================================================

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final provider = CounterProvider();

      final widget = MultiStateListener<int>(
        providers: () => provider.watch,
        listener: (_, __) {},
        listenWhen: (previous, current) => previous != current,
        callListenerOnInit: true,
        child: const SizedBox(),
      );

      final builder = DiagnosticPropertiesBuilder();

      widget.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('providers')), isTrue);

      expect(description.any((value) => value.contains('listener')), isTrue);

      expect(description.any((value) => value.contains('listenWhen')), isTrue);

      expect(
        description.any(
          (value) =>
              value.contains('callListenerOnInit') && value.contains('true'),
        ),
        isTrue,
      );
    });
  });
}
