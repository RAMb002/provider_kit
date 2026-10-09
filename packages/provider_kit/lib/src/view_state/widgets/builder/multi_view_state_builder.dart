part of 'view_state_builder.dart';

/// Private implementation of [ViewStateBuilder.multi].
class _MultiViewStateBuilder<T> extends MultiViewStateBuilderBase<T> {
  const _MultiViewStateBuilder({
    super.key,
    required super.providers,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.rebuildWhen,
    super.isSliver,
  });
}

/// Base class for multi-provider [ViewStateBuilder] implementations.
///
/// Provides the configuration and behavior shared by multi-provider
/// ViewState builders.
abstract class MultiViewStateBuilderBase<T> extends ViewStateBuilder<T> {
  const MultiViewStateBuilderBase({
    super.key,
    required this.providers,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    this.rebuildWhen,
    super.isSliver = false,
  }) : super.base();

  /// {@macro provider_kit.multi_view_state.provider_param}
  final MultiStateProviders<T> providers;

  /// {@template provider_kit.multi_view_state_builder.rebuild_when}
  /// Determines whether the widget should rebuild when the combined view state
  /// changes.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [providers].
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
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has(
          'providers',
          providers,
        ),
      )
      ..add(
        ObjectFlagProperty<RebuildWhen<T>?>.has(
          'rebuildWhen',
          rebuildWhen,
        ),
      );
  }
}

class _MultiViewStateBuilderBaseState<T>
    extends State<MultiViewStateBuilderBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiViewStateBase<T>(
      providers: widget.providers,
      widgetName: widget.debugWidgetName,
      rebuildWhen: widget.rebuildWhen,
      builder: widget._buildState,
    );
  }
}