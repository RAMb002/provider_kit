import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';
import 'package:provider_kit/src/state/state_field.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';

import '../../shared/mocks/notifiers.dart';
import '../../shared/mocks/widgets.dart';

const multiConsumerResetKey = Key('multi_consumer_reset_btn');
const multiConsumerNoopKey = Key('multi_consumer_noop_btn');

/// Test host used to change the watched dependency set and rebuild the parent.
class MultiConsumerTestApp extends StatefulWidget {
  const MultiConsumerTestApp({
    super.key,
    required this.initialProviders,
    required this.newProviders,
    required this.builder,
    required this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
  });

  final List<CounterProvider> initialProviders;
  final List<CounterProvider> newProviders;
  final StateWidgetBuilder<List<int>> builder;
  final ListenerCallback<List<int>> listener;
  final ListenWhen<List<int>>? listenWhen;
  final RebuildWhen<List<int>>? rebuildWhen;
  final bool callListenerOnInit;

  @override
  State<MultiConsumerTestApp> createState() => _MultiConsumerTestAppState();
}

class _MultiConsumerTestAppState extends State<MultiConsumerTestApp> {
  late List<CounterProvider> _activeProviders;

  @override
  void initState() {
    super.initState();
    _activeProviders = widget.initialProviders;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            MultiStateConsumer<List<int>>(
              providers: () => [
                for (final provider in _activeProviders) provider.watch,
              ],
              builder: widget.builder,
              listener: widget.listener,
              listenWhen: widget.listenWhen,
              rebuildWhen: widget.rebuildWhen,
              callListenerOnInit: widget.callListenerOnInit,
              child: const SizedBox(key: Key('multi_consumer_child')),
            ),
            TextButton(
              key: multiConsumerResetKey,
              onPressed: () {
                setState(() {
                  _activeProviders = widget.newProviders;
                });
              },
              child: const Text('Swap Providers'),
            ),
            TextButton(
              key: multiConsumerNoopKey,
              onPressed: () {
                setState(() {});
              },
              child: const Text('Rebuild Parent'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('MultiStateConsumer', () {
    // =========================================================================
    // SECTION 1: CORE RENDERING & CHILD HANDLING
    // =========================================================================

    testWidgets('renders builder output and passes child', (tester) async {
      const childKey = Key('consumer_child');

      final provider1 = CounterProvider();
      final provider2 = CounterProvider(10);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateConsumer<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            builder: (_, state, child) {
              return Row(children: [child!, Text('${state[0]}-${state[1]}')]);
            },
            listener: (_, __) {},
            child: const SizedBox(key: childKey),
          ),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
      expect(find.text('0-10'), findsOneWidget);
    });

    testWidgets('supports arbitrary combined state types', (tester) async {
      final provider = CounterProvider(5);

      ({int count, bool loading})? receivedState;

      await tester.pumpWidget(
        MultiStateConsumer<({int count, bool loading})>(
          providers: () => (count: provider.watch, loading: false),
          builder: (_, state, __) {
            receivedState = state;
            return const SizedBox();
          },
          listener: (_, __) {},
        ),
      );

      expect(receivedState, (count: 5, loading: false));
    });

    testWidgets('child widget is preserved across state rebuilds', (
      tester,
    ) async {
      const childKey = Key('child_preserved');

      int childBuildCount = 0;
      int builderBuildCount = 0;

      final provider = CounterProvider();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MultiStateConsumer<int>(
            providers: () => provider.watch,
            builder: (_, state, child) {
              builderBuildCount++;

              return Column(children: [child!, Text('State: $state')]);
            },
            listener: (_, __) {},
            child: StatefulBuilder(
              key: childKey,
              builder: (_, __) {
                childBuildCount++;
                return const Text('Child');
              },
            ),
          ),
        ),
      );

      expect(builderBuildCount, 1);
      expect(childBuildCount, 1);

      provider.increment();
      await tester.pump();

      expect(builderBuildCount, 2);
      expect(childBuildCount, 1);
    });

    // =========================================================================
    // SECTION 2: INITIALIZATION
    // =========================================================================

    testWidgets('does not call listener on initialization by default', (
      tester,
    ) async {
      final listenerLog = <int>[];
      int buildCount = 0;

      final provider = CounterProvider(5);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) {
            buildCount++;
            return const SizedBox();
          },
          listener: (_, state) => listenerLog.add(state),
        ),
      );

      expect(buildCount, 1);
      expect(listenerLog, isEmpty);
    });

    testWidgets('calls listener on initialization when enabled', (
      tester,
    ) async {
      final listenerLog = <int>[];
      int buildCount = 0;

      final provider = CounterProvider(5);

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) {
            buildCount++;
            return const SizedBox();
          },
          listener: (_, state) => listenerLog.add(state),
          callListenerOnInit: true,
        ),
      );

      await tester.pump();

      expect(buildCount, 1);
      expect(listenerLog, [5]);
    });

    testWidgets(
      'calls initial listener before a normal listener notification before first frame',
      (tester) async {
        final field = StateField(0);
        final states = <int>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MultiStateConsumer<int>(
              providers: () => field.watch,
              callListenerOnInit: true,
              builder: (_, state, child) =>
                  Column(children: [Text('$state'), child!]),
              listener: (_, state) {
                states.add(state);
              },
              child: StateChangeDuringInit(
                onInit: () {
                  field.state = 1;
                },
              ),
            ),
          ),
        );

        expect(states, [0, 1]);
        await tester.pump();
        expect(find.text('1'), findsOneWidget);
      },
    );

    // =========================================================================
    // SECTION 3: BUILDER & LISTENER STATE FLOW
    // =========================================================================

    testWidgets('builder and listener use the same collected state', (
      tester,
    ) async {
      final buildLog = <int>[];
      final listenerLog = <int>[];
      int collectionCount = 0;

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () {
            collectionCount++;
            return provider.watch;
          },
          builder: (_, state, __) {
            buildLog.add(state);
            return const SizedBox();
          },
          listener: (_, state) => listenerLog.add(state),
        ),
      );

      expect(collectionCount, 1);
      expect(buildLog, [0]);
      expect(listenerLog, isEmpty);

      provider.increment();

      // One dependency notification causes one collection. The listener
      // runs immediately; the builder rebuild is scheduled for the frame.
      expect(collectionCount, 2);
      expect(listenerLog, [1]);
      expect(buildLog, [0]);

      await tester.pump();

      expect(buildLog, [0, 1]);
    });

    testWidgets(
      'listener runs for each synchronous update while builder is batched',
      (tester) async {
        final listenerLog = <List<int>>[];
        final buildLog = <List<int>>[];

        final provider1 = CounterProvider();
        final provider2 = CounterProvider(10);

        await tester.pumpWidget(
          MultiStateConsumer<List<int>>(
            providers: () => [provider1.watch, provider2.watch],
            builder: (_, state, __) {
              buildLog.add(state);
              return const SizedBox();
            },
            listener: (_, state) => listenerLog.add(state),
            listenWhen: (_, __) => true,
          ),
        );

        expect(buildLog, [
          [0, 10],
        ]);
        expect(listenerLog, isEmpty);

        provider1.increment();
        provider2.increment();

        expect(listenerLog, [
          [1, 10],
          [1, 11],
        ]);

        await tester.pump();

        expect(buildLog, [
          [0, 10],
          [1, 11],
        ]);
      },
    );

    testWidgets('updates independently across separate frames', (tester) async {
      final listenerLog = <int>[];
      final buildLog = <int>[];

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, state, __) {
            buildLog.add(state);
            return const SizedBox();
          },
          listener: (_, state) => listenerLog.add(state),
        ),
      );

      provider.increment();
      await tester.pump();

      provider.increment();
      await tester.pump();

      expect(buildLog, [0, 1, 2]);
      expect(listenerLog, [1, 2]);
    });

    // =========================================================================
    // SECTION 4: FILTERING
    // =========================================================================

    testWidgets(
      'listenWhen and rebuildWhen control listener and builder independently',
      (tester) async {
        final listenerLog = <int>[];
        final buildLog = <int>[];

        final provider = CounterProvider();

        await tester.pumpWidget(
          MultiStateConsumer<int>(
            providers: () => provider.watch,
            builder: (_, state, __) {
              buildLog.add(state);
              return const SizedBox();
            },
            listener: (_, state) => listenerLog.add(state),
            listenWhen: (_, current) => current.isEven,
            rebuildWhen: (_, current) => current.isOdd,
          ),
        );

        expect(buildLog, [0]);
        expect(listenerLog, isEmpty);

        provider.increment(); // 1: rebuild only
        await tester.pump();

        expect(buildLog, [0, 1]);
        expect(listenerLog, isEmpty);

        provider.increment(); // 2: listen only
        await tester.pump();

        expect(buildLog, [0, 1]);
        expect(listenerLog, [2]);

        provider.increment(); // 3: rebuild only
        await tester.pump();

        expect(buildLog, [0, 1, 3]);
        expect(listenerLog, [2]);
      },
    );

    testWidgets('listenWhen receives correct previous and current states', (
      tester,
    ) async {
      final previousStates = <int>[];
      final currentStates = <int>[];

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          listenWhen: (previous, current) {
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
        ),
      );

      provider.increment();
      await tester.pump();

      provider.increment();
      await tester.pump();

      expect(previousStates, [0, 1]);
      expect(currentStates, [1, 2]);
    });

    testWidgets('rebuildWhen receives correct previous and current states', (
      tester,
    ) async {
      final previousStates = <int>[];
      final currentStates = <int>[];

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          rebuildWhen: (previous, current) {
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
        ),
      );

      provider.increment();
      await tester.pump();

      provider.increment();
      await tester.pump();

      expect(previousStates, [0, 1]);
      expect(currentStates, [1, 2]);
    });

    testWidgets('does not call either filter during the initial build', (
      tester,
    ) async {
      int listenWhenCallCount = 0;
      int rebuildWhenCallCount = 0;

      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          listenWhen: (_, __) {
            listenWhenCallCount++;
            return true;
          },
          rebuildWhen: (_, __) {
            rebuildWhenCallCount++;
            return true;
          },
        ),
      );

      expect(listenWhenCallCount, 0);
      expect(rebuildWhenCallCount, 0);
    });

    // =========================================================================
    // SECTION 5: DYNAMIC DEPENDENCY TRANSITIONS
    // =========================================================================

    testWidgets('updates subscriptions when watched sources change', (
      tester,
    ) async {
      final buildLog = <List<int>>[];
      final listenerLog = <List<int>>[];

      final provider1 = CounterProvider();
      final provider2 = CounterProvider(20);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider1],
          newProviders: [provider2],
          builder: (_, state, __) {
            buildLog.add(state);
            return const SizedBox();
          },
          listener: (_, state) => listenerLog.add(state),
        ),
      );

      expect(buildLog, [
        [0],
      ]);
      expect(listenerLog, isEmpty);

      provider1.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
      ]);
      expect(listenerLog, [
        [1],
      ]);

      await tester.tap(find.byKey(multiConsumerResetKey));
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
      ]);
      expect(listenerLog, [
        [1],
      ]);

      // The removed dependency must no longer trigger either callback.
      provider1.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
      ]);
      expect(listenerLog, [
        [1],
      ]);

      // The new dependency must trigger both callbacks.
      provider2.increment();
      await tester.pump();

      expect(buildLog, [
        [0],
        [1],
        [20],
        [21],
      ]);
      expect(listenerLog, [
        [1],
        [21],
      ]);
    });

    testWidgets('new dependency state becomes the previous-state baseline', (
      tester,
    ) async {
      final previousStates = <List<int>>[];
      final currentStates = <List<int>>[];

      final provider1 = CounterProvider(10);
      final provider2 = CounterProvider(30);

      await tester.pumpWidget(
        MultiConsumerTestApp(
          initialProviders: [provider1],
          newProviders: [provider2],
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
          listenWhen: (previous, current) {
            previousStates.add(previous);
            currentStates.add(current);
            return true;
          },
        ),
      );

      await tester.tap(find.byKey(multiConsumerResetKey));
      await tester.pump();

      // Replacing dependencies establishes a new state baseline without
      // invoking listenWhen.
      expect(previousStates, isEmpty);
      expect(currentStates, isEmpty);

      provider2.increment();
      await tester.pump();

      expect(previousStates, [
        [30],
      ]);
      expect(currentStates, [
        [31],
      ]);
    });

    testWidgets(
      'rebuilds with new dependency state even when rebuildWhen is false',
      (tester) async {
        final buildLog = <List<int>>[];
        final listenerLog = <List<int>>[];

        final provider1 = CounterProvider(10);
        final provider2 = CounterProvider(30);

        await tester.pumpWidget(
          MultiConsumerTestApp(
            initialProviders: [provider1],
            newProviders: [provider2],
            builder: (_, state, __) {
              buildLog.add(state);
              return const SizedBox();
            },
            listener: (_, state) => listenerLog.add(state),
            rebuildWhen: (_, __) => false,
          ),
        );

        expect(buildLog, [
          [10],
        ]);
        expect(listenerLog, isEmpty);

        await tester.tap(find.byKey(multiConsumerResetKey));
        await tester.pump();

        // Widget configuration changes are reflected immediately; rebuildWhen
        // only filters dependency notifications.
        expect(buildLog, [
          [10],
          [30],
        ]);
        expect(listenerLog, isEmpty);

        provider2.increment();
        await tester.pump();

        expect(buildLog, [
          [10],
          [30],
        ]);
        expect(listenerLog, [
          [31],
        ]);
      },
    );

    testWidgets('does not duplicate subscriptions when parent rebuilds', (
      tester,
    ) async {
      final provider = CounterProvider();

      int collectionCount = 0;
      int listenerCallCount = 0;

      Widget buildWidget() {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  MultiStateConsumer<int>(
                    providers: () {
                      collectionCount++;
                      return provider.watch;
                    },
                    builder: (_, state, __) => Text('$state'),
                    listener: (_, __) {
                      listenerCallCount++;
                    },
                  ),
                  TextButton(
                    key: multiConsumerNoopKey,
                    onPressed: () => setState(() {}),
                    child: const Text('Rebuild Parent'),
                  ),
                ],
              );
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget());

      // Initial collection.
      expect(collectionCount, 1);
      expect(listenerCallCount, 0);

      // Parent rebuild causes didUpdateWidget -> one new collection.
      await tester.tap(find.byKey(multiConsumerNoopKey));
      await tester.pump();

      expect(collectionCount, 2);
      expect(listenerCallCount, 0);

      // One provider notification should cause exactly one collection
      // and exactly one listener invocation.
      provider.increment();
      await tester.pump();

      expect(collectionCount, 3);
      expect(listenerCallCount, 1);
    });

    // =========================================================================
    // SECTION 6: DEPENDENCY VALIDATION
    // =========================================================================

    testWidgets('asserts when no watched state source is collected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => 0,
          builder: (_, state, __) => Text('$state'),
          listener: (_, __) {},
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    // =========================================================================
    // SECTION 7: CLEANUP
    // =========================================================================

    testWidgets('detaches listeners when widget is removed from the tree', (
      tester,
    ) async {
      final provider = CounterProvider();

      await tester.pumpWidget(
        MultiStateConsumer<int>(
          providers: () => provider.watch,
          builder: (_, __, ___) => const SizedBox(),
          listener: (_, __) {},
        ),
      );

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(provider.hasListeners, isFalse);
    });

    // =========================================================================
    // SECTION 8: FLUTTER INSPECTOR DIAGNOSTICS
    // =========================================================================

    testWidgets('overrides debugFillProperties correctly', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      MultiStateConsumer<int>(
        providers: () => CounterProvider().watch,
        builder: (_, __, ___) => const SizedBox(),
        listener: (_, __) {},
        listenWhen: (previous, current) => previous != current,
        rebuildWhen: (previous, current) => previous != current,
        callListenerOnInit: true,
        child: const SizedBox(),
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('providers')), isTrue);

      expect(description.any((value) => value.contains('builder')), isTrue);

      expect(description.any((value) => value.contains('listener')), isTrue);

      expect(description.any((value) => value.contains('listenWhen')), isTrue);

      expect(description.any((value) => value.contains('rebuildWhen')), isTrue);

      expect(
        description.any(
          (value) =>
              value.contains('callListenerOnInit') && value.contains('true'),
        ),
        isTrue,
      );

      expect(description.any((value) => value.contains('child')), isTrue);
    });
  });
}
