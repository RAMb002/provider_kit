part of 'async_notifiers.dart';

/// {@template provider_kit.async_view_state_notifier}
/// A common base type for asynchronous notifiers that manage a [ViewState].
///
/// [AsyncViewStateNotifier] defines the shared lifecycle and operations
/// available to asynchronous ViewState notifiers.
///
/// Extend [FutureNotifier] to manage asynchronous operations that produce
/// a single result, or [StreamNotifier] to manage continuous asynchronous
/// updates.
///
/// This class provides the common asynchronous notifier contract without
/// prescribing an execution strategy. Implementations are responsible for
/// providing the behavior of the declared asynchronous operations.
///
/// It also serves as a common type for creating reusable mixins that work
/// with different asynchronous notifier implementations.
///
/// ### Lifecycle
///
/// The [onInitialize] hook is called once after the concrete notifier has
/// finished construction.
///
/// It is scheduled in a microtask to ensure that subclass initialization
/// is complete before the callback executes.
///
/// For ProviderKit's built-in [FutureNotifier] and [StreamNotifier]
/// implementations, this callback executes before the initial asynchronous
/// build begins.
///
/// This hook is useful for initialization that depends on the fully
/// constructed notifier, such as registering listeners or external resources.
///
/// ### Refreshing
///
/// [refresh] requests a refresh using the notifier's current inputs.
///
/// The exact behavior depends on the concrete implementation:
///
/// - [FutureNotifier] reruns its asynchronous build operation.
/// - [StreamNotifier] restarts its stream subscription.
///
/// The returned future represents the relevant refresh operation.
/// Errors from the latest relevant operation can be propagated to the caller.
///
/// ### Rebuilding
///
/// [rebuild] requests a new build using the notifier's latest inputs.
///
/// Use this when an input that determines the notifier's result changes,
/// such as a query, filter, identifier, or configuration value.
///
/// Unlike [refresh], rebuilding indicates that the previous result may
/// no longer correspond to the latest inputs.
///
/// The exact scheduling, state transitions, and handling of previous
/// operations depend on the concrete implementation.
///
/// This method is protected and is primarily intended for notifier
/// implementations and reusable mixins.
///
/// ### Checking operation validity
///
/// [checkStaleness] captures the current validity of an asynchronous
/// operation and returns a callback that reports whether that operation
/// has become outdated.
///
/// For ProviderKit's built-in asynchronous notifiers, a captured operation
/// becomes stale when a refresh, rebuild, or disposal invalidates it.
///
/// Use this to prevent independent asynchronous operations from continuing
/// with outdated results:
///
/// ```dart
/// Future<void> loadNextPage() async {
///   final isStale = checkStaleness();
///
///   final products = await repository.fetchNextPage();
///
///   if (isStale()) return;
///
///   state = DataState([...state.data, ...products]);
/// }
/// ```
///
/// Check the callback after asynchronous gaps, before continuing work or
/// updating state. This does not cancel the underlying asynchronous operation.
///
/// This method is protected and is intended for notifier implementations
/// and reusable mixins.
///
/// {@endtemplate}
abstract class AsyncViewStateNotifier<T> extends ViewStateNotifier<T> {
  /// {@macro provider_kit.async_view_state_notifier}
  ///
  /// [initialState] optionally specifies the initial state.
  /// When omitted, the notifier starts with [LoadingState].
  AsyncViewStateNotifier({ViewState<T>? initialState})
    : super(initialState ?? LoadingState<T>()) {
    scheduleMicrotask(_invokeOnInitialize);
  }

  /// Called once after the concrete notifier has finished construction.
  ///
  /// Override this method to perform synchronous initialization that depends
  /// on the fully constructed notifier, such as registering listeners,
  /// initializing resources, or publishing cached state.
  ///
  /// This callback is scheduled in a microtask, before the initial
  /// asynchronous build of ProviderKit's built-in [FutureNotifier]
  /// and [StreamNotifier] implementations.
  ///
  /// Always call `super.onInitialize()` when overriding to preserve
  /// the initialization chain, including other mixins.
  ///
  /// Example:
  ///
  /// ```dart
  /// @override
  /// void onInitialize() {
  ///   //  Do something here.
  ///
  ///   // Call super.onInitialize() to preserve the initialization chain.
  ///   super.onInitialize();
  /// }
  /// ```
  ///
  /// This callback is intended for synchronous initialization.
  /// Use [refresh] or another explicitly managed asynchronous operation
  /// when asynchronous work is required.
  @protected
  @mustCallSuper
  void onInitialize() {}

  /// Invokes [onInitialize] after construction.
  ///
  /// The callback is skipped if the notifier has been disposed before
  /// the scheduled invocation.
  void _invokeOnInitialize() {
    if (!mounted) return;

    try {
      onInitialize();
    } finally {
      if (mounted) {
        _afterInitialize();
      }
    }
  }

  /// Internal lifecycle hook invoked after [onInitialize] completes.
  ///
  /// Implementations can use this hook to perform framework-managed
  /// initialization that must happen after user initialization.
  void _afterInitialize() {}

  /// Refreshes the notifier using its current inputs.
  ///
  /// The concrete implementation determines how the refresh is performed.
  ///
  /// For [FutureNotifier], this reruns the asynchronous build while
  /// preserving existing data when possible.
  ///
  /// For [StreamNotifier], this restarts the stream subscription while
  /// preserving existing data when possible.
  ///
  /// The returned future completes when the relevant refresh operation
  /// completes. Errors from the current relevant operation can be
  /// propagated with their original stack traces.
  ///
  /// Calling this method after disposal has no effect in ProviderKit's
  /// built-in implementations.
  Future<void> refresh();

  /// Rebuilds the notifier using its latest inputs.
  ///
  /// Use this when an input that determines the notifier's result changes.
  ///
  /// Unlike [refresh], a rebuild can invalidate the previous result because
  /// it may no longer correspond to the latest inputs.
  ///
  /// The concrete implementation determines how the previous result
  /// is handled and how the replacement operation is scheduled.
  ///
  /// ProviderKit's built-in implementations can coalesce pending rebuild
  /// requests and ensure that outdated operations cannot update the current
  /// state.
  ///
  /// This method is protected and is intended for use by notifier
  /// implementations and reusable mixins.
  @protected
  Future<void> rebuild();

  /// Captures the current validity of an asynchronous operation.
  ///
  /// Returns a callback that reports whether the captured operation
  /// has become outdated.
  ///
  /// For ProviderKit's built-in implementations, the callback returns
  /// `true` after a refresh, rebuild, or disposal invalidates the operation.
  ///
  /// Capture the callback before starting asynchronous work and check it
  /// after asynchronous gaps, before continuing work or updating state.
  ///
  /// This does not cancel the underlying asynchronous operation.
  ///
  /// This method is protected and is intended for use by notifier
  /// implementations and reusable mixins.
  ///
  /// Example:
  ///
  /// ```dart
  /// Future<void> loadNextPage() async {
  ///   final isStale = checkStaleness();
  ///
  ///   final products = await repository.fetchNextPage();
  ///
  ///   if (isStale()) return;
  ///
  ///   state = DataState([...state.data, ...products]);
  /// }
  /// ```
  @protected
  bool Function() checkStaleness();
}
