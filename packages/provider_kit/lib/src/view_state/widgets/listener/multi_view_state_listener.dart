part of 'view_state_listener.dart';

/// Private implementation of [ViewStateListener.multi].
///
/// Provides the concrete multi-provider listener configuration.
class _MultiViewStateListener<T> extends MultiViewStateListenerBase<T> {
  const _MultiViewStateListener({
    super.key,
    required super.providers,
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

/// Base class for multi-provider [ViewStateListener] implementations.
///
/// Provides the configuration and behavior shared by multi-provider
/// ViewState listeners.
abstract class MultiViewStateListenerBase<T> extends ViewStateListener<T> {
  const MultiViewStateListenerBase({
    super.key,
    required this.providers,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    this.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.multi_view_state.provider_param}
  /// Builds a combined state from one or more watched [ViewStateNotifier]
  /// providers.
  /// Providers can be watched using `.watch`. Watched providers are
  /// automatically tracked, so the widget updates when any of their states
  /// change.
  ///
  /// Each provider accessed through `.watch` must be a [ViewStateNotifier] or
  /// one of its subclasses, such as [AsyncViewStateNotifier].
  ///
  /// ```dart
  /// providers: () => (
  ///   user: userProvider.watch,
  ///   profile: profileProvider.watch,
  ///   settings: settingsProvider.watch,
  /// )
  /// ```
  ///
  /// The return type can be any Dart type, including a record, list, or custom
  /// object.
  /// {@endtemplate}
  ///
  /// The returned value becomes the combined state passed to [dataStateListener] and
  /// [listenWhen].
  final MultiStateProviders<T> providers;

  /// {@template provider_kit.multi_view_state_listener.listen_when}
  /// Determines whether the listener should be called when the combined view
  /// state changes.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [providers].
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final ListenWhen<T>? listenWhen;

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
  String get debugWidgetName => 'ViewStateListener<$T>.multi';

  @override
  State<MultiViewStateListenerBase<T>> createState() =>
      _MultiViewStateListenerBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
      )
      ..add(ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen));
  }
}

class _MultiViewStateListenerBaseState<T>
    extends SingleChildState<MultiViewStateListenerBase<T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return MultiViewStateBase<T>(
      providers: widget.providers,
      widgetName: widget.debugWidgetName,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget._handleStateChange,
      child: child,
    );
  }
}
