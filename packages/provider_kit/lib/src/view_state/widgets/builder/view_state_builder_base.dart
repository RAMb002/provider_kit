part of 'view_state_builder.dart';

/// Base class for single-view-state-notifier [ViewStateBuilder]
/// implementations.
///
/// Stores the listenable configuration and delegates state tracking to
/// [StateEngine].
abstract class ViewStateBuilderBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateBuilder<T> {
  const ViewStateBuilderBase({
    super.key,
    this.listenable,
    this.rebuildWhen,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.isSliver = false,
  }) : super.base();

  /// {@macro provider_kit.view_state_widget.listenable}
  final P? listenable;

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
      listenable,
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
      ..add(DiagnosticsProperty<P?>('listenable', listenable, defaultValue: null))
      ..add(
        ObjectFlagProperty<RebuildWhen<ViewState<T>>?>.has(
          'rebuildWhen',
          rebuildWhen,
        ),
      );
  }
}

/// Delegates single-listenable state tracking to [StateEngine].
class _ViewStateBuilderBaseState<P extends ViewStateNotifier<T>, T>
    extends State<ViewStateBuilderBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    return StateEngine<P, ViewState<T>>(
      listenable: widget.listenable,
      rebuildWhen: widget.rebuildWhen,
      builder: widget._buildState,
      widgetName: widget.debugWidgetName,
    );
  }
}
