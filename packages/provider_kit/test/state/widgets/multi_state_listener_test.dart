import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';
import 'package:provider_kit/src/state/widgets/listener/state_listener.dart';

import '../../shared/mocks/notifiers.dart';

const incrementProvider0ButtonKey = Key('multi_increment_p0');
const multiResetButtonKey = Key('multi_reset_btn');
const multiNoopButtonKey = Key('multi_noop_btn');

void main() {
  group('StateListener.multi', () {
    testWidgets('throws AssertionError when child is not specified', (
      tester,
    ) async {
      const expectedMessage = 'StateListener<int>.multi requires a child.';

      final provider = CounterProvider();

      await tester.pumpWidget(
        StateListener.multi(
          listenables: () => provider.watch,
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
        StateListener.multi(
          listenables: () => provider.watch,
          listener: (_, __) {},
          child: const SizedBox(key: targetKey),
        ),
      );

      expect(find.byKey(targetKey), findsOneWidget);
    });

    testWidgets('forwards listenWhen to filter listener notifications', (
      tester,
    ) async {
      final provider = CounterProvider(0);

      final transitions = <(int, int)>[];
      final listenerStates = <int>[];

      await tester.pumpWidget(
        StateListener.multi(
          listenables: () => provider.watch,
          listenWhen: (previous, current) {
            transitions.add((previous, current));
            return current.isEven;
          },
          listener: (_, state) => listenerStates.add(state),
          child: const SizedBox(),
        ),
      );

      // Odd state: filter rejects the listener notification.
      provider.increment();
      await tester.pump();

      expect(transitions, [(0, 1)]);
      expect(listenerStates, isEmpty);

      // Even state: filter accepts the listener notification.
      provider.increment();
      await tester.pump();

      expect(transitions, [(0, 1), (1, 2)]);
      expect(listenerStates, [2]);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('is safe to trigger dialogs inside listener', (tester) async {
      final provider = CounterProvider(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateListener.multi(
              listenables: () => [provider.watch],
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
                      child: StateListener.multi(
                        listenables: () => [
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

    testWidgets(
      'does not call initial listener unless callListenerOnInit is enabled',
      (tester) async {
        final provider = CounterProvider();
        final states = <int>[];

        await tester.pumpWidget(
          StateListener.multi(
            listenables: () => provider.watch,
            listener: (_, state) => states.add(state),
            child: const SizedBox(),
          ),
        );

        await tester.pump();

        // Initial notification is disabled by default.
        expect(states, isEmpty);

        // Normal notifications must still be delivered.
        provider.increment();
        await tester.pump();

        expect(states, [1]);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      },
    );

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final provider = CounterProvider();

      final widget = StateListener.multi(
        listenables: () => [provider.watch],
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

      expect(description.any((value) => value.contains('listenables')), isTrue);

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
