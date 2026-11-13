import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/providers.dart';

// Keys used across the test environment setup
const materialAppKey = Key('material_app');
const swapButtonOneKey = Key('swap_button_1');
const swapButtonTwoKey = Key('swap_button_2');
const myCounterAppKey = Key('myCounterApp');
const myCounterAppTextConditionKey = Key('myCounterAppTextCondition');
const myCounterAppTextKey = Key('myCounterAppText');
const myCounterAppIncrementButtonKey = Key('myCounterAppIncrementButton');

class _SelectableCounterProvider extends StateNotifier<int> {
  _SelectableCounterProvider() : selected = StateField<int>(10), super(0);

  final StateField<int> selected;

  void disposeResources() {
    selected.dispose();
    dispose();
  }
}

class MyThemeApp extends StatefulWidget {
  const MyThemeApp({
    super.key,
    required this.themeProvider,
    required this.onBuild,
  });

  final StateNotifier<ThemeData> themeProvider;
  final VoidCallback onBuild;

  @override
  State<MyThemeApp> createState() => _MyThemeAppState();
}

class _MyThemeAppState extends State<MyThemeApp> {
  late StateNotifier<ThemeData> _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = widget.themeProvider;
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ThemeData>(
      listenable: _themeProvider,
      builder: (context, theme, child) {
        widget.onBuild();
        return MaterialApp(
          key: materialAppKey,
          theme: theme,
          home: Column(
            children: [
              ElevatedButton(
                key: swapButtonOneKey,
                child: const SizedBox(),
                onPressed: () {
                  setState(() => _themeProvider = DarkThemeProvider());
                },
              ),
              ElevatedButton(
                key: swapButtonTwoKey,
                child: const SizedBox(),
                onPressed: () {
                  // ignore: no_self_assignments
                  setState(() => _themeProvider = _themeProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MyCounterApp extends StatefulWidget {
  const MyCounterApp({super.key});

  @override
  State<MyCounterApp> createState() => _MyCounterAppState();
}

class _MyCounterAppState extends State<MyCounterApp> {
  final CounterProvider _provider = CounterProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: myCounterAppKey,
        body: Column(
          children: <Widget>[
            StateBuilder<int>(
              listenable: _provider,
              rebuildWhen: (previousState, state) {
                return (previousState + state) % 3 == 0;
              },
              builder: (context, count, child) {
                return Text('$count', key: myCounterAppTextConditionKey);
              },
            ),
            StateBuilder<int>(
              listenable: _provider,
              builder: (context, count, child) {
                return Text('$count', key: myCounterAppTextKey);
              },
            ),
            ElevatedButton(
              key: myCounterAppIncrementButtonKey,
              onPressed: _provider.increment,
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('StateBuilder', () {
    testWidgets('passes initial state to widget', (tester) async {
      final themeProvider = ThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(materialAppKey),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);
    });

    testWidgets('receives events and sends state updates to widget', (
      tester,
    ) async {
      final themeProvider = ThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      themeProvider.setDarkTheme();
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(materialAppKey),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets('forwards rebuildWhen to filter widget updates', (
      tester,
    ) async {
      final provider = CounterProvider();
      final states = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateBuilder<int>(
            listenable: provider,
            rebuildWhen: (_, current) => current.isEven,
            builder: (_, state, __) {
              states.add(state);
              return Text('State: $state');
            },
          ),
        ),
      );

      expect(states, [0]);
      expect(find.text('State: 0'), findsOneWidget);

      // Odd state: rebuildWhen rejects it.
      provider.increment();
      await tester.pump();

      expect(states, [0]);
      expect(find.text('State: 0'), findsOneWidget);

      // Even state: rebuildWhen accepts it.
      provider.increment();
      await tester.pump();

      expect(states, [0, 2]);
      expect(find.text('State: 2'), findsOneWidget);
    });

    testWidgets(
      'preserves child across state updates and does not rebuild it',
      (tester) async {
        var builderBuildCount = 0;
        var childBuildCount = 0;
        final counterProvider = CounterProvider();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StateBuilder<int>(
              listenable: counterProvider,
              child: StatefulBuilder(
                builder: (context, setChildState) {
                  childBuildCount++;
                  return const Text('Static Child');
                },
              ),
              builder: (context, state, child) {
                builderBuildCount++;
                return Column(children: [Text('State: $state'), child!]);
              },
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneWidget);
        expect(find.text('Static Child'), findsOneWidget);
        expect(builderBuildCount, 1);
        expect(childBuildCount, 1);

        counterProvider.increment();
        await tester.pump();

        expect(find.text('State: 1'), findsOneWidget);
        expect(find.text('Static Child'), findsOneWidget);

        expect(builderBuildCount, 2);

        expect(childBuildCount, 1);
      },
    );

    testWidgets(
      'infers the listenable from the context using StateBuilder.of',
      (tester) async {
        final themeProvider = ThemeProvider();
        var numBuilds = 0;
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: StateBuilder.of<ThemeProvider, ThemeData>(
              builder: (context, theme, child) {
                numBuilds++;
                return MaterialApp(
                  key: materialAppKey,
                  theme: theme,
                  home: const SizedBox(),
                );
              },
            ),
          ),
        );

        themeProvider.setDarkTheme();
        await tester.pump();

        var materialApp = tester.widget<MaterialApp>(
          find.byKey(materialAppKey),
        );
        expect(materialApp.theme, ThemeData.dark());
        expect(numBuilds, 2);

        themeProvider.setLightTheme();
        await tester.pump();

        materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));
        expect(materialApp.theme, ThemeData.light());
        expect(numBuilds, 3);
      },
    );

    testWidgets(
      'listens to a nested listenable using StateBuilder.of selectListenable',
      (tester) async {
        final provider = _SelectableCounterProvider();
        final states = <int>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ChangeNotifierProvider<_SelectableCounterProvider>.value(
              value: provider,
              child: StateBuilder.of<_SelectableCounterProvider, int>(
                selectListenable: (notifier) => notifier.selected,
                builder: (_, state, __) {
                  states.add(state);
                  return Text('$state');
                },
              ),
            ),
          ),
        );

        expect(states, [10]);

        provider.selected.state = 11;
        await tester.pump();

        expect(states, [10, 11]);
        expect(find.text('11'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        provider.disposeResources();
      },
    );

    test('of returns StateBuilder<T>', () {
      final StateBuilder<int> builder = StateBuilder.of<CounterProvider, int>(
        builder: (_, __, ___) => const SizedBox(),
      );

      expect(builder, isA<StateBuilder<int>>());
    });

    testWidgets('shows latest state instead of initial state', (tester) async {
      final themeProvider = ThemeProvider()..setDarkTheme();

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(materialAppKey),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);
    });

    testWidgets('overrides debugFillProperties', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      StateBuilder<int>(
        listenable: CounterProvider(),
        builder: (context, state, child) => const SizedBox(),
        rebuildWhen: (previous, current) => previous != current,
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

      expect(description, contains('has rebuildWhen'));

      expect(description.any((e) => e.startsWith('child: Text')), isTrue);
    });
    test('StateBuilder.of overrides debugFillProperties', () {
      final builder = DiagnosticPropertiesBuilder();

      StateBuilder.of<ThemeProvider, ThemeData>(
        selectListenable: (provider) => provider,
        builder: (context, state, child) => const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description, contains('has builder'));
      expect(description, contains('has selectListenable'));
    });
  });
}
