import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

const listenerResetButtonKey = Key('listener_reset_button');
const listenerNoopButtonKey = Key('listener_noop_button');
const listenerIncrementButtonKey = Key('listener_increment_button');

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.provider,
    this.newProvider,
    this.onListenerCalled,
  });

  final CounterProvider provider;
  final CounterProvider? newProvider;
  final ListenerCallback<int>? onListenerCalled;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CounterProvider _currentProvider;

  @override
  void initState() {
    super.initState();
    _currentProvider = widget.provider;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: StateListener<CounterProvider, int>(
          provider: _currentProvider,
          listener: (context, state) {
            widget.onListenerCalled?.call(context, state);
          },
          child: Column(
            children: [
              ElevatedButton(
                key: listenerResetButtonKey,
                child: const SizedBox(),
                onPressed: () {
                  setState(() => _currentProvider = widget.newProvider!);
                },
              ),
              ElevatedButton(
                key: listenerNoopButtonKey,
                child: const SizedBox(),
                onPressed: () {
                  // ignore: no_self_assignments
                  setState(() => _currentProvider = _currentProvider);
                },
              ),
              ElevatedButton(
                key: listenerIncrementButtonKey,
                child: const SizedBox(),
                onPressed: () => _currentProvider.increment(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('StateListener', () {
    testWidgets('throws AssertionError when child is not specified',
        (tester) async {
      const expectedMessage =
          'StateListener<CounterProvider, int> used outside of StateListener must specify a child';

      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: CounterProvider(),
          listener: (context, state) {},
        ),
      );

      expect(
        tester.takeException(),
        isA<AssertionError>()
            .having((e) => e.message, 'message', expectedMessage),
      );
    });

    testWidgets('renders child when specified', (tester) async {
      const targetKey = Key('listener_container');
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: CounterProvider(),
          listener: (_, __) {},
          child: const SizedBox(key: targetKey),
        ),
      );
      expect(find.byKey(targetKey), findsOneWidget);
    });

    testWidgets('calls listener on initialization when flag is true',
        (tester) async {
      final provider = CounterProvider();
      final states = <int>[];

      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          shouldCallListenerOnInit: true,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      // Verification needs post frame loop processing
      await tester.pump();
      expect(states, [0]);
    });

    testWidgets('calls listener on single state change', (tester) async {
      final provider = CounterProvider();
      final states = <int>[];
      const expectedStates = [1];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      provider.increment();
      await tester.pump();
      expect(states, expectedStates);
    });

    testWidgets('calls listener on multiple state changes', (tester) async {
      final provider = CounterProvider();
      final states = <int>[];
      const expectedStates = [1, 2];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
    });

    testWidgets(
        'updates when the provider is changed at runtime to a different provider '
        'and unsubscribes from old provider', (tester) async {
      var listenerCallCount = 0;
      int? latestState;

      final providerOne = CounterProvider();
      final providerTwo = CounterProvider(10); // initial value 10

      final incrementFinder = find.byKey(listenerIncrementButtonKey);
      final resetFinder = find.byKey(listenerResetButtonKey);

      await tester.pumpWidget(
        MyApp(
          provider: providerOne,
          newProvider: providerTwo,
          onListenerCalled: (_, state) {
            listenerCallCount++;
            latestState = state;
          },
        ),
      );

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 1);
      expect(latestState, 1);

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 2);
      expect(latestState, 2);

      // Hot-swapping providers inside runtime state hierarchy
      await tester.tap(resetFinder);
      await tester.pump();

      // Incrementing new instance channel
      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 3);
      expect(latestState, 11);
    });

    testWidgets(
        'does not update when the provider is changed at runtime to same provider '
        'and stays subscribed to current provider', (tester) async {
      var listenerCallCount = 0;
      int? latestState;

      final provider = CounterProvider();
      final incrementFinder = find.byKey(listenerIncrementButtonKey);
      final noopFinder = find.byKey(listenerNoopButtonKey);

      await tester.pumpWidget(
        MyApp(
          provider: provider,
          onListenerCalled: (_, state) {
            listenerCallCount++;
            latestState = state;
          },
        ),
      );

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 1);
      expect(latestState, 1);

      // Trigger didUpdateWidget updates without modifying concrete context instances
      await tester.tap(noopFinder);
      await tester.pump();

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 2);
      expect(latestState, 2);
    });

    testWidgets(
        'calls listenWhen on single state change with correct previous '
        'and current states', (tester) async {
      int? latestPreviousState;
      var listenWhenCallCount = 0;
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = [1];

      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (previous, state) {
            listenWhenCallCount++;
            latestPreviousState = previous;
            states.add(state);
            return true;
          },
          listener: (_, __) {},
          child: const SizedBox(),
        ),
      );

      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
      expect(listenWhenCallCount, 1);
      expect(latestPreviousState, 0);
    });

    testWidgets(
        'calls listenWhen with previous listener state and current provider state and triggers listener on condition satisfaction',
        (tester) async {
      int? latestPreviousState;
      int listenWhenCallCount = 0;
      int listenerCallCount = 0;
      final states = <int>[];
      const expectedStates = [2];
      final provider = CounterProvider();

      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (previous, state) {
            listenWhenCallCount++;
            if ((previous + state) % 3 == 0) {
              latestPreviousState = previous;
              states.add(state);
              return true;
            }
            return false;
          },
          listener: (_, __) {
            listenerCallCount++;
          },
          child: const SizedBox(),
        ),
      );

      provider.increment(); // current = 1, prev = 0 -> condition false
      provider
          .increment(); // current = 2, prev = 1 -> condition (1+2)%3 == 0 -> true
      provider.increment(); // current = 3, prev = 2 -> condition false
      await tester.pump();

      expect(states, expectedStates);
      expect(listenWhenCallCount, 3);
      expect(listenerCallCount, 1);
      expect(latestPreviousState, 1);
    });

    testWidgets('calls listenWhen and listener with correct state',
        (tester) async {
      final listenWhenPreviousState = <int>[];
      final listenWhenCurrentState = <int>[];
      final states = <int>[];
      final provider = CounterProvider();
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (previous, current) {
            if (current % 3 == 0) {
              listenWhenPreviousState.add(previous);
              listenWhenCurrentState.add(current);
              return true;
            }
            return false;
          },
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );
      provider
        ..increment()
        ..increment()
        ..increment();
      await tester.pump();

      expect(states, [3]);
      expect(listenWhenPreviousState, [2]);
      expect(listenWhenCurrentState, [3]);
    });

    testWidgets(
        'calls listenWhen on multiple state change with correct previous '
        'and current states', (tester) async {
      int? latestPreviousState;
      var listenWhenCallCount = 0;
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = [1, 2];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (previous, state) {
            listenWhenCallCount++;
            latestPreviousState = previous;
            states.add(state);
            return true;
          },
          listener: (_, __) {},
          child: const SizedBox(),
        ),
      );
      await tester.pump();
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
      expect(listenWhenCallCount, 2);
      expect(latestPreviousState, 1);
    });

    testWidgets(
        'does not call listener when listenWhen returns false on single state '
        'change', (tester) async {
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = <int>[];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (_, __) => false,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
    });

    testWidgets(
        'calls listener when listenWhen returns true on single state change',
        (tester) async {
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = [1];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (_, __) => true,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
    });

    testWidgets(
        'does not call listener when listenWhen returns false '
        'on multiple state changes', (tester) async {
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = <int>[];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (_, __) => false,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
    });

    testWidgets(
        'calls listener when listenWhen returns true on multiple state change',
        (tester) async {
      final states = <int>[];
      final provider = CounterProvider();
      const expectedStates = [1, 2, 3, 4];
      await tester.pumpWidget(
        StateListener<CounterProvider, int>(
          provider: provider,
          listenWhen: (_, __) => true,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();
      provider.increment();
      await tester.pump();

      expect(states, expectedStates);
    });

    testWidgets(
        'infers the provider from the context if the provider parameter is omitted',
        (tester) async {
      final provider = CounterProvider();
      int? latestPreviousState;
      int listenWhenCallCount = 0;
      final states = <int>[];
      const expectedStates = [1];

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterProvider>.value(
          value: provider,
          child: StateListener<CounterProvider, int>(
            listenWhen: (previous, state) {
              listenWhenCallCount++;
              latestPreviousState = previous;
              return true;
            },
            listener: (_, state) => states.add(state),
            child: const SizedBox(),
          ),
        ),
      );

      provider.increment();
      await tester.pump();
      expect(states, expectedStates);
      expect(listenWhenCallCount, 1);
      expect(latestPreviousState, 0);
    });

    testWidgets(
        'Does not trigger a framework crash (markNeedsBuild error) when a side-effect listener '
        'runs inside the state builder loop and successfully executes the side-effect',
        (tester) async {
      final counterProvider = CounterProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateListener<CounterProvider, int>(
              provider: counterProvider,
              listenWhen: (previous, current) => true,
              listener: (context, state) {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => const Text('Popup Dialog'),
                );
              },
              child: const SizedBox(),
            ),
          ),
        ),
      );

      counterProvider.increment();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Popup Dialog'), findsOneWidget);
    });

    testWidgets('overrides debugFillProperties', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      StateListener(
        shouldCallListenerOnInit: true,
        provider: CounterProvider(),
        listener: (context, state) {},
        listenWhen: (previous, current) => previous != current,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any(
          (e) => e.startsWith('provider: CounterProvider'),
        ),
        isTrue,
      );

      expect(
        description,
        contains('has listener'),
      );

      expect(
        description,
        contains('has listenWhen'),
      );

      expect(
        description,
        contains(
          'shouldCallListenerOnInit: true',
        ),
      );
    });
  });
}
