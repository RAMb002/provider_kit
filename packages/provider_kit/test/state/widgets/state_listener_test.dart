import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/widgets.dart';

const listenerResetButtonKey = Key('listener_reset_button');
const listenerNoopButtonKey = Key('listener_noop_button');
const listenerIncrementButtonKey = Key('listener_increment_button');

class _SelectableOwner extends StateNotifier<int> {
  _SelectableOwner() : selected = StateField<int>(10), super(0);

  final StateField<int> selected;

  void disposeResources() {
    selected.dispose();
    dispose();
  }
}

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
        body: StateListener<int>(
          listenable: _currentProvider,
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
    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      const expectedMessage = 'StateListener<int> requires a child.';
      await tester.pumpWidget(
        StateListener<int>(
          listenable: CounterProvider(),
          listener: (context, state) {},
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
      const targetKey = Key('listener_container');
      await tester.pumpWidget(
        StateListener<int>(
          listenable: CounterProvider(),
          listener: (_, __) {},
          child: const SizedBox(key: targetKey),
        ),
      );
      expect(find.byKey(targetKey), findsOneWidget);
    });

    testWidgets('calls listener on initialization when flag is true', (
      tester,
    ) async {
      final provider = CounterProvider();
      final states = <int>[];

      await tester.pumpWidget(
        StateListener<int>(
          listenable: provider,
          callListenerOnInit: true,
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
        StateListener<int>(
          listenable: provider,
          listener: (_, state) => states.add(state),
          child: const SizedBox(),
        ),
      );

      provider.increment();
      await tester.pump();
      expect(states, expectedStates);
    });

    testWidgets(
      'updates when the listenable is changed at runtime to a different listenable '
      'and unsubscribes from old listenable',
      (tester) async {
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

        // Replace the listenable at runtime.
        await tester.tap(resetFinder);
        await tester.pump();

        // Incrementing new instance channel
        await tester.tap(incrementFinder);
        await tester.pump();
        expect(listenerCallCount, 3);
        expect(latestState, 11);
      },
    );

    testWidgets(
      'filters queued notifications with listenWhen while advancing the baseline',
      (tester) async {
        final field = StateField(0);
        final states = <int>[];
        final previousStates = <int>[];
        final currentStates = <int>[];

        await tester.pumpWidget(
          StateListener<int>(
            listenable: field,
            callListenerOnInit: true,
            listenWhen: (previous, current) {
              previousStates.add(previous);
              currentStates.add(current);

              // Only accept even values.
              return current.isEven;
            },
            listener: (_, state) {
              states.add(state);
            },
            child: StateChangeDuringInit(
              onInit: () {
                field
                  ..state = 1
                  ..state = 2
                  ..state = 3;
              },
            ),
          ),
        );

        expect(states, [0, 2]);
        expect(previousStates, [0, 1, 2]);
        expect(currentStates, [1, 2, 3]);
      },
    );

    testWidgets(
      'infers the listenable from the context using StateListener.of',
      (tester) async {
        final provider = CounterProvider();
        int? latestPreviousState;
        int listenWhenCallCount = 0;
        final states = <int>[];
        const expectedStates = [1];

        await tester.pumpWidget(
          ChangeNotifierProvider<CounterProvider>.value(
            value: provider,
            child: StateListener.of<CounterProvider, int>(
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
      },
    );

    testWidgets(
      'listens to a nested listenable using StateListener.of selectListenable',
      (tester) async {
        final owner = _SelectableOwner();
        final states = <int>[];

        await tester.pumpWidget(
          ChangeNotifierProvider<_SelectableOwner>.value(
            value: owner,
            child: StateListener.of<_SelectableOwner, int>(
              selectListenable: (notifier) => notifier.selected,
              listener: (_, state) => states.add(state),
              child: const SizedBox(),
            ),
          ),
        );

        expect(states, isEmpty);

        owner.selected.state = 11;
        await tester.pump();

        expect(states, [11]);

        await tester.pumpWidget(const SizedBox());
        owner.disposeResources();
      },
    );
    test('of returns StateListener<T>', () {
      final StateListener<int> listener =
          StateListener.of<CounterProvider, int>(
            listener: (_, __) {},
            child: const SizedBox(),
          );

      expect(listener, isA<StateListener<int>>());
      expect(listener, isA<SingleChildWidget>());
    });

    testWidgets(
      'Does not trigger a framework crash (markNeedsBuild error) when a side-effect listener '
      'runs inside the state builder loop and successfully executes the side-effect',
      (tester) async {
        final counterProvider = CounterProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateListener<int>(
                listenable: counterProvider,
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
      },
    );

    testWidgets('overrides debugFillProperties', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      StateListener(
        callListenerOnInit: true,
        listenable: CounterProvider(),
        listener: (context, state) {},
        listenWhen: (previous, current) => previous != current,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any((e) => e.startsWith('listenable: CounterProvider')),
        isTrue,
      );

      expect(description, contains('has listener'));

      expect(description, contains('has listenWhen'));

      expect(description, contains('callListenerOnInit: true'));
    });

    test('StateListener.of overrides debugFillProperties', () {
      final builder = DiagnosticPropertiesBuilder();

      StateListener.of<CounterProvider, int>(
        selectListenable: (provider) => provider,
        listener: (_, __) {},
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description, contains('has listener'));
      expect(description, contains('has selectListenable'));
    });
  });
}
