part of 'view_state_builder.dart';

/// Base class for single-provider [ViewStateBuilder] implementations.
///
/// Provides the provider configuration and delegates state listening to
/// [StateBuilder].
abstract class ViewStateBuilderBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateBuilder<T> {
  const ViewStateBuilderBase({
    super.key,
    this.provider,
    this.rebuildWhen,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.isSliver = false,
  }) : super.base();

  /// {@macro provider_kit.view_state_widget.provider}
  final P? provider;

  /// {@template provider_kit.view_state_builder.rebuild_when}
  /// Determines whether the widget should rebuild when the view state changes.
  ///
  /// The callback receives the previous and current view states.
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final RebuildWhen<ViewState<T>>? rebuildWhen;

  Widget _buildState(BuildContext context, ViewState<T> state, Widget? child) {
    return ViewStateWidgetUtils.buildStateWidget<P, T>(
      context,
      provider,
      state,
      initialBuilder,
      dataBuilder,
      errorBuilder,
      loadingBuilder,
      emptyBuilder,
      isSliver,
    );
  }

  @override
  State<ViewStateBuilderBase<P, T>> createState() =>
      _ViewStateBuilderBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<P?>('provider', provider, defaultValue: null))
      ..add(
        ObjectFlagProperty<RebuildWhen<ViewState<T>>?>.has(
          'rebuildWhen',
          rebuildWhen,
        ),
      );
  }
}

/// Delegates single-provider state listening to [StateBuilder].
class _ViewStateBuilderBaseState<P extends ViewStateNotifier<T>, T>
    extends State<ViewStateBuilderBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    if (provider != null) {
      return StateBuilder<ViewState<T>>(
        provider: provider,
        rebuildWhen: widget.rebuildWhen,
        builder: widget._buildState,
      );
    }

    return StateBuilder.of<P, ViewState<T>>(
      rebuildWhen: widget.rebuildWhen,
      builder: widget._buildState,
    );
  }
}
