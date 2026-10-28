part of 'async_notifiers.dart';

/// {@template provider_kit.async_view_state_notifier}
/// A sealed base class that provides shared infrastructure for asynchronous
/// notifiers that expose data through [ViewState].
///
/// [AsyncViewStateNotifier] coordinates asynchronous build operations, protects
/// against outdated operations updating the state, and provides shared state
/// and refresh behavior for [FutureNotifier] and [StreamNotifier].
///
/// This class is sealed and is intended for use as an internal implementation
/// base for ProviderKit's built-in asynchronous notifier types. Extend
/// [FutureNotifier] or [StreamNotifier] to create asynchronous notifiers.
///
/// ### Constructor parameters
///
/// - `initialState`: The initial [ViewState]. Defaults to [LoadingState].
/// - [disableEmptyState]: Whether empty [Iterable] results and stream events
///   should be represented as [DataState] rather than [EmptyState]. Defaults
///   to `false`.
/// - [loadingMessage]: An optional default message for [LoadingState]
///   instances produced by this notifier, including during initialization and rebuilds.
/// - [emptyMessage]: An optional default message for [EmptyState] instances
///   produced by asynchronous build results.
///
/// ### State handling
///
/// Asynchronous notifiers manage loading, data, empty, and error states
/// according to their build results and lifecycle:
///
/// - Successful results can be represented as [DataState].
/// - Empty results can be represented as [EmptyState], unless
///   [disableEmptyState] is `true`.
/// - When usable data is unavailable, a build failure transitions the state
///   to [ErrorState].
/// - When existing data can be preserved, a failure can be reported without
///   replacing that data with [ErrorState].
///
/// ### Error handling
///
/// Errors are handled according to the concrete notifier's lifecycle and
/// whether existing data can be preserved. Errors that replace the current
/// state are represented by [ErrorState]. Errors that occur while preserving
/// existing data are reported through the inherited notifier error-handling
/// mechanism without necessarily changing the current [ViewState].
///
/// The behavior of the returned [Future] depends on the operation and the
/// concrete notifier. A future-based build failure can be propagated to the
/// caller, while errors emitted later by a stream generally cannot be
/// propagated through the [StreamNotifier.refresh] future.
///
/// ### Retry behavior
///
/// When an asynchronous notifier is used with a view-state widget, retry
/// handling follows these rules:
///
/// 1. An explicitly provided [ErrorState.onRetry] callback takes precedence.
/// 2. If [ErrorState.onRetry] is `null`, supported widgets fall back to the
///    notifier's [refresh] method.
///
/// This behavior applies to [ViewStateBuilder], [ViewStateBuilder.multi],
/// [ViewStateListener], [ViewStateListener.multi], [ViewStateConsumer], and
/// [ViewStateConsumer.multi].
///
/// ### Refreshing
///
/// [refresh] refreshes data according to the concrete notifier's
/// implementation:
///
/// - [FutureNotifier] reruns its build workflow. Existing data is preserved
///   while refreshing when available. Otherwise, the notifier can transition
///   to [LoadingState] while loading initial data.
/// - [StreamNotifier] restarts its stream subscription while preserving
///   existing data when available.
///
/// The returned future follows the relevant asynchronous operation. When an
/// operation is superseded, callers waiting for it follow its replacement.
/// Errors from outdated operations are ignored, while errors from the latest
/// relevant operation can be propagated to the caller.
///
/// Refreshing or rebuilding invalidates previously captured staleness checks.
/// These checks prevent outdated asynchronous work from continuing to act on
/// the current state, but do not cancel the underlying work automatically.
///
/// {@endtemplate}
sealed class AsyncViewStateNotifier<T> extends ViewStateNotifier<T> {
  AsyncViewStateNotifier({
    ViewState<T>? initialState,
    this.disableEmptyState = false,
    this.loadingMessage,
    this.emptyMessage,
  }) : super(initialState ?? LoadingState<T>(loadingMessage)) {
    _buildManager.bindOperationInvalidator(_invalidateStateScopes);
    scheduleMicrotask(_startInitialBuild);
  }

  /// Whether empty results should be represented as [DataState].
  @protected
  final bool disableEmptyState;

  /// The default message for loading states produced by this notifier,
  /// including the initial state and subsequent loading states during
  /// rebuilds.
  ///
  /// Subclasses can reuse this value when manually creating a
  /// [LoadingState].
  @protected
  final String? loadingMessage;

  /// The configured message for empty asynchronous results.
  ///
  /// Subclasses can reuse this value when manually setting an empty state.
  @protected
  final String? emptyMessage;

  final AsyncBuildManager _buildManager = AsyncBuildManager();

  /// A unique Zone key for state assignments made during a managed build.
  final Object _buildZoneKey = Object();

  /// Tracks the validity of independent asynchronous operations.
  final GenerationGuard _generationGuard = GenerationGuard();

  /// Runs the initial build after synchronous subclass initialization finishes.
  void _startInitialBuild() {
    _buildManager.startInitial(_runBuild).ignore();
  }

  /// Runs the subclass's build lifecycle in an isolated Zone.
  ///
  /// Framework-managed state transitions must not inherit a generation token
  /// from an enclosing build or asynchronous callback.
  Future<void> _runBuild(int token, AsyncBuildReason reason) {
    return runZoned<Future<void>>(
      () => _executeBuild(token, reason),
      zoneValues: {_buildZoneKey: null},
    );
  }

  /// Implements the lifecycle specific to a Future- or Stream-based notifier.
  Future<void> _executeBuild(int token, AsyncBuildReason reason);

  /// Whether [token] still belongs to the active build generation.
  bool _isCurrentBuild(int token) {
    return mounted && _buildManager.isCurrent(token);
  }

  /// Whether [value] represents an empty result under the configured policy.
  bool _isEmptyState(Object? value) {
    return !disableEmptyState && value is Iterable && value.isEmpty;
  }

  /// Schedules a rebuild using the latest inputs.
  ///
  /// Multiple requests made before a pending rebuild starts are coalesced
  /// into a single operation using the latest inputs.
  ///
  /// If the operation being awaited becomes outdated, the returned future
  /// follows its replacement until the latest relevant operation completes.
  ///
  /// Errors from outdated operations are ignored. If the latest relevant
  /// operation fails, the returned future propagates its original error
  /// and stack trace.
  @protected
  @nonVirtual
  Future<void> rebuild() {
    final operation = _buildManager.rebuild(_runBuild);

    // Callers may await the original future to observe its error.
    operation.ignore();

    return operation;
  }

  /// Refreshes data using the current inputs.
  ///
  /// If a rebuild is pending or a valid build is running, waits for that
  /// operation. If it becomes outdated while waiting, follows its
  /// replacement. Otherwise, starts a new refresh operation.
  ///
  /// Existing data remains available while refreshing. If the latest
  /// relevant operation fails, the returned future propagates its original
  /// error and stack trace, even when existing data is preserved.
  @mustCallSuper
  Future<void> refresh() {
    if (!mounted) return Future<void>.value();

    final operation = _buildManager.refresh(_runBuild);

    // Also support callers that intentionally do not await refresh.
    operation.ignore();

    return operation;
  }

  /// Publishes a state only when its managed build is still current.
  ///
  /// The generation token is cleared during listener notification so callbacks
  /// do not accidentally inherit the generation of the originating build.
  @override
  @nonVirtual
  set state(ViewState<T> newState) {
    final token = Zone.current[_buildZoneKey];

    if (token is! int) {
      super.state = newState;
      return;
    }

    if (!_isCurrentBuild(token)) return;

    runZoned<void>(
      () => super.state = newState,
      zoneValues: {_buildZoneKey: null},
    );
  }

  /// Returns a callback that checks whether an asynchronous operation
  /// has become outdated.
  ///
  /// Capture the callback before starting work and check it after each
  /// [await], before continuing work or updating state.
  ///
  /// A refresh, rebuild, or disposal can invalidate the captured operation.
  /// This does not cancel in-flight asynchronous work.
  ///
  /// Example:
  ///
  /// ```dart
  /// Future<void> loadNextPage() async {
  ///   final isStale = checkStaleness();
  ///
  ///   final products = await _repository.fetchNextPage();
  ///
  ///   if (isStale()) return;
  ///
  ///   state = DataState([...state.data, ...products]);
  /// }
  /// ```
  @protected
  @nonVirtual
  bool Function() checkStaleness() {
    final generation = _generationGuard.currentGenerationToken;

    return () {
      return !mounted || !_generationGuard.isCurrent(generation);
    };
  }

  /// Invalidates all checks captured before this call.
  void _invalidateStateScopes() {
    _generationGuard.next();
  }

  /// Releases resources owned by a specialized async notifier.
  ///
  /// Subclasses can override this internal hook for resources such as stream
  /// subscriptions. The manager is invalidated before this hook is called.
  void _disposeAsyncResources() {}

  void _onError(Object error, StackTrace stackTrace) {
    if (!mounted) return;

    state = ErrorState<T>(error, stackTrace, onRetry: () => refresh().ignore());
    dispatchError(error, stackTrace);
  }

  @mustCallSuper
  @override
  void dispose() {
    _buildManager.dispose();

    // Keep the existing scope guard and invalidate it during disposal.
    _generationGuard.invalidate();

    _disposeAsyncResources();

    super.dispose();
  }
}
