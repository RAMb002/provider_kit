// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';

import '../../../shared/mocks/notifiers.dart';
import '../../../shared/mocks/widgets.dart';

MultiStateEngine<T> _engine<T>({
  required T Function() listenables,
  Widget Function(BuildContext context, T state, Widget? child)? builder,
  void Function(BuildContext context, T state)? listener,
  bool Function(T previous, T current)? listenWhen,
  bool Function(T previous, T current)? rebuildWhen,
  bool callListenerOnInit = false,
  Widget? child,
}) {
  return MultiStateEngine<T>(
    listenables: listenables,
    builder: builder,
    listener: listener,
    listenWhen: listenWhen,
    rebuildWhen: rebuildWhen,
    callListenerOnInit: callListenerOnInit,
    widgetName: 'MultiStateEngine',
    child: child,
  );
}

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Keeps [child] unchanged when the provided notifier is replaced.
Widget _switchableMediaProvider({
  required _MediaNotifier Function() value,
  required ValueChanged<StateSetter> onStateSetter,
  required Widget child,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      onStateSetter(setState);
      return ListenableProvider<_MediaNotifier>.value(
        value: value(),
        child: child,
      );
    },
  );
}

/// Keeps [child] unchanged while exposing a replaceable ChangeNotifier.
Widget _switchableChangeNotifierMediaProvider({
  required _MediaNotifier Function() value,
  required ValueChanged<StateSetter> onStateSetter,
  required Widget child,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      onStateSetter(setState);
      return ChangeNotifierProvider<_MediaNotifier>.value(
        value: value(),
        child: child,
      );
    },
  );
}

abstract class _MediaNotifier extends StateNotifier<String> {
  _MediaNotifier(super.initialState)
    : saveMutation = Mutation<void>(),
      rating = StateField<int>(0);

  final Mutation<void> saveMutation;
  final StateField<int> rating;

  void disposeResources() {
    saveMutation.dispose();
    rating.dispose();
    dispose();
  }
}

class _MovieNotifier extends _MediaNotifier {
  _MovieNotifier() : super('Movie');
}

class _SeriesNotifier extends _MediaNotifier {
  _SeriesNotifier() : super('Series');
}

class _ProfileNotifier extends StateNotifier<int> {
  _ProfileNotifier() : profile = StateField<int>(10), super(0);

  final StateField<int> profile;

  void disposeResources() {
    profile.dispose();
    dispose();
  }
}

/// A minimal StateNotifier for ChangeNotifierProxyProvider tests.
class _ProxyNotifier extends StateNotifier<int> {
  _ProxyNotifier() : super(0);

  int sourceValue = 0;

  void updateSource(int value) {
    sourceValue = value;
  }
}

class _MediaSelection {
  const _MediaSelection(this.index);

  final int index;
}

void main() {
  group('MultiStateEngine', () {
    group('state collection', () {
      testWidgets('collects the initial value once', (tester) async {
        final field = StateField<int>(5);
        final states = <int>[];
        var collectionCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () {
                collectionCount++;
                return field.watch;
              },
              builder: (_, state, __) {
                states.add(state);
                return Text('$state');
              },
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(states, [5]);
        expect(find.text('5'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets(
        'collects once per notification and rebuilds with latest state',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final buildStates = <(int, int)>[];
          final listenerStates = <(int, int)>[];

          var collectionCount = 0;

          await tester.pumpWidget(
            _host(
              _engine<(int, int)>(
                listenables: () {
                  collectionCount++;
                  return (first.watch, second.watch);
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildStates, [(0, 10)]);
          expect(listenerStates, isEmpty);

          first.state = 1;
          second.state = 11;

          // Each notification recollects and delivers its own combined state.
          expect(collectionCount, 3);
          expect(listenerStates, [(1, 10), (1, 11)]);

          await tester.pump();

          // The builder batches both notifications into one rebuild.
          expect(buildStates, [(0, 10), (1, 11)]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );

      testWidgets('supports a list of states for collection-style usage', (
        tester,
      ) async {
        final first = StateField<int>(0);
        final second = StateField<int>(10);
        final third = StateField<int>(20);

        final buildStates = <List<int>>[];
        final listenerStates = <List<int>>[];

        await tester.pumpWidget(
          _host(
            _engine<List<int>>(
              listenables: () => [first.watch, second.watch, third.watch],
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        expect(buildStates, [
          [0, 10, 20],
        ]);
        expect(listenerStates, isEmpty);

        second.state = 11;
        await tester.pump();

        expect(listenerStates, [
          [0, 11, 20],
        ]);
        expect(buildStates, [
          [0, 10, 20],
          [0, 11, 20],
        ]);

        await tester.pumpWidget(const SizedBox());

        first.dispose();
        second.dispose();
        third.dispose();
      });

      testWidgets(
        'returns combined list in the same order as the listenables callback',
        (tester) async {
          final first = StateField<int>(5);
          final second = StateField<int>(7);

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, states) {
                  listenerStates.add(states);
                },
              ),
            ),
          );

          expect(buildStates, [
            [5, 7],
          ]);

          first.state = 6;
          await tester.pump();

          expect(listenerStates, [
            [6, 7],
          ]);

          expect(buildStates, [
            [5, 7],
            [6, 7],
          ]);

          second.state = 8;
          await tester.pump();

          expect(listenerStates, [
            [6, 7],
            [6, 8],
          ]);

          expect(buildStates, [
            [5, 7],
            [6, 7],
            [6, 8],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'delivers each listener notification while batching builder rebuilds',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, states) {
                  listenerStates.add(states);
                },
              ),
            ),
          );

          // First batch: two individual notifications.
          first.state = 1;
          second.state = 20;
          await tester.pump();

          // Second batch: another two individual notifications.
          first.state = 2;
          second.state = 30;
          await tester.pump();

          expect(listenerStates, [
            [1, 10],
            [1, 20],
            [2, 20],
            [2, 30],
          ]);

          // The builder rebuilds once per frame with the latest combined state.
          expect(buildStates, [
            [0, 10],
            [1, 20],
            [2, 30],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );

      testWidgets('supports a record as the combined state', (tester) async {
        final first = StateField<int>(5);
        final second = StateField<int>(7);

        final buildStates = <({int first, int second})>[];
        final listenerStates = <({int first, int second})>[];

        await tester.pumpWidget(
          _host(
            _engine<({int first, int second})>(
              listenables: () => (first: first.watch, second: second.watch),
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
              listener: (_, state) {
                listenerStates.add(state);
              },
            ),
          ),
        );

        expect(buildStates, [(first: 5, second: 7)]);

        first.state = 6;
        await tester.pump();

        expect(listenerStates, [(first: 6, second: 7)]);

        second.state = 8;
        await tester.pump();

        expect(listenerStates, [(first: 6, second: 7), (first: 6, second: 8)]);

        expect(buildStates, [
          (first: 5, second: 7),
          (first: 6, second: 7),
          (first: 6, second: 8),
        ]);

        await tester.pumpWidget(const SizedBox());

        first.dispose();
        second.dispose();
      });

      testWidgets('supports a custom object as the combined state', (
        tester,
      ) async {
        final first = StateField<int>(5);
        final second = StateField<int>(7);

        final buildStates = <_CombinedState>[];
        final listenerStates = <_CombinedState>[];

        await tester.pumpWidget(
          _host(
            _engine<_CombinedState>(
              listenables: () => _CombinedState(
                first: first.watch,
                second: second.watch.isEven,
              ),
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        expect(buildStates, [const _CombinedState(first: 5, second: false)]);
        expect(listenerStates, isEmpty);

        first.state = 6;
        await tester.pump();

        second.state = 8;
        await tester.pump();

        expect(listenerStates, [
          const _CombinedState(first: 6, second: false),
          const _CombinedState(first: 6, second: true),
        ]);

        expect(buildStates, [
          const _CombinedState(first: 5, second: false),
          const _CombinedState(first: 6, second: false),
          const _CombinedState(first: 6, second: true),
        ]);

        await tester.pumpWidget(const SizedBox());

        first.dispose();
        second.dispose();
      });
      testWidgets('does not subscribe to the same listenable more than once', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final listenerStates = <(int, int)>[];

        await tester.pumpWidget(
          _host(
            _engine<(int, int)>(
              listenables: () => (field.watch, field.watch),
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          ),
        );

        field.state = 1;
        await tester.pump();

        expect(listenerStates, [(1, 1)]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets('replaces dependencies selected during collection', (
        tester,
      ) async {
        final selector = StateField<bool>(false);
        final first = StateField<int>(1);
        final second = StateField<int>(10);
        final buildStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => selector.watch ? first.watch : second.watch,
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
            ),
          ),
        );

        selector.state = true;
        await tester.pump();
        expect(buildStates, [10, 1]);

        second.state = 11;
        await tester.pump();
        expect(buildStates, [10, 1]);

        first.state = 2;
        await tester.pump();
        expect(buildStates, [10, 1, 2]);

        await tester.pumpWidget(const SizedBox());
        selector.dispose();
        first.dispose();
        second.dispose();
      });

      testWidgets(
        'updates dependencies when the dependency graph changes during a state change',
        (tester) async {
          final providerA = StateField<int>(0);
          final providerB = StateField<int>(100);

          final buildStates = <int>[];
          final listenerStates = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () {
                  if (providerA.state.isEven) {
                    return providerA.watch;
                  }

                  return providerB.watch;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(buildStates, [0]);
          expect(listenerStates, isEmpty);

          // A changes from even to odd, so the dependency switches to B.
          providerA.state = 1;
          await tester.pump();

          expect(listenerStates, [100]);
          expect(buildStates, [0, 100]);

          // A is no longer watched. Its change must not trigger collection.
          providerA.state = 2;
          await tester.pump();

          expect(listenerStates, [100]);
          expect(buildStates, [0, 100]);

          // B changes. A is now even, so collection switches back to A.
          providerB.state = 101;
          await tester.pump();

          expect(listenerStates, [100, 2]);
          expect(buildStates, [0, 100, 2]);

          // A is watched again. This change switches the dependency back to B.
          providerA.state = 3;
          await tester.pump();

          expect(listenerStates, [100, 2, 101]);
          expect(buildStates, [0, 100, 2, 101]);

          await tester.pumpWidget(const SizedBox());

          providerA.dispose();
          providerB.dispose();
        },
      );
      testWidgets(
        'recollects multiple dependencies when the widget configuration changes',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);
          final third = StateField<int>(100);

          var activeFields = <StateField<int>>[first, second];

          late StateSetter updateParent;

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateParent = setState;

                  return _engine<List<int>>(
                    listenables: () => [
                      for (final field in activeFields) field.watch,
                    ],
                    builder: (_, state, __) {
                      buildStates.add(state);
                      return const SizedBox();
                    },
                    listener: (_, state) {
                      listenerStates.add(state);
                    },
                  );
                },
              ),
            ),
          );

          expect(buildStates, [
            [0, 10],
          ]);
          expect(listenerStates, isEmpty);

          // Both initial dependencies should notify independently.
          first.state = 1;
          await tester.pump();

          second.state = 11;
          await tester.pump();

          expect(listenerStates, [
            [1, 10],
            [1, 11],
          ]);

          // Replace the first dependency while retaining the second.
          updateParent(() {
            activeFields = [third, second];
          });
          await tester.pump();

          expect(buildStates.last, [100, 11]);

          // The removed dependency must have no remaining subscription.
          expect(first.hasListeners, isFalse);

          // Retained and newly added dependencies must remain subscribed.
          expect(second.hasListeners, isTrue);
          expect(third.hasListeners, isTrue);

          // Replacing dependencies should not itself notify the listener.
          expect(listenerStates, [
            [1, 10],
            [1, 11],
          ]);

          // The removed dependency must no longer trigger updates.
          first.state = 2;
          await tester.pump();

          expect(buildStates.last, [100, 11]);
          expect(listenerStates, [
            [1, 10],
            [1, 11],
          ]);

          // The newly selected dependency must trigger updates.
          third.state = 101;
          await tester.pump();

          expect(buildStates.last, [101, 11]);
          expect(listenerStates.last, [101, 11]);

          // The retained dependency must continue triggering updates.
          second.state = 12;
          await tester.pump();

          expect(buildStates.last, [101, 12]);
          expect(listenerStates.last, [101, 12]);

          await tester.pumpWidget(const SizedBox());
          expect(first.hasListeners, isFalse);
          expect(second.hasListeners, isFalse);
          expect(third.hasListeners, isFalse);
          first.dispose();
          second.dispose();
          third.dispose();
        },
      );

      testWidgets(
        'uses updated filters and child when widget configuration changes',
        (tester) async {
          final field = StateField<int>(0);

          const initialChildKey = Key('initial_child');
          const updatedChildKey = Key('updated_child');

          var useUpdatedConfiguration = false;
          late StateSetter updateParent;

          final oldListenTransitions = <(int, int)>[];
          final oldRebuildTransitions = <(int, int)>[];

          final newListenTransitions = <(int, int)>[];
          final newRebuildTransitions = <(int, int)>[];

          final buildStates = <int>[];
          final listenerStates = <int>[];

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateParent = setState;

                  final bool Function(int, int) listenWhen =
                      useUpdatedConfiguration
                      ? (previous, current) {
                          newListenTransitions.add((previous, current));
                          return true;
                        }
                      : (previous, current) {
                          oldListenTransitions.add((previous, current));
                          return false;
                        };

                  final bool Function(int, int) rebuildWhen =
                      useUpdatedConfiguration
                      ? (previous, current) {
                          newRebuildTransitions.add((previous, current));
                          return true;
                        }
                      : (previous, current) {
                          oldRebuildTransitions.add((previous, current));
                          return false;
                        };

                  return _engine<int>(
                    listenables: () => field.watch,
                    listenWhen: listenWhen,
                    rebuildWhen: rebuildWhen,
                    builder: (_, state, child) {
                      buildStates.add(state);

                      return Column(children: [child!, Text('$state')]);
                    },
                    listener: (_, state) {
                      listenerStates.add(state);
                    },
                    child: useUpdatedConfiguration
                        ? const SizedBox(key: updatedChildKey)
                        : const SizedBox(key: initialChildKey),
                  );
                },
              ),
            ),
          );

          expect(buildStates, [0]);
          expect(find.byKey(initialChildKey), findsOneWidget);

          // Both original filters reject this transition.
          field.state = 1;
          await tester.pump();

          expect(oldListenTransitions, [(0, 1)]);
          expect(oldRebuildTransitions, [(0, 1)]);
          expect(listenerStates, isEmpty);
          expect(buildStates, [0]);

          // Update the existing engine's widget configuration.
          updateParent(() {
            useUpdatedConfiguration = true;
          });
          await tester.pump();

          expect(find.byKey(initialChildKey), findsNothing);
          expect(find.byKey(updatedChildKey), findsOneWidget);

          // The parent update rebuilds with the current state.
          expect(buildStates, [0, 1]);
          expect(listenerStates, isEmpty);

          // The new filters must receive the updated baseline.
          field.state = 2;
          await tester.pump();

          expect(oldListenTransitions, [(0, 1)]);
          expect(oldRebuildTransitions, [(0, 1)]);

          expect(newListenTransitions, [(1, 2)]);
          expect(newRebuildTransitions, [(1, 2)]);

          expect(listenerStates, [2]);
          expect(buildStates, [0, 1, 2]);
          expect(find.text('2'), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets(
        'rebuilds with newly collected state when rebuildWhen rejects state changes',
        (tester) async {
          final first = StateField<int>(10);
          final second = StateField<int>(30);

          var activeFields = <StateField<int>>[first];

          late StateSetter updateParent;

          var collectionCount = 0;
          final buildStates = <List<int>>[];
          final rebuildTransitions = <(List<int>, List<int>)>[];

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateParent = setState;

                  return _engine<List<int>>(
                    listenables: () {
                      collectionCount++;
                      return [for (final field in activeFields) field.watch];
                    },
                    rebuildWhen: (previous, current) {
                      rebuildTransitions.add((previous, current));
                      return false;
                    },
                    builder: (_, state, __) {
                      buildStates.add(state);
                      return Text('$state');
                    },
                  );
                },
              ),
            ),
          );

          // Initial collection and build.
          expect(collectionCount, 1);
          expect(buildStates, [
            [10],
          ]);
          expect(rebuildTransitions, isEmpty);

          // Replace the dependency through a parent rebuild.
          // This configuration change must update the builder even though
          // rebuildWhen returns false.
          updateParent(() {
            activeFields = [second];
          });
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, [
            [10],
            [30],
          ]);
          expect(rebuildTransitions, isEmpty);

          // A normal state notification from the new dependency is filtered.
          second.state = 31;
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, [
            [10],
            [30],
          ]);

          expect(rebuildTransitions, hasLength(1));
          expect(rebuildTransitions.single.$1, [30]);
          expect(rebuildTransitions.single.$2, [31]);

          // The removed dependency must no longer trigger collection or rebuild.
          first.state = 11;
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, [
            [10],
            [30],
          ]);

          // No additional rebuildWhen call should have occurred.
          expect(rebuildTransitions, hasLength(1));
          expect(rebuildTransitions.single.$1, [30]);
          expect(rebuildTransitions.single.$2, [31]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );
      testWidgets(
        'does not rebuild or listen when a dependency leaves combined state unchanged',
        (tester) async {
          final trigger = StateField<int>(0);
          final value = StateField<int>(7);
          final buildStates = <int>[];
          final listenerStates = <int>[];
          var collectionCount = 0;

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () {
                  collectionCount++;
                  trigger.watch;
                  return value.watch;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildStates, [7]);
          expect(listenerStates, isEmpty);

          // The trigger is a dependency, but it does not affect the result.
          trigger.state = 1;
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, [7]);
          expect(listenerStates, isEmpty);

          // The actual combined value still updates normally.
          value.state = 8;
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, [7, 8]);
          expect(listenerStates, [8]);

          await tester.pumpWidget(const SizedBox());
          trigger.dispose();
          value.dispose();
        },
      );
    });

    group('builder and listener', () {
      testWidgets('applies listenWhen and rebuildWhen independently', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              listenWhen: (_, current) => current.isOdd,
              rebuildWhen: (_, current) => current.isEven,
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        field.state = 1;
        await tester.pump();
        field.state = 2;
        await tester.pump();

        expect(buildStates, [0, 2]);
        expect(listenerStates, [1]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets(
        'evaluates listenWhen and rebuildWhen independently using the latest state',
        (tester) async {
          final field = StateField<int>(0);

          final buildStates = <int>[];
          final listenerStates = <int>[];

          final listenTransitions = <(int, int)>[];
          final rebuildTransitions = <(int, int)>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                listenWhen: (previous, current) {
                  listenTransitions.add((previous, current));
                  return current.isOdd;
                },
                rebuildWhen: (previous, current) {
                  rebuildTransitions.add((previous, current));
                  return current.isEven;
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

          // listenWhen accepts 1; rebuildWhen rejects it.
          field.state = 1;
          await tester.pump();

          expect(listenTransitions, [(0, 1)]);
          expect(rebuildTransitions, [(0, 1)]);
          expect(listenerStates, [1]);
          expect(buildStates, [0]);

          // listenWhen rejects 2; rebuildWhen accepts it.
          field.state = 2;
          await tester.pump();

          expect(listenTransitions, [(0, 1), (1, 2)]);
          expect(rebuildTransitions, [(0, 1), (1, 2)]);
          expect(listenerStates, [1]);
          expect(buildStates, [0, 2]);
          expect(find.text('2'), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets(
        'calls listenWhen and rebuildWhen with previous and current combined states',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final listenTransitions = <(List<int>, List<int>)>[];
          final rebuildTransitions = <(List<int>, List<int>)>[];

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                listenWhen: (previous, current) {
                  listenTransitions.add((previous, current));
                  return true;
                },
                rebuildWhen: (previous, current) {
                  rebuildTransitions.add((previous, current));
                  return true;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) {
                  listenerStates.add(state);
                },
              ),
            ),
          );

          expect(buildStates, [
            [0, 10],
          ]);

          // First transition: [0, 10] -> [1, 10].
          first.state = 1;
          await tester.pump();

          // Second transition: [1, 10] -> [2, 10].
          first.state = 2;
          await tester.pump();

          // Verify listenWhen transitions.
          expect(listenTransitions, hasLength(2));

          expect(listenTransitions[0].$1, [0, 10]);
          expect(listenTransitions[0].$2, [1, 10]);

          expect(listenTransitions[1].$1, [1, 10]);
          expect(listenTransitions[1].$2, [2, 10]);

          // Verify rebuildWhen transitions.
          expect(rebuildTransitions, hasLength(2));

          expect(rebuildTransitions[0].$1, [0, 10]);
          expect(rebuildTransitions[0].$2, [1, 10]);

          expect(rebuildTransitions[1].$1, [1, 10]);
          expect(rebuildTransitions[1].$2, [2, 10]);

          expect(listenerStates, [
            [1, 10],
            [2, 10],
          ]);

          expect(buildStates, [
            [0, 10],
            [1, 10],
            [2, 10],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'delivers every notification and rebuilds with latest combined state when listenWhen returns true',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                listenWhen: (_, __) => true,
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(buildStates, [
            [0, 10],
          ]);

          // Both listener notifications should be delivered,
          // while the builder should rebuild with the latest combined state.
          first.state = 1;
          second.state = 20;
          await tester.pump();

          expect(listenerStates, [
            [1, 10],
            [1, 20],
          ]);

          expect(buildStates, [
            [0, 10],
            [1, 20],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );
      testWidgets(
        'filters listener notifications while rebuilding for collection-state changes',
        (tester) async {
          final provider = StateNotifier<List<String>>(['initial']);

          final buildStates = <List<String>>[];
          final listenerStates = <List<String>>[];

          await tester.pumpWidget(
            _host(
              _engine<List<String>>(
                listenables: () => provider.watch,
                listenWhen: (previous, current) {
                  return previous.first.length != current.first.length;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(buildStates, [
            ['initial'],
          ]);
          expect(listenerStates, isEmpty);

          // The contents have the same length.
          // Builder updates, but listenWhen rejects the notification.
          provider.state = ['initial'];
          await tester.pump();

          expect(listenerStates, isEmpty);
          expect(buildStates, [
            ['initial'],
            ['initial'],
          ]);

          // The contents now have a different length.
          // Both builder and listener should update.
          provider.state = ['changed_longer_string'];
          await tester.pump();

          expect(listenerStates, [
            ['changed_longer_string'],
          ]);

          expect(buildStates, [
            ['initial'],
            ['initial'],
            ['changed_longer_string'],
          ]);

          await tester.pumpWidget(const SizedBox());
          provider.dispose();
        },
      );
      testWidgets(
        'filters listener notifications while rebuilding for every combined-state change',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          var listenWhenCallCount = 0;

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                listenWhen: (_, current) {
                  listenWhenCallCount++;
                  return current[0].isEven && current[1].isEven;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(buildStates, [
            [0, 10],
          ]);

          first.state = 1;
          await tester.pump();

          expect(listenerStates, isEmpty);
          expect(listenWhenCallCount, 1);

          first.state = 2;
          await tester.pump();

          expect(listenerStates, [
            [2, 10],
          ]);
          expect(listenWhenCallCount, 2);

          second.state = 11;
          await tester.pump();

          expect(listenerStates, [
            [2, 10],
          ]);
          expect(listenWhenCallCount, 3);

          second.state = 12;
          await tester.pump();

          expect(listenerStates, [
            [2, 10],
            [2, 12],
          ]);
          expect(listenWhenCallCount, 4);

          expect(buildStates, [
            [0, 10],
            [1, 10],
            [2, 10],
            [2, 11],
            [2, 12],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );
      testWidgets('batches synchronous rebuilds but delivers each listener', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        field.state = 1;
        field.state = 2;

        expect(listenerStates, [1, 2]);
        await tester.pump();
        expect(buildStates, [0, 2]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets(
        'filters listener notifications while allowing builder rebuilds',
        (tester) async {
          final first = StateField<int>(0);
          final second = StateField<int>(10);

          final buildStates = <List<int>>[];
          final listenerStates = <List<int>>[];

          var listenWhenCallCount = 0;

          await tester.pumpWidget(
            _host(
              _engine<List<int>>(
                listenables: () => [first.watch, second.watch],
                listenWhen: (_, __) {
                  listenWhenCallCount++;
                  return false;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          expect(buildStates, [
            [0, 10],
          ]);

          // Both notifications are filtered from the listener.
          first.state = 1;
          second.state = 20;
          await tester.pump();

          expect(listenerStates, isEmpty);
          expect(listenWhenCallCount, 2);

          // Builder still receives the latest combined state.
          expect(buildStates, [
            [0, 10],
            [1, 20],
          ]);

          first.state = 2;
          second.state = 30;
          await tester.pump();

          expect(listenerStates, isEmpty);
          expect(listenWhenCallCount, 4);

          expect(buildStates, [
            [0, 10],
            [1, 20],
            [2, 30],
          ]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'calls the initial listener when callListenerOnInit is true',
        (tester) async {
          final field = StateField<int>(5);
          final listenerStates = <int>[];

          await tester.pumpWidget(
            _engine<int>(
              listenables: () => field.watch,
              callListenerOnInit: true,
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          );

          await tester.pump();
          expect(listenerStates, [5]);

          field.state = 6;
          await tester.pump();
          expect(listenerStates, [5, 6]);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets('listener-only mode preserves its child', (tester) async {
        final field = StateField<int>(0);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              listener: (_, state) => listenerStates.add(state),
              child: const Text('Listener child'),
            ),
          ),
        );

        field.state = 1;
        await tester.pump();

        expect(find.text('Listener child'), findsOneWidget);
        expect(listenerStates, [1]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
    });

    group('initial listener queueing', () {
      testWidgets('does not call the initial listener by default', (
        tester,
      ) async {
        final field = StateField<int>(5);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump();

        expect(listenerStates, isEmpty);

        // Normal state notifications must still reach the listener.
        field.state = 6;
        await tester.pump();

        expect(listenerStates, [6]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
      testWidgets(
        'delivers the initial listener before queued notifications in order',
        (tester) async {
          final field = StateField<int>(0);
          final states = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                callListenerOnInit: true,
                listener: (_, state) => states.add(state),
                child: StateChangeDuringInit(
                  onInit: () {
                    field
                      ..state = 1
                      ..state = 2
                      ..state = 3;
                  },
                ),
              ),
            ),
          );

          await tester.pump();

          expect(states, [0, 1, 2, 3]);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets('clears queued notifications when initial listener throws', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              callListenerOnInit: true,
              listener: (_, state) {
                if (state == 0) {
                  throw StateError('initial listener failed');
                }

                states.add(state);
              },
              child: StateChangeDuringInit(
                onInit: () {
                  field
                    ..state = 1
                    ..state = 2;
                },
              ),
            ),
          ),
        );

        final exception = tester.takeException();

        expect(exception, isA<StateError>());
        expect((exception as StateError).message, 'initial listener failed');

        field.state = 3;
        await tester.pump();

        // The queued notifications 1 and 2 were cleared.
        expect(states, [3]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets(
        'clears remaining queued notifications when a queued listener throws',
        (tester) async {
          final field = StateField<int>(0);
          final states = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                callListenerOnInit: true,
                listener: (_, state) {
                  if (state == 1) {
                    throw StateError('queued listener failed');
                  }

                  states.add(state);
                },
                child: StateChangeDuringInit(
                  onInit: () {
                    field
                      ..state = 1
                      ..state = 2;
                  },
                ),
              ),
            ),
          );

          final exception = tester.takeException();

          expect(exception, isA<StateError>());
          expect((exception as StateError).message, 'queued listener failed');

          field.state = 3;
          await tester.pump();

          // Initial 0 ran, 1 threw, and remaining queued 2 was cleared.
          expect(states, [0, 3]);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets('queues state changes triggered by the initial listener', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              callListenerOnInit: true,
              listener: (_, state) {
                states.add(state);

                if (state == 0) {
                  field.state = 1;
                }
              },
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump();

        expect(states, [0, 1]);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
    });

    group('listener reentrancy', () {
      testWidgets(
        'handles state changes triggered by a normal listener notification',
        (tester) async {
          final field = StateField<int>(0);

          final buildStates = <int>[];
          final listenerStates = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                builder: (_, state, __) {
                  buildStates.add(state);
                  return Text('$state');
                },
                listener: (_, state) {
                  listenerStates.add(state);

                  if (state == 1) {
                    field.state = 2;
                  }
                },
              ),
            ),
          );

          field.state = 1;
          await tester.pump();

          // Both the original and listener-triggered notifications are delivered.
          expect(listenerStates, [1, 2]);

          // The builder eventually reflects the latest state.
          expect(buildStates.last, 2);
          expect(find.text('2'), findsOneWidget);

          // The engine continues processing subsequent notifications normally.
          field.state = 3;
          await tester.pump();

          expect(listenerStates, [1, 2, 3]);
          expect(buildStates.last, 3);
          expect(find.text('3'), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );
    });
    group('filtering and state baselines', () {
      testWidgets(
        'filters queued listener notifications and advances the previous-state baseline',
        (tester) async {
          final field = StateField<int>(0);
          final states = <int>[];

          final transitions = <(int, int)>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                callListenerOnInit: true,
                listenWhen: (previous, current) {
                  transitions.add((previous, current));
                  return current.isEven;
                },
                listener: (_, state) => states.add(state),
                child: StateChangeDuringInit(
                  onInit: () {
                    field
                      ..state = 1
                      ..state = 2
                      ..state = 3;
                  },
                ),
              ),
            ),
          );

          await tester.pump();

          expect(transitions, [(0, 1), (1, 2), (2, 3)]);

          // The initial callback is always delivered.
          // Normal notifications are filtered.
          expect(states, [0, 2]);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets(
        'does not invoke filters initially and advances their baselines when events are filtered',
        (tester) async {
          final field = StateField<int>(0);

          final buildStates = <int>[];
          final listenerStates = <int>[];

          final listenTransitions = <(int, int)>[];
          final rebuildTransitions = <(int, int)>[];

          await tester.pumpWidget(
            _host(
              _engine<int>(
                listenables: () => field.watch,
                listenWhen: (previous, current) {
                  listenTransitions.add((previous, current));
                  return current == 2;
                },
                rebuildWhen: (previous, current) {
                  rebuildTransitions.add((previous, current));
                  return current == 2;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return const SizedBox();
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          );

          // Neither filter should run during the initial build.
          expect(listenTransitions, isEmpty);
          expect(rebuildTransitions, isEmpty);

          field.state = 1;
          await tester.pump();

          // Both filters reject state 1.
          expect(buildStates, [0]);
          expect(listenerStates, isEmpty);

          field.state = 2;
          await tester.pump();

          // The previous-state baseline must have advanced to 1,
          // despite the previous event being rejected.
          expect(listenTransitions, [(0, 1), (1, 2)]);
          expect(rebuildTransitions, [(0, 1), (1, 2)]);

          expect(buildStates, [0, 2]);
          expect(listenerStates, [2]);

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );
    });

    group('builder scheduling', () {
      testWidgets('defers rebuild when a watched source changes during build', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              builder: (_, state, child) {
                states.add(state);

                return Column(children: [Text('$state'), child!]);
              },
              child: StateChangeDuringInit(
                onInit: () {
                  field.state = 1;
                },
              ),
            ),
          ),
        );

        // The rebuild must be deferred until after the initial build completes.
        expect(states, [0]);

        await tester.pump();

        expect(states, [0, 1]);
        expect(find.text('1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });

      testWidgets('coalesces multiple rebuild requests during the same build', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              builder: (_, state, child) {
                states.add(state);

                return Column(children: [Text('$state'), child!]);
              },
              child: StateChangeDuringInit(
                onInit: () {
                  field
                    ..state = 1
                    ..state = 2
                    ..state = 3;
                },
              ),
            ),
          ),
        );

        expect(states, [0]);

        await tester.pump();

        // One deferred rebuild should use the latest state.
        expect(states, [0, 3]);
        expect(find.text('3'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
    });

    testWidgets(
      'passes child to builder and preserves it across state changes',
      (tester) async {
        final field = StateField<int>(0);

        var builderBuildCount = 0;
        var childBuildCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              builder: (_, state, child) {
                builderBuildCount++;

                return Column(children: [child!, Text('State: $state')]);
              },
              child: StatefulBuilder(
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
        expect(find.text('Child'), findsOneWidget);

        field.state = 1;
        await tester.pump();

        expect(builderBuildCount, 2);
        expect(childBuildCount, 1);
        expect(find.text('Child'), findsOneWidget);
        expect(find.text('State: 1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      },
    );

    testWidgets('does not duplicate subscriptions when parent rebuilds', (
      tester,
    ) async {
      final field = StateField<int>(0);

      late StateSetter rebuildParent;

      var collectionCount = 0;

      final buildStates = <int>[];
      final listenerStates = <int>[];

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (_, setState) {
              rebuildParent = setState;

              return _engine<int>(
                listenables: () {
                  collectionCount++;
                  return field.watch;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return Text('$state');
                },
                listener: (_, state) {
                  listenerStates.add(state);
                },
              );
            },
          ),
        ),
      );

      expect(collectionCount, 1);
      expect(buildStates, [0]);
      expect(listenerStates, isEmpty);

      rebuildParent(() {});
      await tester.pump();

      expect(collectionCount, 2);
      expect(listenerStates, isEmpty);

      field.state = 1;
      await tester.pump();

      // The event should be processed by exactly one subscription.
      expect(collectionCount, 3);
      expect(listenerStates, [1]);
      expect(buildStates, [0, 0, 1]);

      await tester.pumpWidget(const SizedBox());
      field.dispose();
    });

    testWidgets(
      'updates dependencies when the collection is mutated in place and resets filter baselines',
      (tester) async {
        final first = StateField<int>(1);
        final second = StateField<int>(10);

        final activeFields = <StateField<int>>[first];

        late StateSetter updateParent;

        var collectionCount = 0;

        final buildStates = <List<int>>[];
        final listenerStates = <List<int>>[];

        final listenTransitions = <(List<int>, List<int>)>[];
        final rebuildTransitions = <(List<int>, List<int>)>[];

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                updateParent = setState;

                return _engine<List<int>>(
                  listenables: () {
                    collectionCount++;
                    return [for (final field in activeFields) field.watch];
                  },
                  listenWhen: (previous, current) {
                    listenTransitions.add((previous, current));
                    return true;
                  },
                  rebuildWhen: (previous, current) {
                    rebuildTransitions.add((previous, current));
                    return true;
                  },
                  builder: (_, state, __) {
                    buildStates.add(state);
                    return const SizedBox();
                  },
                  listener: (_, state) => listenerStates.add(state),
                );
              },
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(buildStates, [
          [1],
        ]);

        // Mutate the same collection instead of replacing the list.
        updateParent(() {
          activeFields[0] = second;
        });
        await tester.pump();

        expect(collectionCount, 2);
        expect(buildStates, [
          [1],
          [10],
        ]);

        // Dependency replacement itself is not a state-change event.
        expect(listenTransitions, isEmpty);
        expect(rebuildTransitions, isEmpty);
        expect(listenerStates, isEmpty);

        // The removed dependency must no longer trigger notifications.
        first.state = 2;
        await tester.pump();

        expect(collectionCount, 2);
        expect(buildStates, [
          [1],
          [10],
        ]);

        // The new dependency must still be observed.
        second.state = 11;
        await tester.pump();

        expect(collectionCount, 3);

        // The new dependency's state is the previous-state baseline.
        expect(listenTransitions, hasLength(1));
        expect(listenTransitions.single.$1, [10]);
        expect(listenTransitions.single.$2, [11]);

        expect(rebuildTransitions, hasLength(1));
        expect(rebuildTransitions.single.$1, [10]);
        expect(rebuildTransitions.single.$2, [11]);

        expect(listenerStates, [
          [11],
        ]);
        expect(buildStates, [
          [1],
          [10],
          [11],
        ]);

        await tester.pumpWidget(const SizedBox());
        first.dispose();
        second.dispose();
      },
    );

    testWidgets(
      'does not call listener when dependencies change during widget update',
      (tester) async {
        final first = StateField<int>(10);
        final second = StateField<int>(20);
        final replacement = StateField<int>(30);

        var activeFields = <StateField<int>>[first, second];

        late StateSetter updateParent;

        final listenerStates = <List<int>>[];

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                updateParent = setState;

                return _engine<List<int>>(
                  listenables: () => [
                    for (final field in activeFields) field.watch,
                  ],
                  listenWhen: (_, __) => true,
                  listener: (_, state) => listenerStates.add(state),
                  child: const SizedBox(),
                );
              },
            ),
          ),
        );

        // A normal state change should notify the listener.
        first.state = 11;
        await tester.pump();

        expect(listenerStates, [
          [11, 20],
        ]);

        // Changing the dependencies through a parent rebuild
        // must not invoke the listener.
        updateParent(() {
          activeFields = [replacement];
        });
        await tester.pump();

        expect(listenerStates, [
          [11, 20],
        ]);

        // A subsequent notification from the replacement
        // dependency must still invoke the listener.
        replacement.state = 31;
        await tester.pump();

        expect(listenerStates, [
          [11, 20],
          [31],
        ]);

        await tester.pumpWidget(const SizedBox());

        first.dispose();
        second.dispose();
        replacement.dispose();
      },
    );

    testWidgets(
      'does not call the initial listener again when dependencies change at runtime',
      (tester) async {
        final first = StateField<int>(1);
        final second = StateField<int>(5);

        var active = first;

        late StateSetter updateParent;

        final states = <int>[];

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                updateParent = setState;

                return _engine<int>(
                  listenables: () => active.watch,
                  callListenerOnInit: true,
                  listener: (_, state) => states.add(state),
                  child: const SizedBox(),
                );
              },
            ),
          ),
        );

        await tester.pump();

        expect(states, [1]);

        updateParent(() {
          active = second;
        });
        await tester.pump();

        // Replacing dependencies must not replay the initial callback.
        expect(states, [1]);

        second.state = 6;
        await tester.pump();

        expect(states, [1, 6]);

        await tester.pumpWidget(const SizedBox());
        first.dispose();
        second.dispose();
      },
    );

    testWidgets(
      'updates builder without repeating initial listener when multiple list dependencies are replaced at runtime',
      (tester) async {
        final first = StateField<int>(1);
        final second = StateField<int>(10);
        final replacement = StateField<int>(5);

        var activeFields = <StateField<int>>[first, second];

        late StateSetter updateParent;

        final buildStates = <List<int>>[];
        final listenerStates = <List<int>>[];

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                updateParent = setState;

                return _engine<List<int>>(
                  listenables: () => [
                    for (final field in activeFields) field.watch,
                  ],
                  callListenerOnInit: true,
                  builder: (_, state, __) {
                    buildStates.add(state);
                    return const SizedBox();
                  },
                  listener: (_, state) => listenerStates.add(state),
                );
              },
            ),
          ),
        );

        await tester.pump();

        expect(buildStates, [
          [1, 10],
        ]);
        expect(listenerStates, [
          [1, 10],
        ]);

        // Replace the first dependency while retaining the second.
        updateParent(() {
          activeFields = [replacement, second];
        });
        await tester.pump();

        expect(buildStates, [
          [1, 10],
          [5, 10],
        ]);
        expect(listenerStates, [
          [1, 10],
        ]);

        // The removed dependency must no longer trigger updates.
        first.state = 2;
        await tester.pump();

        expect(buildStates, [
          [1, 10],
          [5, 10],
        ]);
        expect(listenerStates, [
          [1, 10],
        ]);

        // The replacement dependency must trigger both callbacks.
        replacement.state = 6;
        await tester.pump();

        expect(buildStates.last, [6, 10]);
        expect(listenerStates.last, [6, 10]);

        // The retained dependency must continue triggering both callbacks.
        second.state = 11;
        await tester.pump();

        expect(buildStates.last, [6, 11]);
        expect(listenerStates.last, [6, 11]);

        await tester.pumpWidget(const SizedBox());

        first.dispose();
        second.dispose();
        replacement.dispose();
      },
    );
    testWidgets('initial listener receives the collected combined state', (
      tester,
    ) async {
      final first = StateField<int>(5);
      final second = StateField<int>(9);

      final states = <List<int>>[];

      await tester.pumpWidget(
        _host(
          _engine<List<int>>(
            listenables: () => [first.watch, second.watch],
            callListenerOnInit: true,
            listener: (_, state) => states.add(state),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump();

      expect(states, [
        [5, 9],
      ]);

      await tester.pumpWidget(const SizedBox());
      first.dispose();
      second.dispose();
    });
    group('Provider integration', () {
      testWidgets(
        'resolves multiple provider types using of for builder and listener',
        (tester) async {
          final counter = CounterProvider(5);
          final rating = StateField<int>(10);

          final buildStates = <({int count, int rating})>[];
          final listenerStates = <(int, int)>[];

          await tester.pumpWidget(
            _host(
              ChangeNotifierProvider<CounterProvider>.value(
                value: counter,
                child: ChangeNotifierProvider<StateField<int>>.value(
                  value: rating,
                  child: _engine<({int count, int rating})>(
                    listenables: () => (
                      count: of<CounterProvider>().watch,
                      rating: of<StateField<int>>().watch,
                    ),
                    builder: (_, state, __) {
                      buildStates.add(state);
                      return const SizedBox();
                    },
                    listener: (_, state) {
                      listenerStates.add((state.count, state.rating));
                    },
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          );

          expect(buildStates, [(count: 5, rating: 10)]);
          expect(listenerStates, isEmpty);

          counter.increment();
          await tester.pump();

          expect(buildStates, [(count: 5, rating: 10), (count: 6, rating: 10)]);
          expect(listenerStates, [(6, 10)]);

          rating.state++;
          await tester.pump();

          expect(buildStates, [
            (count: 5, rating: 10),
            (count: 6, rating: 10),
            (count: 6, rating: 11),
          ]);
          expect(listenerStates, [(6, 10), (6, 11)]);

          await tester.pumpWidget(const SizedBox());

          counter.dispose();
          rating.dispose();
        },
      );
      testWidgets(
        'rebuilds from provider state when provider instance changes',
        (tester) async {
          final movie = _MovieNotifier();
          final series = _SeriesNotifier();
          _MediaNotifier active = movie;
          late StateSetter replaceProvider;
          final states = <String>[];
          var collectionCount = 0;

          // Reuse this exact engine widget when replacing the Provider value.
          final engine = _engine<String>(
            listenables: () {
              collectionCount++;
              return of<_MediaNotifier>().state;
            },
            builder: (_, state, __) {
              states.add(state);
              return Text(state);
            },
          );

          await tester.pumpWidget(
            _host(
              _switchableMediaProvider(
                value: () => active,
                onStateSetter: (setState) => replaceProvider = setState,
                child: engine,
              ),
            ),
          );

          expect(states, ['Movie']);
          expect(find.text('Movie'), findsOneWidget);
          expect(collectionCount, 1);

          // of().state reads the value; it does not subscribe to owner changes.
          movie.state = 'Movie updated';
          await tester.pump();
          expect(states, ['Movie']);
          expect(collectionCount, 1);

          replaceProvider(() => active = series);
          await tester.pump();
          expect(states, ['Movie', 'Series']);
          expect(find.text('Series'), findsOneWidget);
          expect(collectionCount, 2);

          await tester.pumpWidget(const SizedBox());
          movie.disposeResources();
          series.disposeResources();
        },
      );

      testWidgets('of().watch subscribes to the provided notifier state', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final states = <String>[];
        var collectionCount = 0;
        late StateSetter replaceProvider;
        _MediaNotifier active = movie;
        final series = _SeriesNotifier();

        final engine = _engine<String>(
          listenables: () {
            collectionCount++;
            return of<_MediaNotifier>().watch;
          },
          builder: (_, state, __) {
            states.add(state);
            return Text(state);
          },
        );

        await tester.pumpWidget(
          _host(
            _switchableMediaProvider(
              value: () => active,
              onStateSetter: (setState) => replaceProvider = setState,
              child: engine,
            ),
          ),
        );

        expect(collectionCount, 1);

        movie.state = 'Movie updated';
        await tester.pump();
        expect(states, ['Movie', 'Movie updated']);
        expect(collectionCount, 2);

        replaceProvider(() => active = series);
        await tester.pump();
        expect(states, ['Movie', 'Movie updated', 'Series']);
        expect(collectionCount, 3);

        movie.state = 'Old movie';
        await tester.pump();
        expect(collectionCount, 3);

        series.state = 'Series updated';
        await tester.pump();
        expect(states, ['Movie', 'Movie updated', 'Series', 'Series updated']);
        expect(collectionCount, 4);

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
        series.disposeResources();
      });

      testWidgets('rebinds nested Mutation subscriptions when provider swaps', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final series = _SeriesNotifier();
        _MediaNotifier active = movie;

        late StateSetter replaceProvider;

        final states = <MutationState<void>>[];
        var collectionCount = 0;

        // Keep the same engine widget throughout provider replacements.
        final engine = _engine<MutationState<void>>(
          listenables: () {
            collectionCount++;
            return of<_MediaNotifier>().saveMutation.watch;
          },
          builder: (_, state, __) {
            states.add(state);
            return const SizedBox();
          },
        );

        await tester.pumpWidget(
          _host(
            _switchableMediaProvider(
              value: () => active,
              onStateSetter: (setState) => replaceProvider = setState,
              child: engine,
            ),
          ),
        );

        expect(states, hasLength(1));
        expect(states.last, isA<MutationIdle<void>>());
        expect(collectionCount, 1);

        // Start Movie's mutation.
        final movieCompleter = Completer<void>();
        final movieOperation = movie.saveMutation.run(
          () => movieCompleter.future,
        );

        await tester.pump();

        expect(states.last, isA<MutationLoading<void>>());
        expect(collectionCount, 2);

        // Switch to Series while Movie's mutation is still running.
        replaceProvider(() => active = series);
        await tester.pump();

        expect(states.last, isA<MutationIdle<void>>());
        expect(collectionCount, 3);

        // Start Series' mutation too.
        final seriesCompleter = Completer<void>();
        final seriesOperation = series.saveMutation.run(
          () => seriesCompleter.future,
        );

        await tester.pump();

        expect(states.last, isA<MutationLoading<void>>());
        expect(collectionCount, 4);

        // Switch back to Movie. Its original mutation must still be Loading.
        replaceProvider(() => active = movie);
        await tester.pump();

        expect(states.last, isA<MutationLoading<void>>());
        expect(collectionCount, 5);

        // Complete Series' mutation while Movie is active.
        // The engine must no longer be subscribed to Series.
        final statesBeforeSeriesCompletion = states.length;

        seriesCompleter.complete();
        await seriesOperation;
        await tester.pump();

        expect(states, hasLength(statesBeforeSeriesCompletion));
        expect(collectionCount, 5);

        // Complete Movie's mutation while Movie is active.
        // The engine must still be subscribed to Movie.
        movieCompleter.complete();
        await movieOperation;
        await tester.pump();

        expect(states.last, isA<MutationSuccess<void>>());
        expect(collectionCount, 6);

        await tester.pumpWidget(const SizedBox());

        movie.disposeResources();
        series.disposeResources();
      });
      testWidgets(
        'rebinds nested StateField subscriptions when provider swaps',
        (tester) async {
          final movie = _MovieNotifier();
          final series = _SeriesNotifier();
          _MediaNotifier active = movie;
          late StateSetter replaceProvider;
          final ratings = <int>[];
          var collectionCount = 0;

          final engine = _engine<int>(
            listenables: () {
              collectionCount++;
              return of<_MediaNotifier>().rating.watch;
            },
            builder: (_, state, __) {
              ratings.add(state);
              return Text('$state');
            },
          );

          await tester.pumpWidget(
            _host(
              _switchableMediaProvider(
                value: () => active,
                onStateSetter: (setState) => replaceProvider = setState,
                child: engine,
              ),
            ),
          );

          movie.rating.state = 1;
          await tester.pump();
          expect(ratings, [0, 1]);
          expect(collectionCount, 2);

          replaceProvider(() => active = series);
          await tester.pump();
          expect(ratings, [0, 1, 0]);
          expect(collectionCount, 3);

          movie.rating.state = 2;
          await tester.pump();
          expect(ratings, [0, 1, 0]);
          expect(collectionCount, 3);

          series.rating.state = 3;
          await tester.pump();
          expect(ratings, [0, 1, 0, 3]);
          expect(collectionCount, 4);

          await tester.pumpWidget(const SizedBox());
          movie.disposeResources();
          series.disposeResources();
        },
      );

      testWidgets('works with ChangeNotifierProvider.value', (tester) async {
        final movie = _MovieNotifier();
        final series = _SeriesNotifier();
        _MediaNotifier active = movie;
        late StateSetter replaceProvider;
        final states = <String>[];
        var collectionCount = 0;

        final engine = _engine<String>(
          listenables: () {
            collectionCount++;
            return of<_MediaNotifier>().watch;
          },
          builder: (_, state, __) {
            states.add(state);
            return Text(state);
          },
        );

        await tester.pumpWidget(
          _host(
            _switchableChangeNotifierMediaProvider(
              value: () => active,
              onStateSetter: (setState) => replaceProvider = setState,
              child: engine,
            ),
          ),
        );

        expect(states, ['Movie']);
        expect(collectionCount, 1);

        movie.state = 'Movie updated';
        await tester.pump();
        expect(states, ['Movie', 'Movie updated']);
        expect(collectionCount, 2);

        replaceProvider(() => active = series);
        await tester.pump();
        expect(states, ['Movie', 'Movie updated', 'Series']);
        expect(collectionCount, 3);

        series.state = 'Series updated';
        await tester.pump();
        expect(states, ['Movie', 'Movie updated', 'Series', 'Series updated']);
        expect(collectionCount, 4);

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
        series.disposeResources();
      });

      testWidgets(
        'rebinds provider dependency when provider instance changes',
        (tester) async {
          final first = CounterProvider(1);
          final second = CounterProvider(5);

          var activeProvider = first;

          final buildStates = <int>[];
          final listenerStates = <int>[];

          const swapKey = Key('swap_provider');

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  return ChangeNotifierProvider<CounterProvider>.value(
                    value: activeProvider,
                    child: _engine<int>(
                      listenables: () => of<CounterProvider>().watch,
                      builder: (_, state, child) {
                        buildStates.add(state);

                        // Preserve the GestureDetector passed as the child.
                        return child ?? const SizedBox();
                      },
                      listener: (_, state) => listenerStates.add(state),
                      child: GestureDetector(
                        key: swapKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            activeProvider = second;
                          });
                        },
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          expect(buildStates, [1]);
          expect(listenerStates, isEmpty);

          first.increment();
          await tester.pump();

          expect(buildStates, [1, 2]);
          expect(listenerStates, [2]);

          await tester.tap(find.byKey(swapKey));
          await tester.pump();

          // Provider replacement updates the builder, not the listener.
          expect(buildStates, [1, 2, 5]);
          expect(listenerStates, [2]);

          first.increment();
          await tester.pump();

          // The old provider must no longer trigger either callback.
          expect(buildStates, [1, 2, 5]);
          expect(listenerStates, [2]);

          second.increment();
          await tester.pump();

          expect(buildStates, [1, 2, 5, 6]);
          expect(listenerStates, [2, 6]);

          await tester.pumpWidget(const SizedBox());

          first.dispose();
          second.dispose();
        },
      );
      testWidgets(
        'tracks multiple provider types independently when one is replaced',
        (tester) async {
          final movie = _MovieNotifier();
          final series = _SeriesNotifier();
          final profile = _ProfileNotifier();
          _MediaNotifier active = movie;
          late StateSetter replaceMedia;

          final states = <({int rating, int profile})>[];
          var collectionCount = 0;

          final engine = _engine<({int rating, int profile})>(
            listenables: () {
              collectionCount++;
              final media = of<_MediaNotifier>();
              final user = of<_ProfileNotifier>();

              return (rating: media.rating.watch, profile: user.profile.watch);
            },
            builder: (_, state, __) {
              states.add(state);
              return const SizedBox();
            },
          );

          await tester.pumpWidget(
            _host(
              _switchableMediaProvider(
                value: () => active,
                onStateSetter: (setState) => replaceMedia = setState,
                child: ChangeNotifierProvider<_ProfileNotifier>.value(
                  value: profile,
                  child: engine,
                ),
              ),
            ),
          );

          expect(states, [(rating: 0, profile: 10)]);
          expect(collectionCount, 1);

          movie.rating.state = 1;
          await tester.pump();
          expect(states.last, (rating: 1, profile: 10));

          profile.profile.state = 11;
          await tester.pump();
          expect(states.last, (rating: 1, profile: 11));

          // Replacing the media provider must retain the profile dependency.
          replaceMedia(() => active = series);
          await tester.pump();
          expect(states.last, (rating: 0, profile: 11));

          final countAfterReplacement = collectionCount;

          // The old media notifier is no longer observed.
          movie.rating.state = 2;
          await tester.pump();
          expect(collectionCount, countAfterReplacement);

          // The unchanged ProfileNotifier remains observed.
          profile.profile.state = 12;
          await tester.pump();
          expect(states.last, (rating: 0, profile: 12));

          // The replacement media notifier is observed as well.
          series.rating.state = 3;
          await tester.pump();
          expect(states.last, (rating: 3, profile: 12));

          expect(collectionCount, countAfterReplacement + 2);

          await tester.pumpWidget(const SizedBox());
          movie.disposeResources();
          series.disposeResources();
          profile.disposeResources();
        },
      );

      testWidgets(
        'works with ChangeNotifierProxyProvider and reuses its notifier',
        (tester) async {
          var sourceValue = 1;
          late StateSetter updateSource;
          late _ProxyNotifier notifier;
          var proxyUpdateCount = 0;
          var collectionCount = 0;
          final states = <int>[];

          final engine = _engine<int>(
            listenables: () {
              collectionCount++;
              return of<_ProxyNotifier>().watch;
            },
            builder: (_, state, __) {
              states.add(state);
              return const SizedBox();
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateSource = setState;
                  return Provider<int>.value(
                    value: sourceValue,
                    child: ChangeNotifierProxyProvider<int, _ProxyNotifier>(
                      create: (_) => notifier = _ProxyNotifier(),
                      update: (_, value, previous) {
                        proxyUpdateCount++;
                        final current = previous!;
                        current.updateSource(value);
                        return current;
                      },
                      child: engine,
                    ),
                  );
                },
              ),
            ),
          );

          expect(notifier.sourceValue, 1);
          expect(states, [0]);
          expect(collectionCount, 1);

          final initialProxyUpdateCount = proxyUpdateCount;

          // The proxy dependency changes, but the same notifier is reused.
          updateSource(() => sourceValue = 2);
          await tester.pump();

          expect(proxyUpdateCount, greaterThan(initialProxyUpdateCount));
          expect(notifier.sourceValue, 2);
          expect(collectionCount, 1);
          expect(states, [0]);

          // The engine remains subscribed to the reused notifier.
          notifier.state = 1;
          await tester.pump();

          expect(states, [0, 1]);
          expect(collectionCount, 2);

          // ChangeNotifierProxyProvider owns and disposes this notifier.
          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'supports ProxyProvider values feeding ListenableProxyProvider notifiers',
        (tester) async {
          final movie = _MovieNotifier();
          final series = _SeriesNotifier();
          var selection = 0;
          late StateSetter updateSelection;
          final ratings = <int>[];
          var collectionCount = 0;

          final engine = _engine<int>(
            listenables: () {
              collectionCount++;
              return of<_MediaNotifier>().rating.watch;
            },
            builder: (_, state, __) {
              ratings.add(state);
              return const SizedBox();
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateSelection = setState;
                  return Provider<int>.value(
                    value: selection,
                    child: ProxyProvider<int, _MediaSelection>(
                      update: (_, index, __) => _MediaSelection(index),
                      child:
                          ListenableProxyProvider<
                            _MediaSelection,
                            _MediaNotifier
                          >(
                            update: (_, selected, __) =>
                                selected.index == 0 ? movie : series,
                            // These notifiers are externally owned by this test.
                            dispose: (_, __) {},
                            child: engine,
                          ),
                    ),
                  );
                },
              ),
            ),
          );

          expect(ratings, [0]);
          expect(collectionCount, 1);

          movie.rating.state = 1;
          await tester.pump();
          expect(ratings, [0, 1]);

          // ProxyProvider derives a new selection; ListenableProxyProvider
          // then exposes the corresponding StateNotifier.
          updateSelection(() => selection = 1);
          await tester.pump();

          expect(ratings, [0, 1, 0]);
          expect(collectionCount, 3);

          final countAfterReplacement = collectionCount;

          movie.rating.state = 2;
          await tester.pump();
          expect(collectionCount, countAfterReplacement);

          series.rating.state = 3;
          await tester.pump();
          expect(ratings, [0, 1, 0, 3]);
          expect(collectionCount, countAfterReplacement + 1);

          await tester.pumpWidget(const SizedBox());
          movie.disposeResources();
          series.disposeResources();
        },
      );

      testWidgets(
        'provider replacement rebuilds but does not dispatch the listener',
        (tester) async {
          final movie = _MovieNotifier();
          final series = _SeriesNotifier()..state = 'Movie';
          _MediaNotifier active = movie;
          late StateSetter replaceProvider;
          final buildStates = <String>[];
          final listenerStates = <String>[];
          var collectionCount = 0;

          final engine = _engine<String>(
            listenables: () {
              collectionCount++;
              return of<_MediaNotifier>().watch;
            },
            builder: (_, state, __) {
              buildStates.add(state);
              return Text(state);
            },
            listener: (_, state) => listenerStates.add(state),
          );

          await tester.pumpWidget(
            _host(
              _switchableMediaProvider(
                value: () => active,
                onStateSetter: (setState) => replaceProvider = setState,
                child: engine,
              ),
            ),
          );

          expect(buildStates, ['Movie']);
          expect(listenerStates, isEmpty);
          expect(collectionCount, 1);

          // A different provider instance with the same state still rebuilds
          // the engine, but replacement itself is not a listener event.
          replaceProvider(() => active = series);
          await tester.pump();

          expect(buildStates, ['Movie', 'Movie']);
          expect(listenerStates, isEmpty);
          expect(collectionCount, 2);

          // A later state notification from the replacement is a real event.
          series.state = 'Series updated';
          await tester.pump();

          expect(buildStates, ['Movie', 'Movie', 'Series updated']);
          expect(listenerStates, ['Series updated']);
          expect(collectionCount, 3);

          await tester.pumpWidget(const SizedBox());
          movie.disposeResources();
          series.disposeResources();
        },
      );

      testWidgets(
        'throws ProviderNotFoundException when of provider is missing',
        (tester) async {
          await tester.pumpWidget(
            _host(
              _engine<String>(
                listenables: () => of<_MediaNotifier>().watch,
                builder: (_, state, __) => Text(state),
              ),
            ),
          );

          expect(tester.takeException(), isA<ProviderNotFoundException>());

          expect(() => of<_MediaNotifier>(), throwsA(isA<StateError>()));
        },
      );
    });

    group('lifecycle and validation', () {
      testWidgets('removes subscriptions when the engine is disposed', (
        tester,
      ) async {
        final field = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => field.watch,
              builder: (_, state, __) {
                states.add(state);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(states, [0]);

        // The engine must have subscribed to the field.
        expect(field.hasListeners, isTrue);

        await tester.pumpWidget(const SizedBox());

        // The engine must remove its actual subscription on disposal.
        expect(field.hasListeners, isFalse);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
      test('of throws outside a dependency collection', () {
        expect(() => of<_MediaNotifier>(), throwsA(isA<StateError>()));
      });

      testWidgets('asserts when no watched state source is collected', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () => 0,
              builder: (_, state, __) => Text('$state'),
            ),
          ),
        );

        expect(tester.takeException(), isA<AssertionError>());
      });

      test(
        'watch throws an assertion when used outside a dependency collection',
        () {
          final field = StateField<int>(0);

          expect(() => field.watch, throwsA(isA<AssertionError>()));

          field.dispose();
        },
      );

      testWidgets('cleans the collection scope when listenables throws', (
        tester,
      ) async {
        final field = StateField<int>(0);

        await tester.pumpWidget(
          _engine<int>(
            listenables: () {
              field.watch;
              throw StateError('Collection failed');
            },
            builder: (_, state, __) => Text('$state'),
          ),
        );

        expect(tester.takeException(), isA<StateError>());
        expect(() => of<_MediaNotifier>(), throwsA(isA<StateError>()));

        // Failed collection must not leave a subscription behind.
        expect(field.hasListeners, isFalse);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
    });
  });
}

class _CombinedState {
  const _CombinedState({required this.first, required this.second});

  final int first;
  final bool second;

  @override
  bool operator ==(Object other) {
    return other is _CombinedState &&
        other.first == first &&
        other.second == second;
  }

  @override
  int get hashCode => Object.hash(first, second);
}
