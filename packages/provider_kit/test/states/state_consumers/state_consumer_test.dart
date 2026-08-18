import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

void main() {
  group('StateConsumer', () {
    testWidgets(
        'accesses the provider directly, passes initial state to builder, and nothing to listener',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
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
    });

    testWidgets(
        'accesses the provider directly and passes multiple states to builder and listener',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
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

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(listenerStates, [1]);
    });

    testWidgets(
        'accesses the provider via context and passes initial state to builder',
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
    });

    testWidgets(
        'passes multiple states to builder and listener when provider is passed directly',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
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
      counterProvider.increment();
      await tester.pump();
      expect(find.text('State: 1'), findsOneWidget);
      expect(listenerStates, [1]);
    });

    testWidgets('does not trigger rebuilds when rebuildWhen evaluates to false',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];
      final builderStates = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
              rebuildWhen: (previous, current) => (previous + current) % 3 == 0,
              builder: (context, state, child) {
                builderStates.add(state);
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
      expect(builderStates, [0]);
      expect(listenerStates, isEmpty);

      counterProvider.increment();
      await tester.pump();

      // UI text shouldn't change, builder ignored it, listener captured it
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerStates, [1]);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 2'), findsOneWidget);
      expect(builderStates, [0, 2]);
      expect(listenerStates, [1, 2]);
    });

    testWidgets(
        'does not trigger rebuilds when rebuildWhen evaluates to false (inferred provider)',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: counterProvider,
              child: StateConsumer.of<CounterProvider, int>(
                rebuildWhen: (previous, current) =>
                    (previous + current) % 3 == 0,
                builder: (context, state, child) {
                  builderStates.add(state);
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
      expect(builderStates, [0]);
      expect(listenerStates, isEmpty);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerStates, [1]);

      counterProvider.increment();
      await tester.pumpAndSettle();

      expect(find.text('State: 2'), findsOneWidget);
      expect(builderStates, [0, 2]);
      expect(listenerStates, [1, 2]);
    });

    testWidgets('updates when provider reference has changed', (tester) async {
      const buttonKey = Key('__button__');
      var counterProvider = CounterProvider();
      final listenerStates = <int>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StateConsumer<int>(
                  provider: counterProvider,
                  builder: (context, state, child) {
                    builderStates.add(state);
                    return TextButton(
                      key: buttonKey,
                      onPressed: () => setState(() {}),
                      child: Text('State: $state'),
                    );
                  },
                  listener: (_, state) {
                    listenerStates.add(state);
                  },
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerStates, isEmpty);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(builderStates, [0, 1]);
      expect(listenerStates, [1]);

      counterProvider = CounterProvider();
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0, 1, 0]);
      expect(listenerStates, [1]);
    });

    testWidgets('does not trigger listener when listenWhen evaluates to false',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];
      final builderStates = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
              builder: (context, state, child) {
                builderStates.add(state);
                return Text('State: $state');
              },
              listenWhen: (previous, current) => (previous + current) % 3 == 0,
              listener: (_, state) {
                listenerStates.add(state);
              },
            ),
          ),
        ),
      );

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerStates, isEmpty);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(builderStates, [0, 1]);
      expect(listenerStates, isEmpty);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 2'), findsOneWidget);
      expect(builderStates, [0, 1, 2]);
      expect(listenerStates, [2]);
    });

    testWidgets(
        'calls rebuildWhen/listenWhen and builder/listener with correct states',
        (tester) async {
      final buildWhenPreviousState = <int>[];
      final buildWhenCurrentState = <int>[];
      final buildStates = <int>[];
      final listenWhenPreviousState = <int>[];
      final listenWhenCurrentState = <int>[];
      final listenStates = <int>[];
      final counterProvider = CounterProvider();
      await tester.pumpWidget(
        StateConsumer<int>(
          provider: counterProvider,
          listenWhen: (previous, current) {
            if (current % 3 == 0) {
              listenWhenPreviousState.add(previous);
              listenWhenCurrentState.add(current);
              return true;
            }
            return false;
          },
          listener: (_, state) {
            listenStates.add(state);
          },
          rebuildWhen: (previous, current) {
            if (current.isEven) {
              buildWhenPreviousState.add(previous);
              buildWhenCurrentState.add(current);
              return true;
            }
            return false;
          },
          builder: (_, state, __) {
            buildStates.add(state);
            return const SizedBox();
          },
        ),
      );
      await tester.pump();
      counterProvider
        ..increment()
        ..increment()
        ..increment();
      await tester.pumpAndSettle();

      expect(buildStates, [0, 2]);
      expect(buildWhenPreviousState, [1]);
      expect(buildWhenCurrentState, [2]);

      expect(listenStates, [3]);
      expect(listenWhenPreviousState, [2]);
      expect(listenWhenCurrentState, [3]);
    });

    testWidgets(
        'triggers listener immediately on initialization when shouldCallListenerOnInit is true',
        (tester) async {
      final counterProvider = CounterProvider();
      final listenerStates = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
              shouldCallListenerOnInit: true,
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
    });

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
            provider: counterProvider,
            child: StatefulBuilder(
              builder: (context, setChildState) {
                childBuildCount++;
                return const Text('Static Performance Child');
              },
            ),
            listener: (_, __) {},
            builder: (context, state, child) {
              builderBuildCount++;
              return Column(
                children: [
                  Text('State: $state'),
                  child!,
                ],
              );
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
    });

    testWidgets(
        'Does not trigger a framework crash (markNeedsBuild error) when a side-effect listener '
        'runs inside the state builder loop and successfully executes the side-effect',
        (tester) async {
      final counterProvider = CounterProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateConsumer<int>(
              provider: counterProvider,
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
    });

    testWidgets(
      'updates when the context provider is changed',
      (tester) async {
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
      },
    );

    testWidgets(
      'keeps using the same context provider when the widget rebuilds',
      (tester) async {
        final provider = CounterProvider();
        late StateSetter rebuild;

        final states = <int>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;

                return ChangeNotifierProvider<CounterProvider>.value(
                  value: provider,
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

        provider.increment();
        await tester.pump();

        expect(find.text('1'), findsOneWidget);
        expect(states, [1]);

        rebuild(() {});
        await tester.pump();

        provider.increment();
        await tester.pump();

        expect(find.text('2'), findsOneWidget);
        expect(states, [1, 2]);
      },
    );

    testWidgets('overrides debugFillProperties with all properties populated',
        (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      StateConsumer<int>(
        provider: CounterProvider(),
        shouldCallListenerOnInit: true,
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
        description.any((e) => e.startsWith('provider: CounterProvider')),
        isTrue,
      );

      expect(description, contains('has builder'));
      expect(description, contains('has listener'));
      expect(description, contains('has rebuildWhen'));
      expect(description, contains('has listenWhen'));

      expect(description, contains('shouldCallListenerOnInit: true'));

      expect(
        description.any((e) => e.startsWith('child: Text')),
        isTrue,
      );
    });
  });
}
