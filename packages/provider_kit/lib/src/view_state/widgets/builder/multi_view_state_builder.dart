part of 'view_state_builder.dart';

/// Private implementation of [ViewStateBuilder.multi].
class _MultiViewStateBuilder<T> extends MultiViewStateBuilderBase<T> {
  const _MultiViewStateBuilder({
    super.key,
    required super.listenables,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.rebuildWhen,
    super.isSliver,
    super.child,
  });
}

/// Base class for multi-listenable [ViewStateBuilder] implementations.
///
/// Provides the configuration and behavior shared by multi-listenable
/// ViewState builders.
abstract class MultiViewStateBuilderBase<T> extends ViewStateBuilder<T> {
  const MultiViewStateBuilderBase({
    super.key,
    required this.listenables,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    this.rebuildWhen,
    super.isSliver = false,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.multi_view_state.listenables_param}
  final MultiStateListenables<T> listenables;

  /// {@template provider_kit.multi_view_state_builder.rebuild_when}
  /// Determines whether the widget should rebuild when the combined view state
  /// changes.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [listenables].
  ///
  /// When omitted, the widget rebuilds whenever ProviderKit detects a change
  /// in the combined state.
  /// {@endtemplate}
  final RebuildWhen<T>? rebuildWhen;

  @override
  String get debugWidgetName => 'ViewStateBuilder<$T>.multi';

  @override
  State<MultiViewStateBuilderBase<T>> createState() =>
      _MultiViewStateBuilderBaseState<T>();

  Widget _buildState(
    BuildContext context,
    T state,
    MultiViewStateAggregate aggregate,
    Widget? child,
  ) {
    return MultiViewStateUtils.handleBuilder(
      state,
      aggregate,
      errorBuilder,
      context,
      isSliver,
      initialBuilder,
      loadingBuilder,
      emptyBuilder,
      dataBuilder,
      child
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        ObjectFlagProperty<MultiStateListenables<T>>.has(
          'listenables',
          listenables,
        ),
      )
      ..add(
        ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen),
      );
  }
}

class _MultiViewStateBuilderBaseState<T>
    extends State<MultiViewStateBuilderBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiViewStateEngine<T>(
      listenables: widget.listenables,
      widgetName: widget.debugWidgetName,
      rebuildWhen: widget.rebuildWhen,
      builder: widget._buildState,
      child: widget.child,
    );
  }
}
