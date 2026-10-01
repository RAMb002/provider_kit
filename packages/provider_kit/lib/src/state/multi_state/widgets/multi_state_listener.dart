part of '../multi_state.dart';

/// {@template provider_kit.multi_state_listener}
/// A widget that listens to multiple providers and exposes
/// their states as a single combined state.
/// Use the [providers] callback to declare the providers required by
/// this widget. Access their state through `.watch`.
///
/// The value returned by [providers] becomes the combined state passed to
/// [listener] and [listenWhen]. The combined state can be any Dart type,
/// including a record, list, or custom object.
///
/// - **[providers]** — Builds the combined state from one or more providers..
/// - **[listener]** — Handles changes to the current combined state.
/// - **[listenWhen]** — Determines whether the listener should be called when the combined state changes.
/// - **[callListenerOnInit]** — Determines whether the listener should be called after initialization.
/// - **[child]** — An optional widget that is preserved when the listener is triggered.
///
/// ### Usage
///
/// A record can be used when you want named values:
///
/// ```dart
/// MultiStateListener(
///   providers: () => (
///     user: userProvider.watch,
///     loading: loadingField.watch,
///     save: saveMutation.watch,
///   ),
///   listener: (context, state) {
///     // state.user
///     // state.loading
///     // state.save
///   },
///   child: const MyPage(),
/// );
/// ```
///
/// A list can be used when working with multiple providers of the same type:
///
/// ```dart
/// MultiStateListener(
///   providers: () => mutations
///       .map((mutation) => mutation.watch)
///       .toList(),
///   listener: (context, state) {
///     if (state.any((value) => value.isLoading)) {
///       // Handle loading
///     }
///   },
///   child: const MyPage(),
/// );
/// ```
///
/// A custom object can be used when you want a named combined state type:
///
/// ```dart
/// MultiStateListener(
///   providers: () => CombinedState(
///     user: userProvider.watch,
///     loading: loadingField.watch,
///   ),
///   listener: (context, state) {
///     // Handle the combined state
///   },
///   child: const MyPage(),
/// );
/// ```
/// {@endtemplate}
class MultiStateListener<T> extends MultiStateListenerBase<T> {
  /// {@macro provider_kit.multi_state_listener}
  const MultiStateListener({
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
/// Provides the public configuration shared by [MultiStateListener]
///
/// The actual dependency tracking, state collection, subscriptions,
/// equality checks, and listener invocation are handled by the internal
/// [_MultiStateBase] implementation.
abstract class MultiStateListenerBase<T> extends SingleChildStatefulWidget {
  /// {@macro provider_kit.multi_state_listener}
  const MultiStateListenerBase({
    super.key,
    required this.providers,
    this.listenWhen,
    this.callListenerOnInit = false,
    super.child,
  }) : _onDependenciesUpdate = null;

  /// {@template provider_kit.multi_state.internal_constructor}
  /// Internal constructor used by specialized widgets in this library.
  /// This constructor is only available to specialized widgets within this
  /// library.
  /// {@endtemplate}
  const MultiStateListenerBase._internal({
    super.key,
    required this.providers,
    this.listenWhen,
    this.callListenerOnInit = false,
    required this._onDependenciesUpdate,
    super.child,
  });

  /// {@template provider_kit.multi_state.provider_param}
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

  /// {@template provider_kit.multi_state.listen_when_param}
  /// Determines whether [listener] should be called when the combined state
  /// changes.
  /// The callback receives the previous and current combined states returned
  /// by [providers].
  ///
  /// When omitted, ProviderKit uses its default equality comparison, including
  /// deep comparison for collections.
  /// {@endtemplate}
  final ListenWhen<T>? listenWhen;

  /// {@template provider_kit.multi_state.call_listener_on_init_param}
  /// Whether to call [listener] once after the widget is initialized.
  /// The callback is invoked after the first frame.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  final bool callListenerOnInit;

  /// {@template provider_kit.multi_state.on_dependencies_update_param}
  /// Internal callback used by specialized widgets that need access to the
  /// currently collected dependency objects.
  ///
  /// This is intentionally private and is never exposed through the public
  /// widget constructors.
  /// {@endtemplate}
  final _DependenciesUpdateCallback? _onDependenciesUpdate;

  /// Handles a listener notification for the current combined state.
  ///
  /// Concrete listener widgets implement this method to provide their
  /// listener behavior.
  void onStateChange(BuildContext context, T state);

  @override
  State<MultiStateListenerBase<T>> createState() =>
      _MultiStateListenerBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
      )
      ..add(ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen))
      ..add(
        DiagnosticsProperty<bool>(
          'callListenerOnInit',
          callListenerOnInit,
          defaultValue: false,
        ),
      );
  }
}

/// State wrapper that connects [MultiStateListenerBase] to the shared
/// [_MultiStateBase] implementation.
///
/// This state intentionally contains no dependency or listener logic.
/// Its only responsibility is translating the public listener API into the
/// configuration expected by [_MultiStateBase].
class _MultiStateListenerBaseState<T>
    extends SingleChildState<MultiStateListenerBase<T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return _MultiStateBase<T>(
      providers: widget.providers,
      listener: widget.onStateChange,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      widgetName: widget.runtimeType.toString(),
      onDependenciesUpdate: widget._onDependenciesUpdate,
      child: child,
    );
  }
}
