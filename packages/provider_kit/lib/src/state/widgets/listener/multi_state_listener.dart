part of 'state_listener.dart';

/// Implementation of [StateListener.multi].
///
/// Listens to a combined state produced by multiple providers and invokes
/// the listener when the combined state changes.
class _MultiStateListener<T> extends MultiStateListenerBase<T> {
  const _MultiStateListener({
    super.key,
    required super.providers,
    required this.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

  /// {@template provider_kit.multi_state.listener_param}
  /// Called when the combined state changes and [listenWhen] allows the
  /// change.
  ///
  /// The callback receives the current [BuildContext] and the latest
  /// combined state returned by [providers].
  /// {@endtemplate}
  final ListenerCallback<T> listener;

  @override
  void onStateChange(BuildContext context, T state) {
    listener(context, state);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<ListenerCallback<T>>.has('listener', listener),
    );
  }
}

/// Base class for multi-state listeners.
///
/// Provides the shared public configuration for multi-provider
/// [StateListener] implementations.
///
/// The actual dependency tracking, state collection, subscriptions,
/// equality checks, and listener invocation are handled by the internal
/// [MultiStateEngine] implementation.
abstract class MultiStateListenerBase<T> extends StateListener<T> {
  const MultiStateListenerBase({
    super.key,
    required this.providers,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.multi_state.providers_param}
  /// Builds a combined state from one or more watched providers.
  /// Providers can be watched using `.watch`. Watched providers are
  /// automatically tracked, so the widget updates when any of their states
  /// change.
  ///
  /// ```dart
  /// providers: () => (
  ///   user: userProvider.watch,
  ///   loading: loadingField.watch,
  ///   save: saveMutation.watch,
  /// )
  /// ```
  ///
  /// The return type can be any Dart type, including a record, list, or custom
  /// object.
  /// {@endtemplate}
  ///
  /// The returned value becomes the combined state passed to [listener] and
  /// [listenWhen].
  final MultiStateProviders<T> providers;

  /// Handles a listener notification for the current combined state.
  ///
  /// Concrete listener widgets implement this method to provide their
  /// listener behavior.
  void onStateChange(BuildContext context, T state);

  @override
  String get debugWidgetName => 'StateListener<$T>.multi';

  @override
  State<MultiStateListenerBase<T>> createState() =>
      _MultiStateListenerBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
    );
  }
}

/// State wrapper that connects [MultiStateListenerBase] to the shared
/// [MultiStateEngine] implementation.
///
/// This state intentionally contains no dependency or listener logic.
/// Its only responsibility is translating the public listener API into the
/// configuration expected by [MultiStateEngine].
class _MultiStateListenerBaseState<T>
    extends SingleChildState<MultiStateListenerBase<T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return MultiStateEngine<T>(
      providers: widget.providers,
      listener: widget.onStateChange,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      widgetName: widget.debugWidgetName,
      child: child,
    );
  }
}
