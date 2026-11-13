// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/state/widgets/state_engine.dart';

import '../../../shared/mocks/notifiers.dart';

StateEngine<P, T> _engine<P extends StateListenable<dynamic>, T>({
  StateListenable<T>? listenable,
  SelectStateListenable<P, T>? selectListenable,
  StateWidgetBuilder<T>? builder,
  ListenerCallback<T>? listener,
  ListenWhen<T>? listenWhen,
  RebuildWhen<T>? rebuildWhen,
  bool callListenerOnInit = false,
  Widget? child,
}) {
  return StateEngine<P, T>(
    listenable: listenable,
    selectListenable: selectListenable,
    builder: builder,
    listener: listener,
    listenWhen: listenWhen,
    rebuildWhen: rebuildWhen,
    callListenerOnInit: callListenerOnInit,
    widgetName: 'StateEngine',
    child: child,
  );
}

Widget _host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

class _TestListenable<T> implements StateListenable<T> {
  _TestListenable(this._state);

  T _state;
  final List<VoidCallback> _listeners = [];

  @override
  T get state => _state;

  int get listenerCount => _listeners.length;

  void emit(T value) {
    _state = value;
    notify();
  }

  void notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

class _NotifyDuringInit extends StatefulWidget {
  const _NotifyDuringInit({required this.onInit, required this.child});

  final VoidCallback onInit;
  final Widget child;

  @override
  State<_NotifyDuringInit> createState() => _NotifyDuringInitState();
}

class _NotifyDuringInitState extends State<_NotifyDuringInit> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

abstract class _MediaNotifier extends StateNotifier<String> {
  _MediaNotifier(super.initialState)
    : saveMutation = Mutation<void>(),
      rating = StateField<int>(0);

  Mutation<void> saveMutation;
  final StateField<int> rating;

  Mutation<void> replaceSaveMutation() {
    final previous = saveMutation;
    saveMutation = Mutation<void>();
    notifyListeners();
    return previous;
  }

  void disposeResources({Mutation<void>? previousMutation}) {
    previousMutation?.dispose();
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

class _EquatableValue {
  const _EquatableValue(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      other is _EquatableValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

void main() {
  group('StateEngine', () {
    group('direct listenable', () {
      testWidgets('reads the initial state and subscribes once', (
        tester,
      ) async {
        final source = _TestListenable<int>(5);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                states.add(state);
                return Text('$state');
              },
            ),
          ),
        );

        expect(states, [5]);
        expect(find.text('5'), findsOneWidget);
        expect(source.listenerCount, 1);

        await tester.pumpWidget(const SizedBox());
        expect(source.listenerCount, 0);
      });

      testWidgets('updates the builder and listener when state changes', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];
        final listenTransitions = <(int, int)>[];
        final rebuildTransitions = <(int, int)>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
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
                return Text('$state');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        for (var value = 1; value <= 4; value++) {
          source.emit(value);
          await tester.pump();
        }

        expect(buildStates, [0, 1, 2, 3, 4]);
        expect(listenerStates, [1, 2, 3, 4]);
        expect(find.text('4'), findsOneWidget);

        expect(listenTransitions, [(0, 1), (1, 2), (2, 3), (3, 4)]);

        expect(rebuildTransitions, [(0, 1), (1, 2), (2, 3), (3, 4)]);
      });

      testWidgets('ignores notifications when the state is unchanged', (
        tester,
      ) async {
        final source = _TestListenable<int>(7);
        var buildCount = 0;
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildCount++;
                return Text('$state');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        source.notify();
        await tester.pump();

        expect(buildCount, 1);
        expect(listenerStates, isEmpty);
      });

      testWidgets('rebinds when the direct listenable is replaced', (
        tester,
      ) async {
        final first = _TestListenable<int>(1);
        final second = _TestListenable<int>(10);
        final buildStates = <int>[];
        final listenerStates = <int>[];
        var active = first;
        late StateSetter rebuild;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                rebuild = setState;
                return _engine<_TestListenable<int>, int>(
                  listenable: active,
                  builder: (_, state, __) {
                    buildStates.add(state);
                    return Text('$state');
                  },
                  listener: (_, state) => listenerStates.add(state),
                );
              },
            ),
          ),
        );

        first.emit(2);
        await tester.pump();
        expect(listenerStates, [2]);

        rebuild(() => active = second);
        await tester.pump();

        expect(buildStates, [1, 2, 10]);
        expect(listenerStates, [2]);
        expect(first.listenerCount, 0);
        expect(second.listenerCount, 1);

        first.emit(3);
        await tester.pump();
        expect(listenerStates, [2]);

        second.emit(11);
        await tester.pump();
        expect(listenerStates, [2, 11]);
        expect(find.text('11'), findsOneWidget);
      });

      testWidgets(
        'maintains a single listenable subscription across parent rebuilds',
        (tester) async {
          final source = _TestListenable<int>(0);
          final listenerStates = <int>[];
          var parentBuildCount = 0;
          late StateSetter rebuild;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  rebuild = setState;
                  parentBuildCount++;
                  return _engine<_TestListenable<int>, int>(
                    listenable: source,
                    listener: (_, state) => listenerStates.add(state),
                    child: const SizedBox(),
                  );
                },
              ),
            ),
          );

          expect(source.listenerCount, 1);

          rebuild(() {});
          await tester.pump();
          rebuild(() {});
          await tester.pump();

          expect(parentBuildCount, 3);
          expect(source.listenerCount, 1);

          source.emit(1);
          await tester.pump();
          expect(listenerStates, [1]);
        },
      );

      testWidgets('preserves the child in listener-only mode', (tester) async {
        final source = _TestListenable<int>(0);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              listener: (_, state) => listenerStates.add(state),
              child: const Text('Preserved child'),
            ),
          ),
        );

        source.emit(1);
        await tester.pump();

        expect(find.text('Preserved child'), findsOneWidget);
        expect(listenerStates, [1]);
      });
    });

    group('builder and listener behavior', () {
      testWidgets('applies listenWhen and rebuildWhen independently', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];
        final listenTransitions = <(int, int)>[];
        final rebuildTransitions = <(int, int)>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              listenWhen: (previous, current) {
                listenTransitions.add((previous, current));
                return (previous + current) % 3 == 0;
              },
              rebuildWhen: (previous, current) {
                rebuildTransitions.add((previous, current));
                return current.isOdd;
              },
              builder: (_, state, __) {
                buildStates.add(state);
                return Text('$state');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        source.emit(1);
        await tester.pump();

        source.emit(2);
        await tester.pump();

        source.emit(3);
        await tester.pump();

        expect(buildStates, [0, 1, 3]);
        expect(listenerStates, [2]);

        expect(listenTransitions, [(0, 1), (1, 2), (2, 3)]);

        expect(rebuildTransitions, [(0, 1), (1, 2), (2, 3)]);
      });

      testWidgets(
        'preserves the last accepted state when parent rebuilds after a filtered update',
        (tester) async {
          final source = _TestListenable<int>(0);
          final buildStates = <int>[];
          late StateSetter rebuildParent;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  rebuildParent = setState;

                  return _engine<_TestListenable<int>, int>(
                    listenable: source,
                    rebuildWhen: (_, current) => current.isEven,
                    builder: (_, state, __) {
                      buildStates.add(state);
                      return Text('$state');
                    },
                  );
                },
              ),
            ),
          );

          expect(buildStates, [0]);

          source.emit(1);
          source.emit(2);
          source.emit(3);
          await tester.pump();

          expect(buildStates, [0, 2]);

          rebuildParent(() {});
          await tester.pump();

          expect(buildStates, [0, 2, 2]);
          expect(find.text('2'), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        },
      );
      testWidgets('advances the previous-state baseline when filtered', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final previousStates = <int>[];
        final currentStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              listenWhen: (previous, current) {
                previousStates.add(previous);
                currentStates.add(current);
                return current % 3 == 0;
              },
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          ),
        );

        source.emit(1);
        source.emit(2);
        source.emit(3);
        source.emit(4);
        source.emit(5);

        expect(previousStates, [0, 1, 2, 3, 4]);
        expect(currentStates, [1, 2, 3, 4, 5]);
        expect(listenerStates, [3]);
      });

      testWidgets('forwards listenWhen for normal state notifications', (
        tester,
      ) async {
        final provider = CounterProvider();
        final states = <int>[];
        final previousStates = <int>[];
        final currentStates = <int>[];

        await tester.pumpWidget(
          StateListener<int>(
            listenable: provider,
            listenWhen: (previous, current) {
              previousStates.add(previous);
              currentStates.add(current);

              return current.isEven;
            },
            listener: (_, state) => states.add(state),
            child: const SizedBox(),
          ),
        );

        provider.increment();
        await tester.pump();

        expect(states, isEmpty);

        provider.increment();
        await tester.pump();

        expect(states, [2]);
        expect(previousStates, [0, 1]);
        expect(currentStates, [1, 2]);
      });

      testWidgets('delivers every listener event but batches rebuilds', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildStates.add(state);
                return Text('$state');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        source.emit(1);
        source.emit(2);

        expect(listenerStates, [1, 2]);
        await tester.pump();

        expect(buildStates, [0, 2]);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('passes the supplied child to the builder', (tester) async {
        final source = _TestListenable<int>(3);
        const child = Text('Builder child');
        Widget? receivedChild;

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, child) {
                receivedChild = child;
                return Column(
                  children: [Text('$state'), if (child != null) child],
                );
              },
              child: child,
            ),
          ),
        );

        expect(identical(receivedChild, child), isTrue);
        expect(find.text('Builder child'), findsOneWidget);
      });
    });

    group('widget configuration updates', () {
      testWidgets('uses updated callbacks without resubscribing', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final firstBuildStates = <int>[];
        final secondBuildStates = <int>[];
        final firstListenerStates = <int>[];
        final secondListenerStates = <int>[];
        final firstListenTransitions = <(int, int)>[];
        final secondListenTransitions = <(int, int)>[];
        final firstRebuildTransitions = <(int, int)>[];
        final secondRebuildTransitions = <(int, int)>[];

        var useUpdatedCallbacks = false;
        late StateSetter updateConfiguration;

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                updateConfiguration = setState;
                final useUpdated = useUpdatedCallbacks;

                return _engine<_TestListenable<int>, int>(
                  listenable: source,
                  listenWhen: (previous, current) {
                    (useUpdated
                            ? secondListenTransitions
                            : firstListenTransitions)
                        .add((previous, current));
                    return useUpdated;
                  },
                  rebuildWhen: (previous, current) {
                    (useUpdated
                            ? secondRebuildTransitions
                            : firstRebuildTransitions)
                        .add((previous, current));
                    return useUpdated;
                  },
                  builder: (_, state, __) {
                    (useUpdated ? secondBuildStates : firstBuildStates).add(
                      state,
                    );
                    return Text('$state');
                  },
                  listener: (_, state) {
                    (useUpdated ? secondListenerStates : firstListenerStates)
                        .add(state);
                  },
                );
              },
            ),
          ),
        );

        expect(firstBuildStates, [0]);
        expect(source.listenerCount, 1);

        updateConfiguration(() => useUpdatedCallbacks = true);
        await tester.pump();

        expect(firstListenerStates, isEmpty);
        expect(secondBuildStates, [0]);
        expect(source.listenerCount, 1);

        source.emit(1);
        await tester.pump();

        expect(firstListenTransitions, isEmpty);
        expect(firstRebuildTransitions, isEmpty);
        expect(firstListenerStates, isEmpty);
        expect(secondListenTransitions, [(0, 1)]);
        expect(secondRebuildTransitions, [(0, 1)]);
        expect(secondListenerStates, [1]);
        expect(secondBuildStates, [0, 1]);
        expect(source.listenerCount, 1);

        await tester.pumpWidget(const SizedBox());
        expect(source.listenerCount, 0);
      });

      testWidgets(
        'does not replay the initial callback when callListenerOnInit is enabled later',
        (tester) async {
          final source = _TestListenable<int>(0);
          final firstListenerStates = <int>[];
          final secondListenerStates = <int>[];
          var enableInitialListener = false;
          late StateSetter updateConfiguration;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  updateConfiguration = setState;
                  final enabled = enableInitialListener;

                  return _engine<_TestListenable<int>, int>(
                    listenable: source,
                    callListenerOnInit: enabled,
                    listener: (_, state) {
                      (enabled ? secondListenerStates : firstListenerStates)
                          .add(state);
                    },
                    child: const SizedBox(),
                  );
                },
              ),
            ),
          );

          await tester.pump();
          expect(firstListenerStates, isEmpty);
          expect(secondListenerStates, isEmpty);

          updateConfiguration(() => enableInitialListener = true);
          await tester.pump();

          // Enabling the option after initialization must not replay the
          // initial state as though the engine had just mounted.
          expect(secondListenerStates, isEmpty);

          source.emit(1);
          expect(firstListenerStates, isEmpty);
          expect(secondListenerStates, [1]);

          await tester.pumpWidget(const SizedBox());
          expect(source.listenerCount, 0);
        },
      );
    });

    group('reentrant notifications', () {
      testWidgets(
        'processes a state change triggered from a normal listener in order',
        (tester) async {
          final source = _TestListenable<int>(0);
          final buildStates = <int>[];
          final listenerStates = <int>[];
          final transitions = <(int, int)>[];

          await tester.pumpWidget(
            _host(
              _engine<_TestListenable<int>, int>(
                listenable: source,
                listenWhen: (previous, current) {
                  transitions.add((previous, current));
                  return true;
                },
                builder: (_, state, __) {
                  buildStates.add(state);
                  return Text('$state');
                },
                listener: (_, state) {
                  listenerStates.add(state);
                  if (state == 1) {
                    source.emit(2);
                  }
                },
              ),
            ),
          );

          source.emit(1);

          // Listener delivery is synchronous, including the reentrant event.
          expect(listenerStates, [1, 2]);
          expect(transitions, [(0, 1), (1, 2)]);

          await tester.pump();

          // Both notifications are coalesced into one builder update.
          expect(buildStates, [0, 2]);
          expect(find.text('2'), findsOneWidget);
        },
      );
    });

    group('state equality', () {
      testWidgets('uses value equality when deciding whether to notify', (
        tester,
      ) async {
        final source = _TestListenable<_EquatableValue>(
          const _EquatableValue(1),
        );
        final buildStates = <_EquatableValue>[];
        final listenerStates = <_EquatableValue>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<_EquatableValue>, _EquatableValue>(
              listenable: source,
              builder: (_, state, __) {
                buildStates.add(state);
                return Text('${state.value}');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        // A distinct instance with an equal value is not a state change.
        source.emit(const _EquatableValue(1));
        await tester.pump();

        expect(buildStates, [const _EquatableValue(1)]);
        expect(listenerStates, isEmpty);

        source.emit(const _EquatableValue(2));
        await tester.pump();

        expect(buildStates, [
          const _EquatableValue(1),
          const _EquatableValue(2),
        ]);
        expect(listenerStates, [const _EquatableValue(2)]);
        expect(find.text('2'), findsOneWidget);
      });
    });

    group('initial listener', () {
      testWidgets('does not invoke the initial listener by default', (
        tester,
      ) async {
        final source = _TestListenable<int>(5);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pump();

        expect(listenerStates, isEmpty);
      });

      testWidgets('invokes the initial listener when requested', (
        tester,
      ) async {
        final source = _TestListenable<int>(5);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              callListenerOnInit: true,
              listener: (_, state) => listenerStates.add(state),
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pump();

        expect(listenerStates, [5]);
      });

      testWidgets('delivers the initial callback before queued changes', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              callListenerOnInit: true,
              listener: (_, state) => listenerStates.add(state),
              child: _NotifyDuringInit(
                onInit: () {
                  source.state = 1;
                  source.state = 2;
                  source.state = 3;
                },
                child: const SizedBox(),
              ),
            ),
          ),
        );

        expect(listenerStates, [0, 1, 2, 3]);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });

      testWidgets('filters queued listener notifications with listenWhen', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final listenerStates = <int>[];
        final previousStates = <int>[];
        final currentStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              callListenerOnInit: true,
              rebuildWhen: (_, __) => false,
              listenWhen: (previous, current) {
                previousStates.add(previous);
                currentStates.add(current);
                return current.isEven;
              },
              listener: (_, state) => listenerStates.add(state),
              child: _NotifyDuringInit(
                onInit: () {
                  source
                    ..state = 1
                    ..state = 2
                    ..state = 3;
                },
                child: const SizedBox(),
              ),
            ),
          ),
        );

        expect(listenerStates, [0, 2]);
        expect(previousStates, [0, 1, 2]);
        expect(currentStates, [1, 2, 3]);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });

      testWidgets('clears queued changes when the initial listener throws', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              callListenerOnInit: true,
              listener: (_, state) {
                if (state == 0) {
                  throw StateError('initial callback failed');
                }
                listenerStates.add(state);
              },
              child: _NotifyDuringInit(
                onInit: () {
                  source.state = 1;
                  source.state = 2;
                },
                child: const SizedBox(),
              ),
            ),
          ),
        );

        final exception = tester.takeException();
        expect(exception, isA<StateError>());

        source.state = 3;
        await tester.pump();

        expect(listenerStates, [3]);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });

      testWidgets(
        'clears remaining queued changes when a queued listener throws',
        (tester) async {
          final source = StateField<int>(0);
          final listenerStates = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<StateField<int>, int>(
                listenable: source,
                callListenerOnInit: true,
                listener: (_, state) {
                  if (state == 1) {
                    throw StateError('queued callback failed');
                  }
                  listenerStates.add(state);
                },
                child: _NotifyDuringInit(
                  onInit: () {
                    source.state = 1;
                    source.state = 2;
                  },
                  child: const SizedBox(),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isA<StateError>());

          source.state = 3;
          await tester.pump();

          expect(listenerStates, [0, 3]);

          await tester.pumpWidget(const SizedBox());
          source.dispose();
        },
      );

      testWidgets('queues state changes triggered by the initial listener', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              callListenerOnInit: true,
              listener: (_, state) {
                listenerStates.add(state);
                if (state == 0) source.state = 1;
              },
              child: const SizedBox(),
            ),
          ),
        );
        await tester.pump();

        expect(listenerStates, [0, 1]);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });
    });

    group('rebuild scheduling', () {
      testWidgets('defers a rebuild triggered during the initial build', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              builder: (_, state, child) {
                states.add(state);
                return Column(children: [Text('$state'), child!]);
              },
              child: _NotifyDuringInit(
                onInit: () => source.state = 1,
                child: const SizedBox(),
              ),
            ),
          ),
        );

        expect(states, [0]);

        await tester.pump();

        expect(states, [0, 1]);
        expect(find.text('1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });
      testWidgets('defers a rebuild requested while the builder is running', (
        tester,
      ) async {
        final source = StateField<int>(0);
        var buildCount = 0;

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildCount++;
                if (buildCount == 2) source.state = 2;
                return Text('$state');
              },
            ),
          ),
        );

        source.state = 1;
        await tester.pump();

        expect(buildCount, 2);
        expect(tester.takeException(), isNull);

        await tester.pump();

        expect(buildCount, 3);
        expect(find.text('2'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });

      testWidgets('coalesces multiple rebuild requests during one build', (
        tester,
      ) async {
        final source = StateField<int>(0);
        final buildStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<StateField<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildStates.add(state);
                if (state == 1) {
                  source.state = 2;
                  source.state = 3;
                }
                return Text('$state');
              },
            ),
          ),
        );

        source.state = 1;
        await tester.pump();

        expect(buildStates, [0, 1]);
        expect(tester.takeException(), isNull);

        await tester.pump();

        expect(buildStates, [0, 1, 3]);
        expect(find.text('3'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        source.dispose();
      });
    });

    group('Provider integration', () {
      testWidgets('resolves the provider itself when no selector is supplied', (
        tester,
      ) async {
        final provider = StateNotifier<int>(10);
        final buildStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<StateNotifier<int>>.value(
              value: provider,
              child: _engine<StateNotifier<int>, int>(
                builder: (_, state, __) {
                  buildStates.add(state);
                  return Text('$state');
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          ),
        );

        expect(buildStates, [10]);
        expect(find.text('10'), findsOneWidget);
        expect(provider.hasListeners, isTrue);

        provider.state = 11;
        await tester.pump();

        expect(buildStates, [10, 11]);
        expect(listenerStates, [11]);

        await tester.pumpWidget(const SizedBox());
        expect(provider.hasListeners, isFalse);
        provider.dispose();
      });

      testWidgets('resolves a ListenableProvider value', (tester) async {
        final provider = _TestListenable<int>(4);
        final states = <int>[];

        await tester.pumpWidget(
          _host(
            ListenableProvider<_TestListenable<int>>.value(
              value: provider,
              child: _engine<_TestListenable<int>, int>(
                builder: (_, state, __) {
                  states.add(state);
                  return Text('$state');
                },
              ),
            ),
          ),
        );

        expect(states, [4]);

        provider.emit(5);
        await tester.pump();

        expect(states, [4, 5]);

        await tester.pumpWidget(const SizedBox());
        expect(provider.listenerCount, 0);
      });

      testWidgets(
        'rebinds the provider listenable without dispatching a listener',
        (tester) async {
          final first = _MovieNotifier();
          final second = _SeriesNotifier()..state = 'Movie';
          _MediaNotifier active = first;
          final buildStates = <String>[];
          final listenerStates = <String>[];
          late StateSetter replaceProvider;

          final engine = _engine<_MediaNotifier, String>(
            builder: (_, state, __) {
              buildStates.add(state);
              return Text(state);
            },
            listener: (_, state) => listenerStates.add(state),
          );

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  replaceProvider = setState;
                  return ChangeNotifierProvider<_MediaNotifier>.value(
                    value: active,
                    child: engine,
                  );
                },
              ),
            ),
          );

          expect(buildStates, ['Movie']);
          expect(listenerStates, isEmpty);

          replaceProvider(() => active = second);
          await tester.pump();

          expect(buildStates, ['Movie', 'Movie']);
          expect(listenerStates, isEmpty);

          first.state = 'Old provider';
          await tester.pump();
          expect(buildStates, ['Movie', 'Movie']);

          second.state = 'New provider';
          await tester.pump();
          expect(buildStates, ['Movie', 'Movie', 'New provider']);
          expect(listenerStates, ['New provider']);

          await tester.pumpWidget(const SizedBox());
          first.disposeResources();
          second.disposeResources();
        },
      );

      testWidgets(
        'maintains a single provider-resolved subscription across parent rebuilds',
        (tester) async {
          final provider = StateNotifier<int>(0);
          final listenerStates = <int>[];
          var parentBuildCount = 0;
          late StateSetter rebuild;

          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (_, setState) {
                  rebuild = setState;
                  parentBuildCount++;

                  return ChangeNotifierProvider<StateNotifier<int>>.value(
                    value: provider,
                    child: _engine<StateNotifier<int>, int>(
                      listener: (_, state) => listenerStates.add(state),
                      child: const SizedBox(),
                    ),
                  );
                },
              ),
            ),
          );

          expect(parentBuildCount, 1);

          rebuild(() {});
          await tester.pump();

          rebuild(() {});
          await tester.pump();

          expect(parentBuildCount, 3);

          provider.state = 1;
          await tester.pump();

          expect(listenerStates, [1]);

          await tester.pumpWidget(const SizedBox());
          expect(provider.hasListeners, isFalse);

          provider.dispose();
        },
      );

      testWidgets('selects and observes a nested Mutation', (tester) async {
        final movie = _MovieNotifier();
        final mutationStates = <MutationState<void>>[];
        final listenerStates = <MutationState<void>>[];

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<_MovieNotifier>.value(
              value: movie,
              child: _engine<_MovieNotifier, MutationState<void>>(
                selectListenable: (provider) => provider.saveMutation,
                builder: (_, state, __) {
                  mutationStates.add(state);
                  return Text(state.runtimeType.toString());
                },
                listener: (_, state) => listenerStates.add(state),
              ),
            ),
          ),
        );

        expect(mutationStates, hasLength(1));
        expect(mutationStates.first, isA<MutationIdle<void>>());

        final completer = Completer<void>();
        final operation = movie.saveMutation.run(() => completer.future);
        await tester.pump();

        expect(mutationStates.last, isA<MutationLoading<void>>());
        expect(listenerStates.last, isA<MutationLoading<void>>());

        completer.complete();
        await operation;
        await tester.pump();

        expect(mutationStates.last, isA<MutationSuccess<void>>());
        expect(listenerStates.last, isA<MutationSuccess<void>>());

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
      });

      testWidgets('rebinds a nested Mutation when the provider is replaced', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final series = _SeriesNotifier();
        _MediaNotifier active = movie;
        late StateSetter replaceProvider;
        final buildStates = <MutationState<void>>[];
        final listenerStates = <MutationState<void>>[];

        final engine = _engine<_MediaNotifier, MutationState<void>>(
          selectListenable: (provider) => provider.saveMutation,
          builder: (_, state, __) {
            buildStates.add(state);
            return const SizedBox();
          },
          listener: (_, state) => listenerStates.add(state),
        );

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                replaceProvider = setState;
                return ChangeNotifierProvider<_MediaNotifier>.value(
                  value: active,
                  child: engine,
                );
              },
            ),
          ),
        );

        expect(buildStates.last, isA<MutationIdle<void>>());

        final movieCompleter = Completer<void>();
        final movieOperation = movie.saveMutation.run(
          () => movieCompleter.future,
        );
        await tester.pump();
        expect(buildStates.last, isA<MutationLoading<void>>());

        replaceProvider(() => active = series);
        await tester.pump();

        expect(buildStates.last, isA<MutationIdle<void>>());
        expect(listenerStates, hasLength(1));
        expect(listenerStates.single, isA<MutationLoading<void>>());

        final seriesCompleter = Completer<void>();
        final seriesOperation = series.saveMutation.run(
          () => seriesCompleter.future,
        );
        await tester.pump();
        expect(listenerStates, hasLength(2));

        replaceProvider(() => active = movie);
        await tester.pump();

        expect(buildStates.last, isA<MutationLoading<void>>());
        final listenerCountBeforeOldCompletion = listenerStates.length;

        seriesCompleter.complete();
        await seriesOperation;
        await tester.pump();
        expect(listenerStates, hasLength(listenerCountBeforeOldCompletion));

        movieCompleter.complete();
        await movieOperation;
        await tester.pump();

        expect(listenerStates.last, isA<MutationSuccess<void>>());

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
        series.disposeResources();
      });

      testWidgets('rebinds a nested StateField when the provider is replaced', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final series = _SeriesNotifier();
        _MediaNotifier active = movie;
        late StateSetter replaceProvider;
        final states = <int>[];

        final engine = _engine<_MediaNotifier, int>(
          selectListenable: (provider) => provider.rating,
          builder: (_, state, __) {
            states.add(state);
            return Text('$state');
          },
        );

        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                replaceProvider = setState;
                return ChangeNotifierProvider<_MediaNotifier>.value(
                  value: active,
                  child: engine,
                );
              },
            ),
          ),
        );

        movie.rating.state = 1;
        await tester.pump();
        expect(states, [0, 1]);

        replaceProvider(() => active = series);
        await tester.pump();
        expect(states, [0, 1, 0]);

        movie.rating.state = 2;
        await tester.pump();
        expect(states, [0, 1, 0]);

        series.rating.state = 3;
        await tester.pump();
        expect(states, [0, 1, 0, 3]);

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
        series.disposeResources();
      });

      testWidgets('reselects a nested listenable when its owner replaces it', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final oldMutation = movie.saveMutation;
        final listenerStates = <MutationState<void>>[];

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<_MovieNotifier>.value(
              value: movie,
              child: _engine<_MovieNotifier, MutationState<void>>(
                selectListenable: (provider) => provider.saveMutation,
                listener: (_, state) => listenerStates.add(state),
                child: const SizedBox(),
              ),
            ),
          ),
        );

        final replacedMutation = movie.replaceSaveMutation();
        await tester.pump();

        // Replacing the selected listenable is not itself a state event.
        expect(listenerStates, isEmpty);

        final oldCompleter = Completer<void>();
        final oldOperation = oldMutation.run(() => oldCompleter.future);
        await tester.pump();
        expect(listenerStates, isEmpty);

        final newCompleter = Completer<void>();
        final newOperation = movie.saveMutation.run(() => newCompleter.future);
        await tester.pump();
        expect(listenerStates, hasLength(1));
        expect(listenerStates.single, isA<MutationLoading<void>>());

        oldCompleter.complete();
        await oldOperation;
        await tester.pump();
        expect(listenerStates, hasLength(1));

        newCompleter.complete();
        await newOperation;
        await tester.pump();
        expect(listenerStates.last, isA<MutationSuccess<void>>());

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources(previousMutation: replacedMutation);
      });

      testWidgets(
        'works with ChangeNotifierProxyProvider and reuses its notifier',
        (tester) async {
          var sourceValue = 1;
          late StateSetter updateSource;
          late _ProxyNotifier notifier;
          var proxyUpdateCount = 0;
          final buildStates = <int>[];
          final listenerStates = <int>[];

          final engine = _engine<_ProxyNotifier, int>(
            builder: (_, state, __) {
              buildStates.add(state);
              return Text('$state');
            },
            listener: (_, state) => listenerStates.add(state),
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
          expect(buildStates, [0]);

          final initialUpdateCount = proxyUpdateCount;
          updateSource(() => sourceValue = 2);
          await tester.pump();

          expect(proxyUpdateCount, greaterThan(initialUpdateCount));
          expect(notifier.sourceValue, 2);
          expect(buildStates, [0]);

          notifier.state = 1;
          await tester.pump();

          expect(buildStates, [0, 1]);
          expect(listenerStates, [1]);

          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets('supports ProxyProvider feeding ListenableProxyProvider', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final series = _SeriesNotifier();
        var selection = 0;
        late StateSetter updateSelection;
        final states = <int>[];

        final engine = _engine<_MediaNotifier, int>(
          selectListenable: (provider) => provider.rating,
          builder: (_, state, __) {
            states.add(state);
            return Text('$state');
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
                          dispose: (_, __) {},
                          child: engine,
                        ),
                  ),
                );
              },
            ),
          ),
        );

        expect(states, [0]);

        movie.rating.state = 1;
        await tester.pump();
        expect(states, [0, 1]);

        updateSelection(() => selection = 1);
        await tester.pump();
        expect(states, [0, 1, 0]);

        final countAfterReplacement = states.length;
        movie.rating.state = 2;
        await tester.pump();
        expect(states, hasLength(countAfterReplacement));

        series.rating.state = 3;
        await tester.pump();
        expect(states, [0, 1, 0, 3]);

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
        series.disposeResources();
      });
    });

    group('Provider resolution errors', () {
      testWidgets('reports a missing provider through Provider', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            _engine<_MovieNotifier, String>(
              builder: (_, state, __) => Text(state),
            ),
          ),
        );

        expect(tester.takeException(), isA<ProviderNotFoundException>());
      });

      testWidgets('propagates exceptions thrown by selectListenable', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final selectionError = StateError('selectListenable failed');

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<_MovieNotifier>.value(
              value: movie,
              child: _engine<_MovieNotifier, MutationState<void>>(
                selectListenable: (_) => throw selectionError,
                child: const SizedBox(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), same(selectionError));

        await tester.pumpWidget(const SizedBox());
        movie.disposeResources();
      });
    });

    group('lifecycle', () {
      testWidgets('does not run a queued rebuild after disposal', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final buildStates = <int>[];
        final listenerStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildStates.add(state);
                return Text('$state');
              },
              listener: (_, state) => listenerStates.add(state),
            ),
          ),
        );

        // This schedules the engine's rebuild, but the widget is removed
        // before the next frame can perform it.
        source.emit(1);
        expect(listenerStates, [1]);
        expect(buildStates, [0]);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        // Notifications after disposal must not reach either callback.
        source.emit(2);
        await tester.pump();

        expect(buildStates, [0]);
        expect(listenerStates, [1]);
        expect(source.listenerCount, 0);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'does not run a deferred rebuild triggered during initial build after disposal',
        (tester) async {
          final source = StateField<int>(0);
          final states = <int>[];

          await tester.pumpWidget(
            _host(
              _engine<StateField<int>, int>(
                listenable: source,
                builder: (_, state, child) {
                  states.add(state);
                  return Column(children: [Text('$state'), child!]);
                },
                child: _NotifyDuringInit(
                  onInit: () => source.state = 1,
                  child: const SizedBox(),
                ),
              ),
            ),
          );

          expect(states, [0]);

          // Dispose before the deferred rebuild executes.
          await tester.pumpWidget(const SizedBox());
          await tester.pump();

          expect(states, [0]);
          expect(tester.takeException(), isNull);

          source.dispose();
        },
      );

      testWidgets('removes the direct listenable subscription on disposal', (
        tester,
      ) async {
        final source = _TestListenable<int>(0);
        final buildStates = <int>[];

        await tester.pumpWidget(
          _host(
            _engine<_TestListenable<int>, int>(
              listenable: source,
              builder: (_, state, __) {
                buildStates.add(state);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(source.listenerCount, 1);
        await tester.pumpWidget(const SizedBox());
        expect(source.listenerCount, 0);

        source.emit(1);
        await tester.pump();
        expect(buildStates, [0]);
      });

      testWidgets('removes the selected listenable subscription on disposal', (
        tester,
      ) async {
        final movie = _MovieNotifier();
        final listenerStates = <MutationState<void>>[];

        await tester.pumpWidget(
          _host(
            ChangeNotifierProvider<_MovieNotifier>.value(
              value: movie,
              child: _engine<_MovieNotifier, MutationState<void>>(
                selectListenable: (provider) => provider.saveMutation,
                listener: (_, state) => listenerStates.add(state),
                child: const SizedBox(),
              ),
            ),
          ),
        );

        expect(movie.hasListeners, isTrue);
        expect(movie.saveMutation.hasListeners, isTrue);

        await tester.pumpWidget(const SizedBox());

        expect(movie.hasListeners, isFalse);
        expect(movie.saveMutation.hasListeners, isFalse);

        final completer = Completer<void>();
        final operation = movie.saveMutation.run(() => completer.future);
        await tester.pump();
        expect(listenerStates, isEmpty);

        completer.complete();
        await operation;
        await tester.pump();
        expect(listenerStates, isEmpty);

        movie.disposeResources();
      });
    });
  });
}
