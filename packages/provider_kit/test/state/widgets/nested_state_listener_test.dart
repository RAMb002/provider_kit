import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/view_state_notifiers.dart';

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
              listenable: provider1,
              listener: (_, __) {
                listener1Calls++;
              },
            ),
            StateListener<int>(
              listenable: provider2,
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
      final ofProvider = CounterProvider();

      final viewStateProvider = TestViewStateNotifier<String>(
        const InitialState(),
      );
      final viewStateOfProvider = TestViewStateNotifier<String>(
        const InitialState(),
      );
      final viewStateMultiProvider1 = TestViewStateNotifier<String>(
        const InitialState(),
      );
      final viewStateMultiProvider2 = TestViewStateNotifier<String>(
        const InitialState(),
      );

      var stateListenerCalls = 0;
      var secondListenerCalls = 0;
      var ofListenerCalls = 0;

      var viewStateListenerCalls = 0;
      var viewStateOfListenerCalls = 0;
      var viewStateMultiListenerCalls = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CounterProvider>.value(value: ofProvider),
            ChangeNotifierProvider<TestViewStateNotifier<String>>.value(
              value: viewStateOfProvider,
            ),
          ],

          builder: (context, _) {
            return NestedStateListener(
              listeners: [
                // Explicit StateListener.
                StateListener<int>(
                  listenable: counterProvider,
                  listener: (_, __) {
                    stateListenerCalls++;
                  },
                ),

                // StateListener.multi.
                StateListener.multi(
                  listenables: () => secondProvider.watch,
                  listener: (_, __) {
                    secondListenerCalls++;
                  },
                ),

                // StateListener.of.
                StateListener.of<CounterProvider, int>(
                  listener: (_, __) {
                    ofListenerCalls++;
                  },
                ),

                // Explicit ViewStateListener.
                ViewStateListener<String>(
                  listenable: viewStateProvider,
                  dataStateListener: (_, __) {
                    viewStateListenerCalls++;
                  },
                ),

                // ViewStateListener.of.
                ViewStateListener.of<TestViewStateNotifier<String>, String>(
                  dataStateListener: (_, __) {
                    viewStateOfListenerCalls++;
                  },
                ),

                // ViewStateListener.multi.
                ViewStateListener.multi(
                  listenables: () => (
                    first: viewStateMultiProvider1.watch,
                    second: viewStateMultiProvider2.watch,
                  ),
                  dataStateListener: (_, __) {
                    viewStateMultiListenerCalls++;
                  },
                ),
              ],
              child: const SizedBox(),
            );
          },
        ),
      );

      // Explicit StateListener.
      counterProvider.increment();
      await tester.pump();

      expect(stateListenerCalls, 1);
      expect(secondListenerCalls, 0);
      expect(ofListenerCalls, 0);

      // StateListener.multi.
      secondProvider.increment();
      await tester.pump();

      expect(stateListenerCalls, 1);
      expect(secondListenerCalls, 1);
      expect(ofListenerCalls, 0);

      // StateListener.of.
      ofProvider.increment();
      await tester.pump();

      expect(ofListenerCalls, 1);

      // Explicit ViewStateListener.
      viewStateProvider.emit(const DataState<String>('explicit'));
      await tester.pump();

      expect(viewStateListenerCalls, 1);

      // ViewStateListener.of.
      viewStateOfProvider.emit(const DataState<String>('of'));
      await tester.pump();

      expect(viewStateOfListenerCalls, 1);

      // ViewStateListener.multi.
      viewStateMultiProvider1.emit(const DataState<String>('first'));
      await tester.pump();

      expect(viewStateMultiListenerCalls, 0);

      viewStateMultiProvider2.emit(const DataState<String>('second'));
      await tester.pump();

      expect(viewStateMultiListenerCalls, 1);
    });

    testWidgets('renders child', (tester) async {
      final provider = CounterProvider();
      const childKey = Key('child');

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(listenable: provider, listener: (_, __) {}),
          ],
          child: const SizedBox(key: childKey),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('removes nested listeners when removed from the tree', (
      tester,
    ) async {
      final provider1 = CounterProvider();
      final provider2 = CounterProvider();

      var listener1Calls = 0;
      var listener2Calls = 0;

      await tester.pumpWidget(
        NestedStateListener(
          listeners: [
            StateListener<int>(
              listenable: provider1,
              listener: (_, __) {
                listener1Calls++;
              },
            ),
            StateListener<int>(
              listenable: provider2,
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
