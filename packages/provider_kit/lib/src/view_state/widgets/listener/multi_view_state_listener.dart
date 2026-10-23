part of 'view_state_listener.dart';

/// Private implementation of [ViewStateListener.multi].
///
/// Provides the concrete multi-view-state listener configuration.
class _MultiViewStateListener<T> extends MultiViewStateListenerBase<T> {
  const _MultiViewStateListener({
    super.key,
    required super.listenables,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });
}

/// Base class for multi-view-state [ViewStateListener] implementations.
///
/// Provides the configuration and behavior shared by these listeners.
abstract class MultiViewStateListenerBase<T> extends ViewStateListener<T> {
  const MultiViewStateListenerBase({
    super.key,
    required this.listenables,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    this.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.multi_view_state.listenables_param}
  /// Builds a combined state by reading values from one or more
  /// [ViewStateNotifier] instances through `.watch`. ProviderKit automatically
  /// tracks the watched notifiers and updates the widget when their states change.
  ///
  /// Each notifier accessed through `.watch` must be a [ViewStateNotifier] or
  /// one of its subclasses, such as [FutureNotifier].
  ///
  /// ```dart
  /// listenables: () => (
  ///   user: userNotifier.watch,
  ///   profile: profileNotifier.watch,
  ///   settings: settingsNotifier.watch,
  /// )
  /// ```
  ///
  /// The return type can be any Dart type, including a record, list, or custom
  /// object.
  /// {@endtemplate}
  ///
  /// The returned value becomes the combined state passed to [dataStateListener] and
  /// [listenWhen].
  final MultiStateListenables<T> listenables;

  /// {@template provider_kit.multi_view_state_listener.listen_when}
  /// Determines whether the listener should be called when the combined view
  /// state changes.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [listenables].
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final ListenWhen<T>? listenWhen;

  void _handleStateChange(
    BuildContext _,
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
  String get debugWidgetName => 'ViewStateListener<$T>.multi';

  @override
  State<MultiViewStateListenerBase<T>> createState() =>
      _MultiViewStateListenerBaseState<T>();

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
      ..add(ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen));
  }
}

class _MultiViewStateListenerBaseState<T>
    extends SingleChildState<MultiViewStateListenerBase<T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return MultiViewStateEngine<T>(
      listenables: widget.listenables,
      widgetName: widget.debugWidgetName,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget._handleStateChange,
      child: child,
    );
  }
}
