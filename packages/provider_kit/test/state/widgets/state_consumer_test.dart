import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

void main() {
  group('StateConsumer', () {
    testWidgets(
      'accesses the listenable directly, passes initial state to builder, and nothing to listener',
      (tester) async {
        final counterProvider = CounterProvider();
        final listenerStates = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateConsumer<int>(
                listenable: counterProvider,
                builder: (context, state, child) {
                  return Text('State: $state');
                },
                listener: (_, state) {
                  listenerStates.add(state);
                },
              ),
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneWidget);
        expect(listenerStates, isEmpty);
      },
    );

    testWidgets(
      'accesses the listenable via context and passes initial state to builder',
      (tester) async {
        final counterProvider = CounterProvider();
        final listenerStates = <int>[];

        await tester.pumpWidget(
          ChangeNotifierProvider<CounterProvider>.value(
            value: counterProvider,
            child: MaterialApp(
              home: Scaffold(
                body: StateConsumer.of<CounterProvider, int>(
                  builder: (context, state, child) {
                    return Text('State: $state');
                  },
                  listener: (_, state) {
                    listenerStates.add(state);
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneWidget);
        expect(listenerStates, isEmpty);
      },
    );

    test('of returns StateConsumer<T>', () {
      final StateConsumer<int> consumer =
          StateConsumer.of<CounterProvider, int>(
            builder: (_, __, ___) => const SizedBox(),
            listener: (_, __) => {},
          );

      expect(consumer, isA<StateConsumer<int>>());
    });

    testWidgets(
      'triggers listener immediately on initialization when callListenerOnInit is true',
      (tester) async {
        final counterProvider = CounterProvider();
        final listenerStates = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateConsumer<int>(
                listenable: counterProvider,
                callListenerOnInit: true,
                builder: (context, state, child) => const SizedBox(),
                listener: (_, state) {
                  listenerStates.add(state);
                },
              ),
            ),
          ),
        );

        await tester.pump();

        expect(listenerStates, [0]);
      },
    );

    testWidgets(
      'preserves child asset architecture across iterations without triggering rebuild cycles',
      (tester) async {
        var builderBuildCount = 0;
        var childBuildCount = 0;
        final counterProvider = CounterProvider();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StateConsumer<int>(
              listenable: counterProvider,
              child: StatefulBuilder(
                builder: (context, setChildState) {
                  childBuildCount++;
                  return const Text('Static Performance Child');
                },
              ),
              listener: (_, __) {},
              builder: (context, state, child) {
                builderBuildCount++;
                return Column(children: [Text('State: $state'), child!]);
              },
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneWidget);
        expect(find.text('Static Performance Child'), findsOneWidget);
        expect(builderBuildCount, 1);
        expect(childBuildCount, 1);

        counterProvider.increment();
        await tester.pump();

        expect(find.text('State: 1'), findsOneWidget);
        expect(find.text('Static Performance Child'), findsOneWidget);
        expect(builderBuildCount, 2);

        expect(childBuildCount, 1);
      },
    );

    testWidgets('forwards listenWhen and rebuildWhen independently', (
      tester,
    ) async {
      final provider = CounterProvider();
      final builderStates = <int>[];
      final listenerStates = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateConsumer<int>(
            listenable: provider,
            listenWhen: (_, current) => current.isOdd,
            rebuildWhen: (_, current) => current.isEven,
            builder: (_, state, __) {
              builderStates.add(state);
              return Text('State: $state');
            },
            listener: (_, state) => listenerStates.add(state),
          ),
        ),
      );

      expect(builderStates, [0]);
      expect(listenerStates, isEmpty);

      // Odd state: listener accepts it, builder rejects it.
      provider.increment();
      await tester.pump();

      expect(builderStates, [0]);
      expect(listenerStates, [1]);
      expect(find.text('State: 0'), findsOneWidget);

      // Even state: builder accepts it, listener rejects it.
      provider.increment();
      await tester.pump();

      expect(builderStates, [0, 2]);
      expect(listenerStates, [1]);
      expect(find.text('State: 2'), findsOneWidget);
    });
    testWidgets(
      'selects and listens to a nested listenable using StateConsumer.of',
      (tester) async {
        final provider = _SelectableCounterProvider();
        final builderStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChangeNotifierProvider<_SelectableCounterProvider>.value(
              value: provider,
              child: StateConsumer.of<_SelectableCounterProvider, int>(
                selectListenable: (notifier) => notifier.selected,
                builder: (_, state, __) {
                  builderStates.add(state);
                  return Text('$state');
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          ),
        );

        expect(find.text('10'), findsOneWidget);
        expect(builderStates, [10]);
        expect(listenerStates, isEmpty);

        provider.selected.state = 11;
        await tester.pump();

        expect(find.text('11'), findsOneWidget);
        expect(builderStates, [10, 11]);
        expect(listenerStates, [11]);

        await tester.pumpWidget(const SizedBox());
        provider.disposeResources();
      },
    );

    testWidgets(
      'Does not trigger a framework crash (markNeedsBuild error) when a side-effect listener '
      'runs inside the state builder loop and successfully executes the side-effect',
      (tester) async {
        final counterProvider = CounterProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StateConsumer<int>(
                listenable: counterProvider,
                rebuildWhen: (previous, current) => true,
                listenWhen: (previous, current) => true,
                listener: (context, state) {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const Text('Popup Dialog'),
                  );
                },
                builder: (context, state, child) {
                  return Text('State: $state');
                },
              ),
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneWidget);

        counterProvider.increment();

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        expect(find.text('Popup Dialog'), findsOneWidget);
      },
    );

    testWidgets('updates when the context listenable is changed', (
      tester,
    ) async {
      final firstProvider = CounterProvider();
      final secondProvider = CounterProvider(100);

      final states = <int>[];
      var currentProvider = firstProvider;
      late StateSetter rebuild;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;

              return ChangeNotifierProvider<CounterProvider>.value(
                value: currentProvider,
                child: StateConsumer.of<CounterProvider, int>(
                  listener: (_, state) => states.add(state),
                  builder: (_, state, __) => Text('$state'),
                  child: const SizedBox(),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      firstProvider.increment();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(states, [1]);

      rebuild(() {
        currentProvider = secondProvider;
      });

      await tester.pump();

      expect(find.text('100'), findsOneWidget);

      secondProvider.increment();
      await tester.pump();

      expect(find.text('101'), findsOneWidget);
      expect(states, [1, 101]);

      firstProvider.increment();
      await tester.pump();

      expect(find.text('101'), findsOneWidget);
      expect(states, [1, 101]);
    });

    testWidgets('overrides debugFillProperties with all properties populated', (
      tester,
    ) async {
      final builder = DiagnosticPropertiesBuilder();

      StateConsumer<int>(
        listenable: CounterProvider(),
        callListenerOnInit: true,
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {},
        rebuildWhen: (previous, current) => previous != current,
        builder: (context, state, child) => const SizedBox(),
        child: const Text('Static Child'),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any((e) => e.startsWith('listenable: CounterProvider')),
        isTrue,
      );

      expect(description, contains('has builder'));
      expect(description, contains('has listener'));
      expect(description, contains('has rebuildWhen'));
      expect(description, contains('has listenWhen'));

      expect(description, contains('callListenerOnInit: true'));

      expect(description.any((e) => e.startsWith('child: Text')), isTrue);
    });

    test('StateConsumer.of overrides debugFillProperties', () {
      final builder = DiagnosticPropertiesBuilder();

      StateConsumer.of<CounterProvider, int>(
        selectListenable: (provider) => provider,
        builder: (_, __, ___) => const SizedBox(),
        listener: (_, __) {},
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description, contains('has builder'));
      expect(description, contains('has listener'));
      expect(description, contains('has selectListenable'));
    });
  });
}

class _SelectableCounterProvider extends StateNotifier<int> {
  _SelectableCounterProvider() : selected = StateField<int>(10), super(0);

  final StateField<int> selected;

  void disposeResources() {
    selected.dispose();
    dispose();
  }
}
