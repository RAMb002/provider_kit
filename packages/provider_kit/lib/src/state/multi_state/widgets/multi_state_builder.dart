part of '../multi_state.dart';

/// {@template provider_kit.multi_state_builder}
/// A widget that rebuilds its UI based on the combined state returned by
/// [providers].
/// Use the [providers] callback to declare the providers required by this
/// widget. Access their state through `.watch`.
///
/// The value returned by [providers] becomes the combined state passed to
/// [builder] and [rebuildWhen].
/// The combined state can be any Dart type, including a record, list, or
/// custom object.
///
/// - **[providers]** — Builds the combined state from one or more providers.
/// - **[builder]** — Builds the widget tree from the current combined state.
/// - **[rebuildWhen]** — Determines whether the widget should rebuild when the combined state changes.
/// - **[child]** —  An optional widget that does not depend on the combined state.
/// This widget is preserved when the builder rebuilds.
///
/// ### Usage
///
/// A record can be used when you want named values:
///
/// ```dart
/// MultiStateBuilder(
///   providers: () => (
///     user: userProvider.watch,
///     loading: loadingField.watch,
///   ),
///   builder: (context, state, child) {
///     return Column(
///       children: [
///         Text(state.user.name),
///         if (state.loading)
///           const CircularProgressIndicator(),
///         child!,
///       ],
///     );
///   },
///   child: const MyFooter(),
/// );
/// ```
///
/// A list can be used when working with multiple providers of the same type:
///
/// ```dart
/// MultiStateBuilder(
///   providers: () => mutations
///       .map((mutation) => mutation.watch)
///       .toList(),
///   builder: (context, state, child) {
///     final isLoading = state.any((value) => value.isLoading);
///
///     return isLoading
///         ? const CircularProgressIndicator()
///         : const YourWidget();
///   },
///   child: const MyFooter(),
/// );
/// ```
///
/// A custom object can be used when you want a named combined state type:
///
/// ```dart
/// MultiStateBuilder(
///   providers: () => CombinedState(
///     user: userProvider.watch,
///     loading: loadingField.watch,
///   ),
///   builder: (context, state, child) {
///     return Text(state.user.name);
///   },
/// );
/// ```
/// {@endtemplate}
class MultiStateBuilder<T> extends MultiStateBuilderBase<T> {
  /// {@macro provider_kit.multi_state_builder}
  const MultiStateBuilder({
    super.key,
    required super.providers,
    required this.builder,
    super.rebuildWhen,
    super.child,
  });

  /// {@template provider_kit.multi_state.builder_param}
  /// Builds the widget tree using the current combined state.
  ///
  /// The [state] is the value returned by [providers].
  ///
  /// The [child] is an optional widget passed to [builder].
  /// It can be used for a subtree that does not depend on the combined state.
  /// {@endtemplate}
  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) {
    return builder(context, state, child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder),
    );
  }
}

/// Base class for multi-state builders.
///
/// Provides the common builder configuration used by [MultiStateBuilder]
/// and other multi-state builder variants such as `MultiViewStateBuilder`.
abstract class MultiStateBuilderBase<T> extends StatefulWidget {
  const MultiStateBuilderBase({
    super.key,
    required this.providers,
    this.rebuildWhen,
    this.child,
  });

  /// {@macro provider_kit.multi_state.provider_param}
  ///
  /// The returned value becomes the combined state passed to [builder] and
  /// [rebuildWhen].
  final MultiStateProviders<T> providers;

  /// {@template provider_kit.multi_state.rebuild_when_param}
  /// Determines whether [builder] should be called when the combined state
  /// changes.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [providers].
  ///
  /// When omitted, ProviderKit uses the combined state's `!=` comparison to
  /// determine whether the state has changed.
  /// {@endtemplate}
  final RebuildWhen<T>? rebuildWhen;

  /// {@template provider_kit.multi_state_builder.child_param}
  /// An optional widget that does not depend on the combined state.
  /// This widget is preserved when the builder rebuilds.
  /// {@endtemplate}
  final Widget? child;

  /// Builds the widget tree from the current combined state.
  /// Implemented by concrete builder widgets to provide their public
  /// builder behavior.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<MultiStateBuilderBase<T>> createState() =>
      _MultiStateBuilderBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
      )
      ..add(ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen))
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}

class _MultiStateBuilderBaseState<T> extends State<MultiStateBuilderBase<T>> {
  @override
  Widget build(BuildContext context) {
    return _MultiStateBase<T>(
      providers: widget.providers,
      builder: widget.build,
      rebuildWhen: widget.rebuildWhen,
      widgetName: widget.runtimeType.toString(),
      child: widget.child,
    );
  }
}
