import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  Widget wrap(Widget child) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }

  group('WatchBuilder', () {
    // =========================================================================
    // INITIAL BUILD
    // =========================================================================

    testWidgets('builds initially and returns the widget produced by builder', (
      tester,
    ) async {
      final source = _TestStateSource<int>(10);
      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final value = source.watch;

              return Text('$value', key: const Key('value'));
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('10'), findsOneWidget);
      expect(source.listenerCount, 1);
    });

    testWidgets('passes child to builder', (tester) async {
      final source = _TestStateSource<int>(10);
      const child = SizedBox(key: Key('child'));

      Widget? receivedChild;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            child: child,
            builder: (context, child) {
              receivedChild = child;

              source.watch;

              return Column(children: [if (child != null) child]);
            },
          ),
        ),
      );

      expect(identical(receivedChild, child), isTrue);
      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    // =========================================================================
    // SINGLE DEPENDENCY
    // =========================================================================

    testWidgets('rebuilds when the watched dependency notifies', (
      tester,
    ) async {
      final source = _TestStateSource<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final value = source.watch;

              return Text('$value');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      source.value = 1;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets(
      'rebuilds from a notification even when the state value is unchanged',
      (tester) async {
        final source = _TestStateSource<int>(10);
        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                buildCount++;

                source.watch;

                return const SizedBox();
              },
            ),
          ),
        );

        expect(buildCount, 1);

        source.notify();
        await tester.pump();

        expect(buildCount, 2);
      },
    );

    // =========================================================================
    // MULTIPLE DEPENDENCIES
    // =========================================================================

    testWidgets('subscribes to multiple watched dependencies', (tester) async {
      final first = _TestStateSource<int>(1);
      final second = _TestStateSource<int>(2);

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              final firstValue = first.watch;
              final secondValue = second.watch;

              return Text('$firstValue $secondValue');
            },
          ),
        ),
      );

      expect(first.listenerCount, 1);
      expect(second.listenerCount, 1);
      expect(find.text('1 2'), findsOneWidget);
    });

    testWidgets('rebuilds when the first watched dependency changes', (
      tester,
    ) async {
      final first = _TestStateSource<int>(1);
      final second = _TestStateSource<int>(2);
      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final firstValue = first.watch;
              final secondValue = second.watch;

              return Text('$firstValue $secondValue');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      first.value = 10;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('10 2'), findsOneWidget);
    });

    testWidgets('rebuilds when the second watched dependency changes', (
      tester,
    ) async {
      final first = _TestStateSource<int>(1);
      final second = _TestStateSource<int>(2);
      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final firstValue = first.watch;
              final secondValue = second.watch;

              return Text('$firstValue $secondValue');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      second.value = 20;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('1 20'), findsOneWidget);
    });

    // =========================================================================
    // DUPLICATE WATCHES
    // =========================================================================

    testWidgets(
      'creates only one subscription when the same source is watched multiple times',
      (tester) async {
        final source = _TestStateSource<int>(10);
        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                buildCount++;

                final first = source.watch;
                final second = source.watch;
                final third = source.watch;

                return Text('$first $second $third');
              },
            ),
          ),
        );

        expect(source.listenerCount, 1);
        expect(buildCount, 1);
        expect(find.text('10 10 10'), findsOneWidget);

        source.value = 20;
        await tester.pump();

        // One source notification must result in only one rebuild.
        expect(buildCount, 2);
        expect(source.listenerCount, 1);
        expect(find.text('20 20 20'), findsOneWidget);
      },
    );

    // =========================================================================
    // DYNAMIC DEPENDENCIES
    // =========================================================================

    testWidgets('adds dependencies when they become reachable', (tester) async {
      final enabled = _TestStateSource<bool>(false);
      final user = _TestStateSource<String>('John');

      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final isEnabled = enabled.watch;

              if (!isEnabled) {
                return const Text('Disabled');
              }

              final name = user.watch;

              return Text(name);
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Disabled'), findsOneWidget);

      expect(enabled.listenerCount, 1);
      expect(user.listenerCount, 0);

      enabled.value = true;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('John'), findsOneWidget);

      expect(enabled.listenerCount, 1);
      expect(user.listenerCount, 1);
    });

    testWidgets('removes dependencies when they are no longer reachable', (
      tester,
    ) async {
      final enabled = _TestStateSource<bool>(true);
      final user = _TestStateSource<String>('John');

      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final isEnabled = enabled.watch;

              if (!isEnabled) {
                return const Text('Disabled');
              }

              final name = user.watch;

              return Text(name);
            },
          ),
        ),
      );

      expect(enabled.listenerCount, 1);
      expect(user.listenerCount, 1);

      enabled.value = false;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Disabled'), findsOneWidget);

      expect(enabled.listenerCount, 1);
      expect(user.listenerCount, 0);
    });

    testWidgets('removed dependencies no longer trigger rebuilds', (
      tester,
    ) async {
      final enabled = _TestStateSource<bool>(true);
      final user = _TestStateSource<String>('John');

      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final isEnabled = enabled.watch;

              if (!isEnabled) {
                return const Text('Disabled');
              }

              return Text(user.watch);
            },
          ),
        ),
      );

      expect(buildCount, 1);

      enabled.value = false;
      await tester.pump();

      expect(buildCount, 2);
      expect(user.listenerCount, 0);

      user.value = 'Jane';
      await tester.pump();

      // `user` is no longer a dependency.
      expect(buildCount, 2);
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets(
      'newly added dependencies trigger rebuilds after becoming active',
      (tester) async {
        final enabled = _TestStateSource<bool>(false);
        final user = _TestStateSource<String>('John');

        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                buildCount++;

                final isEnabled = enabled.watch;

                if (!isEnabled) {
                  return const Text('Disabled');
                }

                return Text(user.watch);
              },
            ),
          ),
        );

        expect(user.listenerCount, 0);

        enabled.value = true;
        await tester.pump();

        expect(user.listenerCount, 1);
        expect(buildCount, 2);

        user.value = 'Jane';
        await tester.pump();

        expect(buildCount, 3);
        expect(find.text('Jane'), findsOneWidget);
      },
    );

    // =========================================================================
    // DEPENDENCY COLLECTION THROUGH HELPERS
    // =========================================================================

    testWidgets('tracks dependencies accessed through helper methods', (
      tester,
    ) async {
      final source = _TestStateSource<int>(10);
      var buildCount = 0;

      int readValue() {
        return source.watch;
      }

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              return Text('${readValue()}');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(source.listenerCount, 1);
      expect(find.text('10'), findsOneWidget);

      source.value = 20;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('20'), findsOneWidget);
    });

    // =========================================================================
    // PARENT REBUILDS
    // =========================================================================

    testWidgets('parent rebuilds do not create duplicate subscriptions', (
      tester,
    ) async {
      final source = _TestStateSource<int>(0);
      final parentKey = GlobalKey<_RebuildParentState>();

      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          _RebuildParent(
            key: parentKey,
            builder: () {
              return WatchBuilder(
                builder: (context, child) {
                  buildCount++;

                  return Text('${source.watch}');
                },
              );
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(source.listenerCount, 1);

      parentKey.currentState!.rebuildParent();
      await tester.pump();

      expect(buildCount, 2);
      expect(source.listenerCount, 1);

      parentKey.currentState!.rebuildParent();
      await tester.pump();

      expect(buildCount, 3);
      expect(source.listenerCount, 1);

      source.value = 1;
      await tester.pump();

      // Still only one subscription.
      expect(buildCount, 4);
      expect(source.listenerCount, 1);
    });

    // =========================================================================
    // WIDGET CONFIGURATION UPDATES
    // =========================================================================

    testWidgets('updates subscriptions when the widget configuration changes', (
      tester,
    ) async {
      final first = _TestStateSource<int>(1);
      final second = _TestStateSource<int>(2);

      final watchKey = GlobalKey();

      var useSecond = false;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            key: watchKey,
            builder: (context, child) {
              final value = (useSecond ? second : first).watch;

              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(first.listenerCount, 1);
      expect(second.listenerCount, 0);

      useSecond = true;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            key: watchKey,
            builder: (context, child) {
              final value = (useSecond ? second : first).watch;

              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(first.listenerCount, 0);
      expect(second.listenerCount, 1);

      first.value = 100;
      await tester.pump();

      // Old dependency must no longer affect the widget.
      expect(find.text('2'), findsOneWidget);
      expect(second.listenerCount, 1);
    });

    testWidgets(
      'does not duplicate subscriptions when configuration changes but '
      'dependencies remain the same',
      (tester) async {
        final source = _TestStateSource<int>(1);
        final watchKey = GlobalKey();

        String text = 'first';

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              key: watchKey,
              builder: (context, child) {
                final value = source.watch;

                return Text('$text $value');
              },
            ),
          ),
        );

        expect(firstOf(find.byType(Text), tester), 'first 1');
        expect(source.listenerCount, 1);

        text = 'second';

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              key: watchKey,
              builder: (context, child) {
                final value = source.watch;

                return Text('$text $value');
              },
            ),
          ),
        );

        expect(firstOf(find.byType(Text), tester), 'second 1');
        expect(source.listenerCount, 1);

        source.value = 2;
        await tester.pump();

        expect(firstOf(find.byType(Text), tester), 'second 2');
        expect(source.listenerCount, 1);
      },
    );

    // =========================================================================
    // BUILD SCHEDULING
    // =========================================================================

    testWidgets(
      'does not synchronously rebuild while a dependency notifies during build',
      (tester) async {
        final first = _TestStateSource<int>(0);
        final second = _TestStateSource<int>(0);

        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                buildCount++;

                final firstValue = first.watch;
                final secondValue = second.watch;

                if (buildCount == 2) {
                  first.notify();
                }

                return Text('$firstValue $secondValue');
              },
            ),
          ),
        );

        expect(buildCount, 1);

        first.notify();
        await tester.pump();

        // First notification caused build #2.
        expect(buildCount, 2);

        // The notification from inside build #2 must be deferred.
        // No "setState() or markNeedsBuild() called during build" error.
        expect(tester.takeException(), isNull);

        await tester.pump();

        expect(buildCount, 3);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'coalesces multiple dependency notifications during the same build',
      (tester) async {
        final first = _TestStateSource<int>(0);
        final second = _TestStateSource<int>(0);

        var buildCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                buildCount++;

                final firstValue = first.watch;
                final secondValue = second.watch;

                if (buildCount == 2) {
                  first.notify();
                  second.notify();
                }

                return Text('$firstValue $secondValue');
              },
            ),
          ),
        );

        expect(buildCount, 1);

        first.notify();
        await tester.pump();

        expect(buildCount, 2);
        expect(tester.takeException(), isNull);

        await tester.pump();

        // Two notifications during build #2 should result in one deferred
        // rebuild.
        expect(buildCount, 3);
        expect(tester.takeException(), isNull);
      },
    );

    // =========================================================================
    // CHILD PRESERVATION
    // =========================================================================

    testWidgets(
      'does not rebuild child when only a watched dependency changes',
      (tester) async {
        final source = _TestStateSource<int>(0);

        final childKey = GlobalKey<_BuildCountingChildState>();

        final child = _BuildCountingChild(key: childKey);

        var builderCount = 0;

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              child: child,
              builder: (context, child) {
                builderCount++;

                final value = source.watch;

                return Column(
                  children: [Text('$value'), if (child != null) child],
                );
              },
            ),
          ),
        );

        expect(builderCount, 1);
        expect(childKey.currentState!.buildCount, 1);

        source.value = 1;
        await tester.pump();

        expect(builderCount, 2);

        // WatchBuilder rebuilt, but the preserved child did not.
        expect(childKey.currentState!.buildCount, 1);
      },
    );

    // =========================================================================
    // DISPOSAL
    // =========================================================================

    testWidgets('removes all dependency subscriptions when disposed', (
      tester,
    ) async {
      final first = _TestStateSource<int>(0);
      final second = _TestStateSource<int>(0);

      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;

              final firstValue = first.watch;
              final secondValue = second.watch;

              return Text('$firstValue $secondValue');
            },
          ),
        ),
      );

      expect(first.listenerCount, 1);
      expect(second.listenerCount, 1);

      await tester.pumpWidget(const SizedBox());

      expect(first.listenerCount, 0);
      expect(second.listenerCount, 0);

      final disposedBuildCount = buildCount;

      first.notify();
      second.notify();

      await tester.pump();

      expect(buildCount, disposedBuildCount);
    });

    testWidgets('does not react to dependency notifications after disposal', (
      tester,
    ) async {
      final source = _TestStateSource<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              buildCount++;
              return Text('${source.watch}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      await tester.pumpWidget(const SizedBox());

      expect(source.listenerCount, 0);

      for (var index = 0; index < 5; index++) {
        source.notify();
      }

      await tester.pump();

      expect(buildCount, 1);
    });

    // =========================================================================
    // INVALID USAGE
    // =========================================================================

    testWidgets('asserts when builder does not watch any state source', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          WatchBuilder(
            builder: (context, child) {
              return const SizedBox();
            },
          ),
        ),
      );

      final exception = tester.takeException();

      expect(exception, isNotNull);
      expect(exception.toString(), contains('WatchBuilder'));
      expect(
        exception.toString(),
        contains('at least one watched state source'),
      );
    });

    // =========================================================================
    // DIAGNOSTICS
    // =========================================================================

    testWidgets('debugFillProperties exposes builder and child', (
      tester,
    ) async {
      const child = SizedBox(key: Key('diagnostic-child'));

      final diagnostics = DiagnosticPropertiesBuilder();

      WatchBuilder(
        builder: (context, child) => const SizedBox(),
        child: child,
      ).debugFillProperties(diagnostics);

      final description = diagnostics.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(description.any((value) => value.contains('builder')), isTrue);

      expect(description.any((value) => value.contains('child')), isTrue);
    });

    // =========================================================================
    // EXCEPTION SAFETY
    // =========================================================================

    testWidgets(
      'a builder exception does not prevent a later valid WatchBuilder '
      'from collecting dependencies',
      (tester) async {
        final source = _TestStateSource<int>(10);

        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                throw StateError('builder failed');
              },
            ),
          ),
        );

        final exception = tester.takeException();

        expect(exception, isNotNull);

        // Replace the failing builder with a valid one while reusing the
        // widget position.
        await tester.pumpWidget(
          wrap(
            WatchBuilder(
              builder: (context, child) {
                return Text('${source.watch}');
              },
            ),
          ),
        );

        expect(find.text('10'), findsOneWidget);
        expect(source.listenerCount, 1);

        source.value = 20;
        await tester.pump();

        expect(find.text('20'), findsOneWidget);
      },
    );
  });
}

// =============================================================================
// TEST HELPERS
// =============================================================================

class _TestStateSource<T> implements StateListenable<T> {
  _TestStateSource(this._value);

  T _value;

  final List<VoidCallback> _listeners = <VoidCallback>[];

  int get listenerCount => _listeners.length;

  @override
  T get state => _value;

  set value(T value) {
    _value = value;
    notify();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notify() {
    final listeners = List<VoidCallback>.of(_listeners);

    for (final listener in listeners) {
      listener();
    }
  }
}

class _RebuildParent extends StatefulWidget {
  const _RebuildParent({required this.builder, super.key});

  final Widget Function() builder;

  @override
  State<_RebuildParent> createState() => _RebuildParentState();
}

class _RebuildParentState extends State<_RebuildParent> {
  void rebuildParent() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder();
  }
}

class _BuildCountingChild extends StatefulWidget {
  const _BuildCountingChild({super.key});

  @override
  State<_BuildCountingChild> createState() => _BuildCountingChildState();
}

class _BuildCountingChildState extends State<_BuildCountingChild> {
  int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    buildCount++;

    return const SizedBox(key: Key('counting-child'));
  }
}

String firstOf(Finder finder, WidgetTester tester) {
  final text = tester.widget<Text>(finder);

  return text.data!;
}
