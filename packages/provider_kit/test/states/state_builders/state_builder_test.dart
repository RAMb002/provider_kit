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
      provider: _themeProvider,
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
              provider: _provider,
              rebuildWhen: (previousState, state) {
                return (previousState + state) % 3 == 0;
              },
              builder: (context, count, child) {
                return Text(
                  '$count',
                  key: myCounterAppTextConditionKey,
                );
              },
            ),
            StateBuilder<int>(
              provider: _provider,
              builder: (context, count, child) {
                return Text(
                  '$count',
                  key: myCounterAppTextKey,
                );
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

      final materialApp =
          tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);
    });

    testWidgets('receives events and sends state updates to widget',
        (tester) async {
      final themeProvider = ThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      themeProvider.setDarkTheme();
      await tester.pump();

      final materialApp =
          tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets('preserves child across state updates and does not rebuild it',
        (tester) async {
      var builderBuildCount = 0;
      var childBuildCount = 0;
      final counterProvider = CounterProvider();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateBuilder<int>(
            provider: counterProvider,
            child: StatefulBuilder(
              builder: (context, setChildState) {
                childBuildCount++;
                return const Text('Static Child');
              },
            ),
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
      expect(find.text('Static Child'), findsOneWidget);
      expect(builderBuildCount, 1);
      expect(childBuildCount, 1);

      counterProvider.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(find.text('Static Child'), findsOneWidget);

      expect(builderBuildCount, 2);

      expect(childBuildCount, 1);
    });

    testWidgets('infers the provider from the context using StateBuilder.of',
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

      var materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));
      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeProvider.setLightTheme();
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));
      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets(
        'updates provider and performs new lookup when widget is updated',
        (tester) async {
      final themeProvider = ThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: StateBuilder.of<ThemeProvider, ThemeData>(
              builder: (context, theme, child) {
                numBuilds++;
                return MaterialApp(
                  key: materialAppKey,
                  theme: theme,
                  home: ElevatedButton(
                    child: const SizedBox(),
                    onPressed: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      final materialApp =
          tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 2);
    });

    testWidgets(
        'updates when the provider is changed at runtime to a different provider and unsubscribes from old provider',
        (tester) async {
      final themeProvider = ThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      var materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(swapButtonOneKey));
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeProvider.setLightTheme();
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets(
        'does not update when the provider is changed at runtime to same provider and stays subscribed to current provider',
        (tester) async {
      final themeProvider = DarkThemeProvider();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      var materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(swapButtonTwoKey));
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeProvider.setLightTheme();
      await tester.pump();

      materialApp = tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets(
      'updates subscription when the context provider changes',
      (tester) async {
        final firstProvider = CounterProvider();
        final secondProvider = CounterProvider(100);

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
                  child: StateBuilder.of<CounterProvider, int>(
                    builder: (_, state, __) => Text('$state'),
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

        rebuild(() {
          currentProvider = secondProvider;
        });

        await tester.pump();

        expect(find.text('100'), findsOneWidget);
        expect(find.text('1'), findsNothing);

        secondProvider.increment();
        await tester.pump();

        expect(find.text('101'), findsOneWidget);

        firstProvider.increment();
        await tester.pump();

        expect(find.text('101'), findsOneWidget);
        expect(find.text('2'), findsNothing);
      },
    );

    testWidgets(
      'keeps using the same context provider when the widget rebuilds',
      (tester) async {
        final provider = CounterProvider();
        late StateSetter rebuild;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;

                return ChangeNotifierProvider<CounterProvider>.value(
                  value: provider,
                  child: StateBuilder.of<CounterProvider, int>(
                    builder: (_, state, __) => Text('$state'),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);

        provider.increment();
        await tester.pump();

        expect(find.text('1'), findsOneWidget);

        rebuild(() {});

        await tester.pump();

        provider.increment();
        await tester.pump();

        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets('shows latest state instead of initial state', (tester) async {
      final themeProvider = ThemeProvider()..setDarkTheme();

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeProvider: themeProvider, onBuild: () => numBuilds++),
      );

      final materialApp =
          tester.widget<MaterialApp>(find.byKey(materialAppKey));

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);
    });

    testWidgets(
        'with rebuildWhen only rebuilds when rebuildWhen evaluates to true',
        (tester) async {
      await tester.pumpWidget(const MyCounterApp());

      expect(find.byKey(myCounterAppKey), findsOneWidget);

      final incrementButtonFinder = find.byKey(myCounterAppIncrementButtonKey);
      expect(incrementButtonFinder, findsOneWidget);

      var counterText = tester.widget<Text>(find.byKey(myCounterAppTextKey));
      expect(counterText.data, '0');

      var conditionalCounterText =
          tester.widget<Text>(find.byKey(myCounterAppTextConditionKey));
      expect(conditionalCounterText.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pump();

      counterText = tester.widget<Text>(find.byKey(myCounterAppTextKey));
      expect(counterText.data, '1');

      conditionalCounterText =
          tester.widget<Text>(find.byKey(myCounterAppTextConditionKey));
      expect(conditionalCounterText.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pump();

      counterText = tester.widget<Text>(find.byKey(myCounterAppTextKey));
      expect(counterText.data, '2');

      conditionalCounterText =
          tester.widget<Text>(find.byKey(myCounterAppTextConditionKey));
      expect(conditionalCounterText.data, '2');

      await tester.tap(incrementButtonFinder);
      await tester.pump();

      counterText = tester.widget<Text>(find.byKey(myCounterAppTextKey));
      expect(counterText.data, '3');

      conditionalCounterText =
          tester.widget<Text>(find.byKey(myCounterAppTextConditionKey));
      expect(conditionalCounterText.data, '2');
    });

    testWidgets('calls rebuildWhen and builder with correct state',
        (tester) async {
      final rebuildWhenPreviousState = <int>[];
      final rebuildWhenCurrentState = <int>[];
      final states = <int>[];
      final counterProvider = CounterProvider();
      await tester.pumpWidget(
        StateBuilder<int>(
          provider: counterProvider,
          rebuildWhen: (previous, state) {
            if (state.isEven) {
              rebuildWhenPreviousState.add(previous);
              rebuildWhenCurrentState.add(state);
              return true;
            }
            return false;
          },
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );

      counterProvider
        ..increment()
        ..increment()
        ..increment();
      await tester.pump();

      expect(states, [0, 2]);
      expect(rebuildWhenPreviousState, [1]);
      expect(rebuildWhenCurrentState, [2]);
    });

    testWidgets(
        'does not rebuild with latest state when rebuildWhen is false and widget is updated',
        (tester) async {
      const targetKey = Key('__target__');
      final states = <int>[];
      final counterProvider = CounterProvider();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) => StateBuilder<int>(
              provider: counterProvider,
              rebuildWhen: (previous, state) => state.isEven,
              builder: (_, state, __) {
                states.add(state);
                return ElevatedButton(
                  key: targetKey,
                  child: const SizedBox(),
                  onPressed: () => setState(() {}),
                );
              },
            ),
          ),
        ),
      );

      counterProvider
        ..increment()
        ..increment()
        ..increment();
      await tester.pump();
      expect(states, [0, 2]);

      await tester.tap(find.byKey(targetKey));
      await tester.pump();
      expect(states, [0, 2, 2]);
    });

    testWidgets('overrides debugFillProperties', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      StateBuilder<int>(
        provider: CounterProvider(),
        builder: (context, state, child) => const SizedBox(),
        rebuildWhen: (previous, current) => previous != current,
        child: const Text('Static Child'),
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
        contains('has builder'),
      );

      expect(
        description,
        contains('has rebuildWhen'),
      );

      expect(
        description.any((e) => e.startsWith('child: Text')),
        isTrue,
      );
    });
    test('StateBuilder.of overrides debugFillProperties', () {
      final builder = DiagnosticPropertiesBuilder();

      StateBuilder.of<ThemeProvider, ThemeData>(
        builder: (context, state, child) => const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description.any((e) => e.startsWith('provider: null')),
        isTrue,
      );

      expect(
        description,
        contains('has builder'),
      );
    });
  });
}
