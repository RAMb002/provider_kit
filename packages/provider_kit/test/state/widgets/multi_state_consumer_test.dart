import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

void main() {
  group('StateConsumer.multi', () {
    testWidgets(
      'builds from combined state, passes child, and listens to updates',
      (tester) async {
        const childKey = Key('multi_consumer_child');
        const outputKey = Key('multi_consumer_output');

        final counter = CounterProvider(5);
        final rating = CounterProvider(10);

        final buildStates = <({int count, int rating})>[];
        final listenerStates = <({int count, int rating})>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StateConsumer.multi(
              listenables: () => (count: counter.watch, rating: rating.watch),
              builder: (_, state, child) {
                buildStates.add(state);

                return Column(
                  children: [
                    child!,
                    Text('${state.count}-${state.rating}', key: outputKey),
                  ],
                );
              },
              listener: (_, state) {
                listenerStates.add(state);
              },
              child: const SizedBox(key: childKey),
            ),
          ),
        );

        // Initial combined state.
        expect(buildStates, [(count: 5, rating: 10)]);
        expect(listenerStates, isEmpty);

        // The child parameter is forwarded and rendered.
        expect(find.byKey(childKey), findsOneWidget);
        expect(find.byKey(outputKey), findsOneWidget);
        expect(find.text('5-10'), findsOneWidget);

        counter.increment();
        await tester.pump();

        // Builder and listener receive the same updated combined state.
        expect(buildStates, [(count: 5, rating: 10), (count: 6, rating: 10)]);
        expect(listenerStates, [(count: 6, rating: 10)]);
        expect(find.text('6-10'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());

        counter.dispose();
        rating.dispose();
      },
    );

    testWidgets('passes null to builder when child is not specified', (
      tester,
    ) async {
      final provider = CounterProvider(5);

      final receivedChildren = <Widget?>[];
      final buildStates = <int>[];
      final listenerStates = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateConsumer.multi(
            listenables: () => provider.watch,
            builder: (_, state, child) {
              receivedChildren.add(child);
              buildStates.add(state);
              return Text('$state');
            },
            listener: (_, state) {
              listenerStates.add(state);
            },
          ),
        ),
      );

      expect(receivedChildren, [isNull]);
      expect(buildStates, [5]);
      expect(listenerStates, isEmpty);
      expect(find.text('5'), findsOneWidget);

      provider.increment();
      await tester.pump();

      expect(receivedChildren, [isNull, isNull]);
      expect(buildStates, [5, 6]);
      expect(listenerStates, [6]);
      expect(find.text('6'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('forwards listenWhen and rebuildWhen independently', (
      tester,
    ) async {
      final provider = CounterProvider(0);

      final buildStates = <int>[];
      final listenerStates = <int>[];

      final listenTransitions = <(int, int)>[];
      final rebuildTransitions = <(int, int)>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateConsumer.multi(
            listenables: () => provider.watch,
            listenWhen: (previous, current) {
              listenTransitions.add((previous, current));
              return current.isEven;
            },
            rebuildWhen: (previous, current) {
              rebuildTransitions.add((previous, current));
              return current.isOdd;
            },
            builder: (_, state, __) {
              buildStates.add(state);
              return Text('$state');
            },
            listener: (_, state) {
              listenerStates.add(state);
            },
          ),
        ),
      );

      expect(buildStates, [0]);
      expect(listenerStates, isEmpty);
      expect(listenTransitions, isEmpty);
      expect(rebuildTransitions, isEmpty);

      // Odd state: builder rebuilds, listener is filtered.
      provider.increment();
      await tester.pump();

      expect(buildStates, [0, 1]);
      expect(listenerStates, isEmpty);

      // Even state: listener is called, builder is filtered.
      provider.increment();
      await tester.pump();

      expect(buildStates, [0, 1]);
      expect(listenerStates, [2]);

      // Another odd state: builder rebuilds, listener is filtered.
      provider.increment();
      await tester.pump();

      expect(buildStates, [0, 1, 3]);
      expect(listenerStates, [2]);
      expect(find.text('3'), findsOneWidget);

      // Both filters receive the correct transitions.
      expect(listenTransitions, [(0, 1), (1, 2), (2, 3)]);
      expect(rebuildTransitions, [(0, 1), (1, 2), (2, 3)]);

      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });

    testWidgets('forwards callListenerOnInit to the engine', (tester) async {
      // Initial listener is disabled by default.
      final defaultProvider = CounterProvider(5);
      final defaultListenerStates = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateConsumer.multi(
            listenables: () => defaultProvider.watch,
            builder: (_, state, __) => Text('$state'),
            listener: (_, state) {
              defaultListenerStates.add(state);
            },
          ),
        ),
      );

      await tester.pump();

      expect(defaultListenerStates, isEmpty);

      // Normal notifications must still be delivered.
      defaultProvider.increment();
      await tester.pump();

      expect(defaultListenerStates, [6]);

      await tester.pumpWidget(const SizedBox());
      defaultProvider.dispose();

      // Enabling callListenerOnInit delivers the initial state.
      final initialProvider = CounterProvider(9);
      final initialListenerStates = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StateConsumer.multi(
            listenables: () => initialProvider.watch,
            callListenerOnInit: true,
            builder: (_, state, __) => Text('$state'),
            listener: (_, state) {
              initialListenerStates.add(state);
            },
          ),
        ),
      );

      await tester.pump();

      expect(initialListenerStates, [9]);

      // Normal notifications continue after the initial callback.
      initialProvider.increment();
      await tester.pump();

      expect(initialListenerStates, [9, 10]);

      await tester.pumpWidget(const SizedBox());
      initialProvider.dispose();
    });

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final provider = CounterProvider();

      final widget = StateConsumer.multi(
        listenables: () => provider.watch,
        builder: (_, __, ___) => const SizedBox(),
        listener: (_, __) {},
        listenWhen: (previous, current) => previous != current,
        rebuildWhen: (previous, current) => previous != current,
        callListenerOnInit: true,
        child: const SizedBox.shrink(),
      );

      final builder = DiagnosticPropertiesBuilder();
      widget.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('listenables')), isTrue);
      expect(description.any((value) => value.contains('builder')), isTrue);
      expect(description.any((value) => value.contains('listener')), isTrue);
      expect(description.any((value) => value.contains('listenWhen')), isTrue);
      expect(description.any((value) => value.contains('rebuildWhen')), isTrue);
      expect(description.any((value) => value.contains('child')), isTrue);
      expect(
        description.any(
          (value) =>
              value.contains('callListenerOnInit') && value.contains('true'),
        ),
        isTrue,
      );

      provider.dispose();
    });
  });
}
