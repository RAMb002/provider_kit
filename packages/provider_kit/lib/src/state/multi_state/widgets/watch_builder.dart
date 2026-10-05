part of '../multi_state.dart';

/// {@template provider_kit.watch_builder}
/// A widget that automatically rebuilds when any
/// [StateValueListenable] accessed through `.watch` changes.
/// It provides a simple way to listen to multiple state sources
/// without explicitly declaring them.
///
/// ```dart
/// WatchBuilder(
///   builder: (context, child) {
///     final count = countField.watch;
///     final user = userProvider.watch;
///
///     return Text('$count ${user.name}');
///   },
/// )
/// ```
///
/// For cases where you want to combine multiple state sources into a single
/// value or state, use [MultiStateBuilder] and declare the providers explicitly.
///
/// Dependencies are updated automatically when the values used by the
/// builder change, so conditional state can also be handled naturally.
///
/// ```dart
/// WatchBuilder(
///   builder: (context, child) {
///     final isLoggedIn = authField.watch;
///
///     if (!isLoggedIn) {
///       return const LoginView();
///     }
///
///     final user = userField.watch;
///
///     return Text(user.name);
///   },
/// )
/// ```
///
/// In this example, `userField` is only listened to while the user is logged
/// in.
///
/// At least one [StateValueListenable] must be accessed through `.watch`
/// inside [builder].
/// {@endtemplate}
class WatchBuilder extends StatefulWidget {
  /// {@macro provider_kit.watch_builder}
  const WatchBuilder({super.key, required this.builder, this.child});

  /// Builds the widget and discovers its state dependencies.
  ///
  /// Access [StateValueListenable] values through `.watch` inside this
  /// callback.
  ///
  /// Every watched state source becomes a dependency of this widget.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// An optional widget passed to [builder].
  ///
  /// This widget is not rebuilt when a watched dependency changes unless its
  /// parent rebuilds it.
  final Widget? child;

  @override
  State<WatchBuilder> createState() => _WatchBuilderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, Widget? child)
        >.has('builder', builder),
      )
      ..add(DiagnosticsProperty<Widget?>('child', child));
  }
}

/// State implementation for [WatchBuilder].
///
/// The builder itself is executed inside the dependency collector. The
/// collected dependencies are then synchronized with the current
/// subscriptions.
///
/// When any subscribed dependency changes, the widget schedules a rebuild.
/// The builder is executed again during that rebuild, allowing the dependency
/// set to change dynamically.
class _WatchBuilderState extends State<WatchBuilder> {
  late final _DependencySubscription _dependencySubscription;

  final RebuildScheduler _rebuildScheduler = RebuildScheduler();

  @override
  void initState() {
    super.initState();

    _dependencySubscription = _DependencySubscription(
      onChange: _handleDependencyChange,
    );
  }

  void _handleDependencyChange() {
    if (!mounted) {
      return;
    }

    _rebuildScheduler.request(
      isMounted: () => mounted,
      rebuild: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _DependencyCollection<Widget> collection =
        _DependencyTracker.collect<Widget>(
          () => widget.builder(context, widget.child),
          widgetName: 'WatchBuilder',
        );

    _dependencySubscription.sync(collection.dependencies);

    return collection.value;
  }

  @override
  void dispose() {
    _dependencySubscription.dispose();
    super.dispose();
  }
}
