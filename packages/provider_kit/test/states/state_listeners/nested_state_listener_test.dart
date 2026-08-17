import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

void main() {
  group('NestedStateListener', () {
    testWidgets('supports multiple nested listeners', (tester) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider();

      var listener1Calls = 0;
      var listener2Calls = 0;

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(
              provider: provider1,
              listener: (_, __) {
                listener1Calls++;
              },
            ),
            StateListener<int>(
              provider: provider2,
              listener: (_, __) {
                listener2Calls++;
              },
            ),
          ],
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      await tester.pump();

      expect(listener1Calls, 1);
      expect(listener2Calls, 0);

      provider2.increment();
      await tester.pump();

      expect(listener1Calls, 1);
      expect(listener2Calls, 1);
    });

    testWidgets('nests different listener types', (tester) async {
      final counterProvider = CounterProvider();
      final secondProvider = CounterProvider();

      var stateListenerCalls = 0;
      var secondListenerCalls = 0;

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(
              provider: counterProvider,
              listener: (_, __) {
                stateListenerCalls++;
              },
            ),
            MultiStateListener<int>(
              providers: [secondProvider],
              listener: (_, __) {
                secondListenerCalls++;
              },
            ),
          ],
          child: const SizedBox(),
        ),
      );

      counterProvider.increment();
      await tester.pump();

      expect(stateListenerCalls, 1);
      expect(secondListenerCalls, 0);

      secondProvider.increment();
      await tester.pump();

      expect(stateListenerCalls, 1);
      expect(secondListenerCalls, 1);
    });

    testWidgets('renders child', (tester) async {
      final provider = CounterProvider();
      const childKey = Key('child');

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(
              provider: provider,
              listener: (_, __) {},
            ),
          ],
          child: const SizedBox(key: childKey),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('removes nested listeners when removed from the tree',
        (tester) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider();

      var listener1Calls = 0;
      var listener2Calls = 0;

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(
              provider: provider1,
              listener: (_, __) {
                listener1Calls++;
              },
            ),
            StateListener<int>(
              provider: provider2,
              listener: (_, __) {
                listener2Calls++;
              },
            ),
          ],
          child: const SizedBox(),
        ),
      );

      provider1.increment();
      provider2.increment();
      await tester.pump();

      expect(listener1Calls, 1);
      expect(listener2Calls, 1);

      await tester.pumpWidget(const SizedBox());

      provider1.increment();
      provider2.increment();
      await tester.pump();

      expect(listener1Calls, 1);
      expect(listener2Calls, 1);
    });
  });
}
