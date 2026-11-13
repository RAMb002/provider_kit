// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart';

import '../../shared/mocks/view_state_notifiers.dart';

MultiViewStateEngine<T> _engine<T>({
  required MultiStateListenables<T> listenables,
  MultiViewStateBuilderCallback<T>? builder,
  MultiViewStateListenerCallback<T>? listener,
  ListenWhen<T>? listenWhen,
  RebuildWhen<T>? rebuildWhen,
  bool callListenerOnInit = false,
  Widget? child,
}) {
  return MultiViewStateEngine<T>(
    listenables: listenables,
    builder: builder,
    listener: listener,
    listenWhen: listenWhen,
    rebuildWhen: rebuildWhen,
    callListenerOnInit: callListenerOnInit,
    widgetName: 'MultiViewStateEngine',
    child: child,
  );
}

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Keeps the same engine child while replacing the Provider-owned object.
Widget _switchableStringOwnerProvider({
  required _StringViewStateOwner Function() owner,
  required ValueChanged<StateSetter> onStateSetter,
  required Widget child,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      onStateSetter(setState);
      return ChangeNotifierProvider<_StringViewStateOwner>.value(
        value: owner(),
        child: child,
      );
    },
  );
}

class _StringViewStateOwner extends StateNotifier<String> {
  _StringViewStateOwner(super.value)
    : notifier = TestViewStateNotifier<String>(DataState<String>(value));

  final TestViewStateNotifier<String> notifier;

  void disposeResources() {
    notifier.dispose();
    dispose();
  }
}

class _IntViewStateOwner extends StateNotifier<int> {
  _IntViewStateOwner(super.value)
    : notifier = TestViewStateNotifier<int>(DataState<int>(value));

  final TestViewStateNotifier<int> notifier;

  void disposeResources() {
    notifier.dispose();
    dispose();
  }
}

/// Emits state changes while its parent is being mounted.
class _EmitOnMount extends StatefulWidget {
  const _EmitOnMount({required this.onMount, required this.child});

  final VoidCallback onMount;
  final Widget child;

  @override
  State<_EmitOnMount> createState() => _EmitOnMountState();
}

class _EmitOnMountState extends State<_EmitOnMount> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ProxyViewStateNotifier extends TestViewStateNotifier<String> {
  _ProxyViewStateNotifier() : super(const DataState<String>('initial'));

  int sourceValue = 0;

  void updateSource(int value) {
    sourceValue = value;
  }
}

class _ViewStateSelection {
  const _ViewStateSelection(this.index);

  final int index;
}

void main() {
  group('MultiViewStateEngine', () {
    group('state collection and subscriptions', () {
      testWidgets('collects the initial combined state once', (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        final buildStates = <String>[];
        final aggregateStatuses = <MultiViewStateStatus>[];
        var collectionCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () {
                collectionCount++;
                return provider.watch;
              },
              builder: (_, state, aggregate, __) {
                buildStates.add(state.data);
                aggregateStatuses.add(aggregate.status);
                return Text(state.data);
              },
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(buildStates, ['initial']);
        expect(aggregateStatuses, [MultiViewStateStatus.data]);
        expect(find.text('initial'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets('updates aggregate when dependency access order changes', (
        tester,
      ) async {
        final first = TestViewStateNotifier<String>(
          const LoadingState<String>('First'),
        );
        final second = TestViewStateNotifier<String>(
          const LoadingState<String>('Second'),
        );

        var reverseOrder = false;
        final loadingMessages = <String?>[];

        await tester.pumpWidget(
          _host(
            _engine<int>(
              listenables: () {
                if (reverseOrder) {
                  second.watch;
                  first.watch;
                } else {
                  first.watch;
                  second.watch;
                }

                // Keep the combined state unchanged. This test verifies only
                // that aggregation follows the latest dependency order.
                return 0;
              },
              listener: (_, __, aggregate) {
                loadingMessages.add(aggregate.loadingMessage);
              },
              child: const SizedBox(),
            ),
          ),
        );

        expect(loadingMessages, isEmpty);

        // Change the callback's access order without changing its dependencies.
        reverseOrder = true;

        // This notification causes the callback to be collected again.
        second.emit(const LoadingState<String>('Updated Second'));

        await tester.pump();

        expect(loadingMessages, ['Updated Second']);

        await tester.pumpWidget(const SizedBox());
        first.dispose();
        second.dispose();
      });

      testWidgets('collects each notification and batches builder rebuilds', (
        tester,
      ) async {
        final first = TestViewStateNotifier<String>(
          const DataState<String>('first'),
        );
        final second = TestViewStateNotifier<String>(
          const DataState<String>('second'),
        );

        final buildValues = <List<String>>[];
        final listenerValues = <List<String>>[];
        var collectionCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<List<ViewState<String>>>(
              listenables: () {
                collectionCount++;
                return [first.watch, second.watch];
              },
              builder: (_, state, __, ___) {
                buildValues.add([for (final item in state) item.data]);
                return const SizedBox();
              },
              listener: (_, state, __) {
                listenerValues.add([for (final item in state) item.data]);
              },
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(buildValues, [
          ['first', 'second'],
        ]);
        expect(listenerValues, isEmpty);

        first.emit(const DataState<String>('first-updated'));
        second.emit(const DataState<String>('second-updated'));

        // Each notification is collected and delivered separately.
        expect(collectionCount, 3);
        expect(listenerValues, [
          ['first-updated', 'second'],
          ['first-updated', 'second-updated'],
        ]);

        await tester.pump();

        // Rebuild requests in the same frame are coalesced.
        expect(buildValues, [
          ['first', 'second'],
          ['first-updated', 'second-updated'],
        ]);

        await tester.pumpWidget(const SizedBox());
        first.dispose();
        second.dispose();
      });

      testWidgets('does not subscribe to the same notifier more than once', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        var collectionCount = 0;
        var buildCount = 0;
        var listenerCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<({ViewState<String> first, ViewState<String> second})>(
              listenables: () {
                collectionCount++;
                return (first: provider.watch, second: provider.watch);
              },
              builder: (_, __, ___, ____) {
                buildCount++;
                return const SizedBox();
              },
              listener: (_, __, ___) => listenerCount++,
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(buildCount, 1);
        expect(listenerCount, 0);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(collectionCount, 2);
        expect(buildCount, 2);
        expect(listenerCount, 1);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets(
        'replaces dependencies when the dependency graph changes during a notification',
        (tester) async {
          final selector = TestViewStateNotifier<bool>(
            const DataState<bool>(false),
          );
          final first = TestViewStateNotifier<String>(
            const DataState<String>('first'),
          );
          final second = TestViewStateNotifier<String>(
            const DataState<String>('second'),
          );

          final buildValues = <String>[];
          final listenerValues = <String>[];
          var collectionCount = 0;

          await tester.pumpWidget(
            _host(
              _engine<ViewState<String>>(
                listenables: () {
                  collectionCount++;
                  final useSecond = selector.watch.data;
                  return useSecond ? second.watch : first.watch;
                },
                builder: (_, state, __, ___) {
                  buildValues.add(state.data);
                  return Text(state.data);
                },
                listener: (_, state, __) => listenerValues.add(state.data),
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildValues, ['first']);

          // Changing the selector causes the callback to watch second instead.
          selector.emit(const DataState<bool>(true));
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildValues, ['first', 'second']);
          expect(listenerValues, ['second']);

          // The old dependency is no longer observed.
          first.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(listenerValues, ['second']);

          // The newly selected dependency remains observed.
          second.emit(const DataState<String>('second updated'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildValues, ['first', 'second', 'second updated']);
          expect(listenerValues, ['second', 'second updated']);

          await tester.pumpWidget(const SizedBox());
          selector.dispose();
          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'recollects dependencies when the widget configuration changes without notifying',
        (tester) async {
          final first = TestViewStateNotifier<String>(
            const DataState<String>('first'),
          );
          final second = TestViewStateNotifier<String>(
            const DataState<String>('second'),
          );
          var active = first;
          late StateSetter updateParent;

          final buildValues = <String>[];
          final listenerValues = <String>[];
          var collectionCount = 0;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateParent = setState;
                  return _engine<ViewState<String>>(
                    listenables: () {
                      collectionCount++;
                      return active.watch;
                    },
                    builder: (_, state, __, ___) {
                      buildValues.add(state.data);
                      return Text(state.data);
                    },
                    listener: (_, state, __) => listenerValues.add(state.data),
                  );
                },
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildValues, ['first']);

          updateParent(() => active = second);
          await tester.pump();

          // Widget configuration changes establish a new baseline, not an event.
          expect(collectionCount, 2);
          expect(buildValues, ['first', 'second']);
          expect(listenerValues, isEmpty);

          first.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(listenerValues, isEmpty);

          second.emit(const DataState<String>('second updated'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildValues, ['first', 'second', 'second updated']);
          expect(listenerValues, ['second updated']);

          await tester.pumpWidget(const SizedBox());
          first.dispose();
          second.dispose();
        },
      );

      testWidgets('does not duplicate subscriptions when the parent rebuilds', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        late StateSetter rebuildParent;
        final buildValues = <String>[];
        final listenerValues = <String>[];
        var collectionCount = 0;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                rebuildParent = setState;
                return _engine<ViewState<String>>(
                  listenables: () {
                    collectionCount++;
                    return provider.watch;
                  },
                  builder: (_, state, __, ___) {
                    buildValues.add(state.data);
                    return Text(state.data);
                  },
                  listener: (_, state, __) => listenerValues.add(state.data),
                );
              },
            ),
          ),
        );

        expect(collectionCount, 1);
        expect(buildValues, ['initial']);

        rebuildParent(() {});
        await tester.pump();

        expect(collectionCount, 2);
        expect(buildValues, ['initial', 'initial']);
        expect(listenerValues, isEmpty);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        // One notifier event must produce one collection and one callback.
        expect(collectionCount, 3);
        expect(buildValues, ['initial', 'initial', 'updated']);
        expect(listenerValues, ['updated']);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });
    });

    group('listener delivery and rebuild scheduling', () {
      testWidgets('does not call the listener on initialization by default', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        final listenerValues = <String>[];

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              listener: (_, state, __) => listenerValues.add(state.data),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump();
        expect(listenerValues, isEmpty);

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(listenerValues, ['updated']);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets('calls the initial listener with the initial aggregate', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const LoadingState<String>('Initial loading', 0.25),
        );
        final listenerSnapshots = <(String?, double?)>[];

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              callListenerOnInit: true,
              listener: (_, __, aggregate) {
                listenerSnapshots.add((
                  aggregate.loadingMessage,
                  aggregate.loadingProgress,
                ));
              },
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump();

        expect(listenerSnapshots, [('Initial loading', 0.25)]);

        provider.emit(const LoadingState<String>('Updated loading', 0.5));
        await tester.pump();

        expect(listenerSnapshots, [
          ('Initial loading', 0.25),
          ('Updated loading', 0.5),
        ]);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets('queues state changes triggered by the initial listener', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );

        final listenerValues = <String>[];

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              callListenerOnInit: true,
              listener: (_, state, __) {
                listenerValues.add(state.data);

                if (state.data == 'initial') {
                  provider.emit(const DataState<String>('updated'));
                }
              },
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump();

        // The initial listener runs first. Its state change must be queued
        // and delivered afterward, rather than being lost or executed recursively.
        expect(listenerValues, ['initial', 'updated']);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets(
        'delivers the initial listener before notifications queued during the first build',
        (tester) async {
          final provider = TestViewStateNotifier<String>(
            const DataState<String>('initial'),
          );
          final listenerSnapshots = <(MultiViewStateStatus, String?)>[];
          final buildStatuses = <MultiViewStateStatus>[];

          await tester.pumpWidget(
            _host(
              _engine<ViewState<String>>(
                listenables: () => provider.watch,
                callListenerOnInit: true,
                builder: (_, __, aggregate, child) {
                  buildStatuses.add(aggregate.status);
                  return child!;
                },
                listener: (_, __, aggregate) {
                  listenerSnapshots.add((
                    aggregate.status,
                    aggregate.loadingMessage,
                  ));
                },
                child: _EmitOnMount(
                  onMount: () {
                    provider.emit(const LoadingState<String>('First update'));
                    provider.emit(const LoadingState<String>('Second update'));
                  },
                  child: const SizedBox(),
                ),
              ),
            ),
          );

          // Changes during the initial build are deferred into one rebuild.
          expect(buildStatuses, [MultiViewStateStatus.data]);

          await tester.pump();

          expect(buildStatuses, [
            MultiViewStateStatus.data,
            MultiViewStateStatus.loading,
          ]);
          expect(listenerSnapshots, [
            (MultiViewStateStatus.data, null),
            (MultiViewStateStatus.loading, 'First update'),
            (MultiViewStateStatus.loading, 'Second update'),
          ]);

          await tester.pumpWidget(const SizedBox());
          provider.dispose();
        },
      );

      testWidgets('queues state changes triggered by a listener', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        final listenerValues = <String>[];
        final buildValues = <String>[];

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              builder: (_, state, __, ___) {
                buildValues.add(state.data);
                return Text(state.data);
              },
              listener: (_, state, __) {
                listenerValues.add(state.data);
                if (state.data == 'first update') {
                  provider.emit(const DataState<String>('second update'));
                }
              },
            ),
          ),
        );

        provider.emit(const DataState<String>('first update'));
        await tester.pump();

        expect(listenerValues, ['first update', 'second update']);
        expect(buildValues.last, 'second update');
        expect(find.text('second update'), findsOneWidget);

        provider.emit(const DataState<String>('third update'));
        await tester.pump();

        expect(listenerValues, [
          'first update',
          'second update',
          'third update',
        ]);
        expect(buildValues.last, 'third update');

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });

      testWidgets('listener-only mode preserves its child', (tester) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );
        final listenerValues = <String>[];

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              listener: (_, state, __) => listenerValues.add(state.data),
              child: const Text('Listener child'),
            ),
          ),
        );

        provider.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(find.text('Listener child'), findsOneWidget);
        expect(listenerValues, ['updated']);

        await tester.pumpWidget(const SizedBox());
        provider.dispose();
      });
    });

    group('Provider integration', () {
      testWidgets('resolves multiple Provider-owned listenables with of', (
        tester,
      ) async {
        final stringOwner = _StringViewStateOwner('first');
        final intOwner = _IntViewStateOwner(10);
        final buildValues = <(String, int)>[];
        final listenerValues = <(String, int)>[];

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<_StringViewStateOwner>.value(
              value: stringOwner,
              child: ChangeNotifierProvider<_IntViewStateOwner>.value(
                value: intOwner,
                child:
                    _engine<({ViewState<String> first, ViewState<int> second})>(
                      listenables: () => (
                        first: of<_StringViewStateOwner>().notifier.watch,
                        second: of<_IntViewStateOwner>().notifier.watch,
                      ),
                      builder: (_, state, __, ___) {
                        buildValues.add((state.first.data, state.second.data));
                        return const SizedBox();
                      },
                      listener: (_, state, __) {
                        listenerValues.add((
                          state.first.data,
                          state.second.data,
                        ));
                      },
                    ),
              ),
            ),
          ),
        );

        expect(buildValues, [('first', 10)]);
        expect(listenerValues, isEmpty);

        stringOwner.notifier.emit(const DataState<String>('updated'));
        await tester.pump();

        expect(buildValues, [('first', 10), ('updated', 10)]);
        expect(listenerValues, [('updated', 10)]);

        intOwner.notifier.emit(const DataState<int>(11));
        await tester.pump();

        expect(buildValues, [('first', 10), ('updated', 10), ('updated', 11)]);
        expect(listenerValues, [('updated', 10), ('updated', 11)]);

        await tester.pumpWidget(const SizedBox());
        stringOwner.disposeResources();
        intOwner.disposeResources();
      });

      testWidgets(
        'subscribes to a Provider-owned ViewStateNotifier and rebinds when the Provider instance changes',
        (tester) async {
          final first = TestViewStateNotifier<String>(
            const DataState<String>('first'),
          );

          final second = TestViewStateNotifier<String>(
            const DataState<String>('second'),
          );

          var activeProvider = first;
          late StateSetter replaceProvider;

          final buildStates = <String>[];
          final listenerStates = <String>[];

          var collectionCount = 0;

          // Keep the same engine widget while replacing the Provider value.
          final engine = _engine<ViewState<String>>(
            listenables: () {
              collectionCount++;
              return of<TestViewStateNotifier<String>>().watch;
            },
            builder: (_, state, __, ___) {
              buildStates.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) {
              listenerStates.add(state.data);
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  replaceProvider = setState;

                  return ChangeNotifierProvider<
                    TestViewStateNotifier<String>
                  >.value(value: activeProvider, child: engine);
                },
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildStates, ['first']);
          expect(listenerStates, isEmpty);

          // The currently provided notifier must be observed.
          first.emit(const DataState<String>('first updated'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, ['first', 'first updated']);
          expect(listenerStates, ['first updated']);

          // Replace the Provider value with another notifier.
          replaceProvider(() {
            activeProvider = second;
          });
          await tester.pump();

          // Replacement establishes a new baseline, not a listener event.
          expect(collectionCount, 3);
          expect(buildStates, ['first', 'first updated', 'second']);
          expect(listenerStates, ['first updated']);

          // The old notifier must no longer trigger updates.
          first.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, ['first', 'first updated', 'second']);
          expect(listenerStates, ['first updated']);

          // The replacement notifier must now be observed.
          second.emit(const DataState<String>('second updated'));
          await tester.pump();

          expect(collectionCount, 4);
          expect(buildStates, [
            'first',
            'first updated',
            'second',
            'second updated',
          ]);
          expect(listenerStates, ['first updated', 'second updated']);

          await tester.pumpWidget(const SizedBox());

          expect(first.hasListeners, isFalse);
          expect(second.hasListeners, isFalse);

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'replacing a Provider-owned notifier with equal state establishes a new baseline',
        (tester) async {
          final first = TestViewStateNotifier<String>(
            const DataState<String>('same'),
          );

          final second = TestViewStateNotifier<String>(
            const DataState<String>('same'),
          );

          var activeProvider = first;
          late StateSetter replaceProvider;

          final buildStates = <String>[];
          final listenerStates = <String>[];

          final engine = _engine<ViewState<String>>(
            listenables: () => of<TestViewStateNotifier<String>>().watch,
            builder: (_, state, __, ___) {
              buildStates.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) {
              listenerStates.add(state.data);
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  replaceProvider = setState;

                  return ChangeNotifierProvider<
                    TestViewStateNotifier<String>
                  >.value(value: activeProvider, child: engine);
                },
              ),
            ),
          );

          expect(buildStates, ['same']);
          expect(listenerStates, isEmpty);

          // Replace with a different notifier having the same state.
          replaceProvider(() {
            activeProvider = second;
          });
          await tester.pump();

          expect(buildStates, ['same', 'same']);
          expect(listenerStates, isEmpty);

          // The old notifier is no longer observed.
          first.emit(const DataState<String>('old update'));
          await tester.pump();

          expect(buildStates, ['same', 'same']);
          expect(listenerStates, isEmpty);

          // The new notifier is observed.
          second.emit(const DataState<String>('new update'));
          await tester.pump();

          expect(buildStates, ['same', 'same', 'new update']);
          expect(listenerStates, ['new update']);

          await tester.pumpWidget(const SizedBox());

          expect(first.hasListeners, isFalse);
          expect(second.hasListeners, isFalse);

          first.dispose();
          second.dispose();
        },
      );
      testWidgets(
        'works with ListenableProvider.value and rebinds when the Provider instance changes',
        (tester) async {
          final first = TestViewStateNotifier<String>(
            const DataState<String>('first'),
          );

          final second = TestViewStateNotifier<String>(
            const DataState<String>('second'),
          );

          var activeProvider = first;
          late StateSetter replaceProvider;

          final buildStates = <String>[];
          final listenerStates = <String>[];

          var collectionCount = 0;

          final engine = _engine<ViewState<String>>(
            listenables: () {
              collectionCount++;
              return of<TestViewStateNotifier<String>>().watch;
            },
            builder: (_, state, __, ___) {
              buildStates.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) {
              listenerStates.add(state.data);
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  replaceProvider = setState;

                  return ListenableProvider<
                    TestViewStateNotifier<String>
                  >.value(value: activeProvider, child: engine);
                },
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildStates, ['first']);
          expect(listenerStates, isEmpty);

          // The first notifier is observed.
          first.emit(const DataState<String>('first updated'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, ['first', 'first updated']);
          expect(listenerStates, ['first updated']);

          // Replace the provided notifier.
          replaceProvider(() {
            activeProvider = second;
          });
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, ['first', 'first updated', 'second']);
          expect(listenerStates, ['first updated']);

          // The old notifier must no longer trigger updates.
          first.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(listenerStates, ['first updated']);

          // The replacement notifier must now be observed.
          second.emit(const DataState<String>('second updated'));
          await tester.pump();

          expect(collectionCount, 4);
          expect(buildStates, [
            'first',
            'first updated',
            'second',
            'second updated',
          ]);
          expect(listenerStates, ['first updated', 'second updated']);

          await tester.pumpWidget(const SizedBox());

          expect(first.hasListeners, isFalse);
          expect(second.hasListeners, isFalse);

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'works with ChangeNotifierProxyProvider and reuses its notifier',
        (tester) async {
          var sourceValue = 1;

          late StateSetter updateSource;
          late _ProxyViewStateNotifier notifier;

          var createCount = 0;
          var proxyUpdateCount = 0;
          var collectionCount = 0;

          final buildStates = <String>[];
          final listenerStates = <String>[];

          final engine = _engine<ViewState<String>>(
            listenables: () {
              collectionCount++;
              return of<_ProxyViewStateNotifier>().watch;
            },
            builder: (_, state, __, ___) {
              buildStates.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) {
              listenerStates.add(state.data);
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateSource = setState;

                  return Provider<int>.value(
                    value: sourceValue,
                    child:
                        ChangeNotifierProxyProvider<
                          int,
                          _ProxyViewStateNotifier
                        >(
                          create: (_) {
                            createCount++;
                            return notifier = _ProxyViewStateNotifier();
                          },
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

          expect(createCount, 1);
          expect(proxyUpdateCount, greaterThan(0));
          expect(notifier.sourceValue, 1);

          expect(collectionCount, 1);
          expect(buildStates, ['initial']);
          expect(listenerStates, isEmpty);

          final initialProxyUpdateCount = proxyUpdateCount;

          // Change the upstream Provider value.
          updateSource(() {
            sourceValue = 2;
          });

          await tester.pump();

          // The proxy updates but reuses the same notifier.
          expect(proxyUpdateCount, greaterThan(initialProxyUpdateCount));
          expect(createCount, 1);
          expect(notifier.sourceValue, 2);

          // Reusing the same notifier must not cause dependency recollection.
          expect(collectionCount, 1);
          expect(buildStates, ['initial']);
          expect(listenerStates, isEmpty);

          // The engine must still be subscribed to the reused notifier.
          notifier.emit(const DataState<String>('updated'));

          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, ['initial', 'updated']);
          expect(listenerStates, ['updated']);

          // ChangeNotifierProxyProvider owns and disposes the notifier.
          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'supports ProxyProvider values feeding ListenableProxyProvider notifiers',
        (tester) async {
          final first = TestViewStateNotifier<String>(
            const DataState<String>('first'),
          );

          final second = TestViewStateNotifier<String>(
            const DataState<String>('second'),
          );

          var selection = 0;
          late StateSetter updateSelection;

          final buildStates = <String>[];
          final listenerStates = <String>[];

          var collectionCount = 0;

          final engine = _engine<ViewState<String>>(
            listenables: () {
              collectionCount++;
              return of<TestViewStateNotifier<String>>().watch;
            },
            builder: (_, state, __, ___) {
              buildStates.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) {
              listenerStates.add(state.data);
            },
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateSelection = setState;

                  return Provider<int>.value(
                    value: selection,
                    child: ProxyProvider<int, _ViewStateSelection>(
                      update: (_, index, __) => _ViewStateSelection(index),
                      child:
                          ListenableProxyProvider<
                            _ViewStateSelection,
                            TestViewStateNotifier<String>
                          >(
                            update: (_, selected, __) =>
                                selected.index == 0 ? first : second,
                            // The notifiers are externally owned by this test.
                            dispose: (_, __) {},
                            child: engine,
                          ),
                    ),
                  );
                },
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildStates, ['first']);
          expect(listenerStates, isEmpty);

          // The currently selected notifier is observed.
          first.emit(const DataState<String>('first updated'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildStates, ['first', 'first updated']);
          expect(listenerStates, ['first updated']);

          // Change the upstream selection. The proxy chain now exposes second.
          updateSelection(() {
            selection = 1;
          });

          await tester.pump();

          // Replacing the selected notifier establishes a new baseline.
          expect(collectionCount, 3);
          expect(buildStates, ['first', 'first updated', 'second']);
          expect(listenerStates, ['first updated']);

          // The previously selected notifier must no longer be observed.
          first.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildStates, ['first', 'first updated', 'second']);
          expect(listenerStates, ['first updated']);

          // The newly selected notifier must be observed.
          second.emit(const DataState<String>('second updated'));
          await tester.pump();

          expect(collectionCount, 4);
          expect(buildStates, [
            'first',
            'first updated',
            'second',
            'second updated',
          ]);
          expect(listenerStates, ['first updated', 'second updated']);

          await tester.pumpWidget(const SizedBox());

          expect(first.hasListeners, isFalse);
          expect(second.hasListeners, isFalse);

          first.dispose();
          second.dispose();
        },
      );

      testWidgets(
        'tracks multiple Provider dependencies independently when one is replaced',
        (tester) async {
          final firstMedia = TestViewStateNotifier<String>(
            const DataState<String>('first media'),
          );

          final secondMedia = TestViewStateNotifier<String>(
            const DataState<String>('second media'),
          );

          final profile = TestViewStateNotifier<int>(const DataState<int>(10));

          var activeMedia = firstMedia;
          late StateSetter replaceMedia;

          final buildValues = <(String, int)>[];
          final listenerValues = <(String, int)>[];

          var collectionCount = 0;

          final engine =
              _engine<({ViewState<String> media, ViewState<int> profile})>(
                listenables: () {
                  collectionCount++;

                  return (
                    media: of<TestViewStateNotifier<String>>().watch,
                    profile: of<TestViewStateNotifier<int>>().watch,
                  );
                },
                builder: (_, state, __, ___) {
                  buildValues.add((state.media.data, state.profile.data));
                  return const SizedBox();
                },
                listener: (_, state, __) {
                  listenerValues.add((state.media.data, state.profile.data));
                },
              );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  replaceMedia = setState;

                  return ChangeNotifierProvider<
                    TestViewStateNotifier<String>
                  >.value(
                    value: activeMedia,
                    child:
                        ChangeNotifierProvider<
                          TestViewStateNotifier<int>
                        >.value(value: profile, child: engine),
                  );
                },
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildValues, [('first media', 10)]);
          expect(listenerValues, isEmpty);

          // Both Provider dependencies initially work.
          firstMedia.emit(const DataState<String>('first media updated'));
          await tester.pump();

          expect(buildValues.last, ('first media updated', 10));
          expect(listenerValues.last, ('first media updated', 10));

          profile.emit(const DataState<int>(11));
          await tester.pump();

          expect(buildValues.last, ('first media updated', 11));
          expect(listenerValues.last, ('first media updated', 11));

          // Replace only the media Provider. The profile Provider remains unchanged.
          replaceMedia(() {
            activeMedia = secondMedia;
          });

          await tester.pump();

          expect(collectionCount, 4);
          expect(buildValues.last, ('second media', 11));

          // Provider replacement establishes a new baseline, not a listener event.
          expect(listenerValues, [
            ('first media updated', 10),
            ('first media updated', 11),
          ]);

          // The old media notifier must be detached.
          expect(firstMedia.hasListeners, isFalse);

          firstMedia.emit(const DataState<String>('stale media update'));
          await tester.pump();

          expect(collectionCount, 4);
          expect(buildValues.last, ('second media', 11));

          // The unchanged profile Provider must remain subscribed.
          expect(profile.hasListeners, isTrue);

          profile.emit(const DataState<int>(12));
          await tester.pump();

          expect(collectionCount, 5);
          expect(buildValues.last, ('second media', 12));
          expect(listenerValues.last, ('second media', 12));

          // The replacement media Provider must also be subscribed.
          secondMedia.emit(const DataState<String>('second media updated'));
          await tester.pump();

          expect(collectionCount, 6);
          expect(buildValues.last, ('second media updated', 12));
          expect(listenerValues.last, ('second media updated', 12));

          await tester.pumpWidget(const SizedBox());

          expect(firstMedia.hasListeners, isFalse);
          expect(secondMedia.hasListeners, isFalse);
          expect(profile.hasListeners, isFalse);

          firstMedia.dispose();
          secondMedia.dispose();
          profile.dispose();
        },
      );

      testWidgets(
        'rebinds nested notifier subscriptions when the Provider-owned object changes',
        (tester) async {
          final firstOwner = _StringViewStateOwner('same');
          final secondOwner = _StringViewStateOwner('same');
          var activeOwner = firstOwner;
          late StateSetter replaceOwner;
          var collectionCount = 0;
          final buildValues = <String>[];
          final listenerValues = <String>[];

          final engine = _engine<ViewState<String>>(
            listenables: () {
              collectionCount++;
              return of<_StringViewStateOwner>().notifier.watch;
            },
            builder: (_, state, __, ___) {
              buildValues.add(state.data);
              return Text(state.data);
            },
            listener: (_, state, __) => listenerValues.add(state.data),
          );

          await tester.pumpWidget(
            _host(
              _switchableStringOwnerProvider(
                owner: () => activeOwner,
                onStateSetter: (setState) => replaceOwner = setState,
                child: engine,
              ),
            ),
          );

          expect(collectionCount, 1);
          expect(buildValues, ['same']);
          expect(listenerValues, isEmpty);

          // Replacing the Provider value establishes a new baseline.
          // The replacement itself is not a state-listener event.
          replaceOwner(() => activeOwner = secondOwner);
          await tester.pump();

          expect(collectionCount, 2);
          expect(buildValues, ['same', 'same']);
          expect(listenerValues, isEmpty);

          // The removed notifier is no longer observed.
          firstOwner.notifier.emit(const DataState<String>('stale update'));
          await tester.pump();

          expect(collectionCount, 2);
          expect(listenerValues, isEmpty);

          secondOwner.notifier.emit(const DataState<String>('new update'));
          await tester.pump();

          expect(collectionCount, 3);
          expect(buildValues, ['same', 'same', 'new update']);
          expect(listenerValues, ['new update']);

          await tester.pumpWidget(const SizedBox());
          firstOwner.disposeResources();
          secondOwner.disposeResources();
        },
      );

      testWidgets(
        'throws ProviderNotFoundException when a Provider is missing',
        (tester) async {
          await tester.pumpWidget(
            _host(
              _engine<ViewState<String>>(
                listenables: () => of<_StringViewStateOwner>().notifier.watch,
                builder: (_, __, ___, ____) => const SizedBox(),
              ),
            ),
          );

          expect(tester.takeException(), isA<ProviderNotFoundException>());
        },
      );
    });

    group('lifecycle and validation', () {
      testWidgets('removes state subscriptions when the engine is disposed', (
        tester,
      ) async {
        final provider = TestViewStateNotifier<String>(
          const DataState<String>('initial'),
        );

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => provider.watch,
              builder: (_, __, ___, ____) => const SizedBox(),
            ),
          ),
        );

        expect(provider.hasListeners, isTrue);

        await tester.pumpWidget(const SizedBox());

        expect(provider.hasListeners, isFalse);
        provider.dispose();
      });

      testWidgets('asserts when no watched state source is collected', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () => const DataState<String>('data'),
              builder: (_, __, ___, ____) => const SizedBox(),
            ),
          ),
        );

        expect(tester.takeException(), isA<AssertionError>());
      });

      testWidgets(
        'rejects a watched dependency that is not a ViewStateNotifier',
        (tester) async {
          final field = StateField<String>('data');

          await tester.pumpWidget(
            _host(
              _engine<String>(
                listenables: () => field.watch,
                builder: (_, __, ___, ____) => const SizedBox(),
              ),
            ),
          );

          expect(
            tester.takeException(),
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('ViewStateNotifier'),
            ),
          );

          await tester.pumpWidget(const SizedBox());
          field.dispose();
        },
      );

      testWidgets('cleans the collection scope when listenables throws', (
        tester,
      ) async {
        final field = StateField<String>('data');

        await tester.pumpWidget(
          _host(
            _engine<ViewState<String>>(
              listenables: () {
                field.watch;
                throw StateError('Collection failed');
              },
              builder: (_, __, ___, ____) => const SizedBox(),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Collection failed',
          ),
        );
        expect(field.hasListeners, isFalse);

        await tester.pumpWidget(const SizedBox());
        field.dispose();
      });
    });
  });
}
