part of 'view_state_consumer.dart';

/// Private implementation of [ViewStateConsumer.multi].
class _MultiViewStateConsumer<T> extends MultiViewStateConsumerBase<T> {
  const _MultiViewStateConsumer({
    super.key,
    required super.providers,
    required super.dataBuilder,
    super.initialBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.isSliver,
  });
}


/// Base class for multi-provider [ViewStateConsumer] implementations.
///
/// Provides the configuration and behavior shared by multi-provider
/// ViewState consumers.
abstract class MultiViewStateConsumerBase<T> extends ViewStateConsumer<T> {
  const MultiViewStateConsumerBase({
    super.key,
    required this.providers,
    required super.dataBuilder,
    super.initialBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    this.rebuildWhen,
    this.listenWhen,
    super.callListenerOnInit = false,
    super.isSliver = false,
  }) : super.base();

  /// {@macro provider_kit.multi_view_state.provider_param}
  final MultiStateProviders<T> providers;

  /// {@macro provider_kit.multi_view_state_builder.rebuild_when}
  final RebuildWhen<T>? rebuildWhen;

  /// {@macro provider_kit.multi_view_state_listener.listen_when}
  final ListenWhen<T>? listenWhen;

  @override
  String get debugWidgetName => 'ViewStateConsumer<$T>.multi';

  @override
  State<MultiViewStateConsumerBase<T>> createState() =>
      _MultiViewStateConsumerBaseState<T>();

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

  void _handleStateChange(
    BuildContext context,
    T state,
    MultiViewStateAggregate aggregate,
  ) {
    MultiViewStateUtils.handleListener(
      state,
      aggregate,
      errorStateListener,
      initialStateListener,
      loadingStateListener,
      emptyStateListener,
      dataStateListener,
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
      )
      ..add(
        ObjectFlagProperty<ListenWhen<T>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}


class _MultiViewStateConsumerBaseState<T>
    extends State<MultiViewStateConsumerBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiViewStateBase<T>(
      providers: widget.providers,
      widgetName: widget.debugWidgetName,
      rebuildWhen: widget.rebuildWhen,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      builder: widget._buildState,
      listener: widget._handleStateChange,
    );
  }
}