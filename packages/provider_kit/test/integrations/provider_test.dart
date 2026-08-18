import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class TestCounterNotifier extends StateNotifier<int> {
  TestCounterNotifier() : super(0);

  void increment() {
    state++;
  }
}

void main() {
  group('StateNotifier Provider compatibility', () {
    testWidgets(
      'works with Provider Consumer',
      (tester) async {
        final notifier = TestCounterNotifier();

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<TestCounterNotifier>.value(
              value: notifier,
              child: Consumer<TestCounterNotifier>(
                builder: (_, provider, __) {
                  return Text('${provider.state}');
                },
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);

        notifier.increment();
        await tester.pump();

        expect(find.text('1'), findsOneWidget);

        notifier.increment();
        await tester.pump();

        expect(find.text('2'), findsOneWidget);

        notifier.dispose();
      },
    );

    testWidgets(
      'works with Provider Selector',
      (tester) async {
        final notifier = TestCounterNotifier();
        var buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<TestCounterNotifier>.value(
              value: notifier,
              child: Selector<TestCounterNotifier, int>(
                selector: (_, provider) => provider.state,
                builder: (_, state, __) {
                  buildCount++;

                  return Text('$state');
                },
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);
        expect(buildCount, 1);

        notifier.increment();
        await tester.pump();

        expect(find.text('1'), findsOneWidget);
        expect(buildCount, 2);

        notifier.increment();
        await tester.pump();

        expect(find.text('2'), findsOneWidget);
        expect(buildCount, 3);

        notifier.dispose();
      },
    );

    testWidgets(
      'works with Provider.of',
      (tester) async {
        final notifier = TestCounterNotifier();
        int? capturedState;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<TestCounterNotifier>.value(
              value: notifier,
              child: Builder(
                builder: (context) {
                  capturedState =
                      Provider.of<TestCounterNotifier>(context).state;

                  return Text('$capturedState');
                },
              ),
            ),
          ),
        );

        expect(capturedState, 0);
        expect(find.text('0'), findsOneWidget);

        notifier.increment();
        await tester.pump();

        expect(capturedState, 1);
        expect(find.text('1'), findsOneWidget);

        notifier.dispose();
      },
    );

    testWidgets(
      'Selector rebuilds when selected StateNotifier state changes',
      (tester) async {
        final notifier = TestCounterNotifier();
        var buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<TestCounterNotifier>.value(
              value: notifier,
              child: Selector<TestCounterNotifier, int>(
                selector: (_, provider) => provider.state,
                builder: (_, state, __) {
                  buildCount++;

                  return Text('Selected: $state');
                },
              ),
            ),
          ),
        );

        expect(find.text('Selected: 0'), findsOneWidget);
        expect(buildCount, 1);

        notifier.increment();
        await tester.pump();

        expect(find.text('Selected: 1'), findsOneWidget);
        expect(buildCount, 2);

        notifier.dispose();
      },
    );
  });
}