part of 'view_state_consumer.dart';

/// Base class for single-provider [ViewStateConsumer] implementations.
///
/// Provides the provider configuration and delegates state management to
/// [StateConsumer].
abstract class ViewStateConsumerBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateConsumer<T> {
  const ViewStateConsumerBase({
    super.key,
    this.provider,
    this.rebuildWhen,
    this.listenWhen,
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
    super.callListenerOnInit,
    super.isSliver,
  }) : super.base();

  /// {@macro provider_kit.view_state_widget.provider}
  final P? provider;

  /// {@macro provider_kit.view_state_builder.rebuild_when}
  final RebuildWhen<ViewState<T>>? rebuildWhen;

  /// {@macro provider_kit.view_state_listener.listen_when}
  final ListenWhen<ViewState<T>>? listenWhen;

  @override
  State<ViewStateConsumerBase<P, T>> createState() =>
      _ViewStateConsumerBaseState<P, T>();

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

  void _handleStateChange(BuildContext context, ViewState<T> state) {
    ViewStateWidgetUtils.handleListener<T>(
      state: state,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      dataStateListener: dataStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
    );
  }

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
      )
      ..add(
        ObjectFlagProperty<ListenWhen<ViewState<T>>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}

/// Delegates single-provider listening and rebuilding to [StateConsumer].
class _ViewStateConsumerBaseState<P extends ViewStateNotifier<T>, T>
    extends State<ViewStateConsumerBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    if (provider != null) {
      return StateConsumer<ViewState<T>>(
        provider: provider,
        rebuildWhen: widget.rebuildWhen,
        listenWhen: widget.listenWhen,
        callListenerOnInit: widget.callListenerOnInit,
        builder: widget._buildState,
        listener: widget._handleStateChange,
      );
    }

    return StateConsumer.of<P, ViewState<T>>(
      rebuildWhen: widget.rebuildWhen,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      builder: widget._buildState,
      listener: widget._handleStateChange,
    );
  }
}
