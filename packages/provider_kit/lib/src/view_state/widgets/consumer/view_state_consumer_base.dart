part of 'view_state_consumer.dart';

/// Base class for single-view-state-notifier [ViewStateConsumer]
/// implementations.
///
/// Stores the listenable configuration and delegates state tracking,
/// rebuilding, and listener scheduling to [StateEngine].
abstract class ViewStateConsumerBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateConsumer<T> {
  const ViewStateConsumerBase({
    super.key,
    this.listenable,
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

  /// {@macro provider_kit.view_state_widget.listenable}
  final P? listenable;

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

  void _handleStateChange(BuildContext context, ViewState<T> state) {
    ViewStateWidgetUtils.handleListener<T>(
      state: state,
      context: context,
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
      ..add(
        DiagnosticsProperty<P?>('listenable', listenable, defaultValue: null),
      )
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

/// Delegates single-listenable state tracking, rebuilding, and listener
/// scheduling to [StateEngine].
class _ViewStateConsumerBaseState<P extends ViewStateNotifier<T>, T>
    extends State<ViewStateConsumerBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    return StateEngine<P, ViewState<T>>(
      listenable: widget.listenable,
      rebuildWhen: widget.rebuildWhen,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      builder: widget._buildState,
      listener: widget._handleStateChange,
      widgetName: widget.debugWidgetName,
    );
  }
}
