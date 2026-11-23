import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

void main() {
  group('StateBuilder.multi', () {
    testWidgets('builds from combined state and passes child', (tester) async {
      const childKey = Key('multi_builder_child');
      const outputKey = Key('multi_builder_output');

      final provider = CounterProvider(5);
      final buildStates = <({int count, bool loading})>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateBuilder.multi(
            listenables: () => (count: provider.watch, loading: false),
            builder: (_, state, child) {
              buildStates.add(state);

              return Column(
                children: [
                  child!,
                  Text('${state.count}-${state.loading}', key: outputKey),
                ],
              );
            },
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(buildStates, [(count: 5, loading: false)]);
      expect(find.byKey(childKey), findsOneWidget);
      expect(find.byKey(outputKey), findsOneWidget);
      expect(find.text('5-false'), findsOneWidget);

      provider.increment();
      await tester.pump();

      expect(buildStates, [
        (count: 5, loading: false),
        (count: 6, loading: false),
      ]);
      expect(find.text('6-false'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('forwards rebuildWhen to the engine', (tester) async {
      final provider = CounterProvider(0);

      final buildStates = <int>[];
      final transitions = <(int, int)>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateBuilder.multi(
            listenables: () => provider.watch,
            rebuildWhen: (previous, current) {
              transitions.add((previous, current));
              return current.isEven;
            },
            builder: (_, state, __) {
              buildStates.add(state);
              return Text('$state');
            },
          ),
        ),
      );

      expect(buildStates, [0]);
      expect(transitions, isEmpty);

      // The filter rejects odd values.
      provider.increment();
      await tester.pump();

      expect(transitions, [(0, 1)]);
      expect(buildStates, [0]);

      // The filter accepts even values.
      provider.increment();
      await tester.pump();

      expect(transitions, [(0, 1), (1, 2)]);
      expect(buildStates, [0, 2]);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('passes null to builder when child is not specified', (
      tester,
    ) async {
      final provider = CounterProvider(5);
      final receivedChildren = <Widget?>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateBuilder.multi(
            listenables: () => provider.watch,
            builder: (_, state, child) {
              receivedChildren.add(child);
              return Text('$state');
            },
          ),
        ),
      );

      expect(receivedChildren, [isNull]);
      expect(find.text('5'), findsOneWidget);

      provider.increment();
      await tester.pump();

      expect(receivedChildren, [isNull, isNull]);
      expect(find.text('6'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final provider = CounterProvider();

      final widget = StateBuilder.multi(
        listenables: () => provider.watch,
        rebuildWhen: (previous, current) => previous != current,
        child: const SizedBox(),
        builder: (_, __, ___) => const SizedBox(),
      );

      final builder = DiagnosticPropertiesBuilder();
      widget.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('listenables')), isTrue);
      expect(description.any((value) => value.contains('rebuildWhen')), isTrue);
      expect(description.any((value) => value.contains('child')), isTrue);
      expect(description.any((value) => value.contains('builder')), isTrue);

      provider.dispose();
    });
  });
}
