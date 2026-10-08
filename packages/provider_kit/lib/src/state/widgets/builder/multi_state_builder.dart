part of 'state_builder.dart';

class _MultiStateBuilder<T> extends MultiStateBuilderBase<T> {
  const _MultiStateBuilder({
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
/// Provides the shared public configuration for multi-provider
/// [StateBuilder] implementations.
///
/// The actual dependency tracking, state collection, subscriptions,
/// equality checks, and rebuild scheduling are handled by the internal
/// [MultiStateBase] implementation.
abstract class MultiStateBuilderBase<T> extends StateBuilder<T> {
  const MultiStateBuilderBase({
    super.key,
    required this.providers,
    super.rebuildWhen,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.multi_state.providers_param}
  ///
  /// The returned value becomes the combined state passed to [builder] and
  /// [rebuildWhen].
  final MultiStateProviders<T> providers;

  /// Builds the widget tree from the current combined state.
  Widget build(BuildContext context, T state, Widget? child);

  /// Name used by the shared multi-state implementation for diagnostics and
  /// error messages.
  @override
  String get debugWidgetName => 'StateBuilder<$T>.multi';

  @override
  State<MultiStateBuilderBase<T>> createState() =>
      _MultiStateBuilderBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
    );
  }
}

class _MultiStateBuilderBaseState<T> extends State<MultiStateBuilderBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiStateBase<T>(
      providers: widget.providers,
      builder: widget.build,
      rebuildWhen: widget.rebuildWhen,
      widgetName: widget.debugWidgetName,
      child: widget.child,
    );
  }
}
