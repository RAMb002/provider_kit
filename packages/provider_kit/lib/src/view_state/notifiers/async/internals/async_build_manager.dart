part of '../async_notifiers.dart';

@internal
enum AsyncBuildReason { initial, refresh, rebuild }

/// Coordinates asynchronous build operations and generation tracking.
///
/// State transitions and error handling remain the notifier's responsibility.
@internal
final class AsyncBuildManager {
  final GenerationGuard _generationGuard = GenerationGuard();

  /// Operations whose asynchronous execution has not finished.
  final Set<_AsyncBuildOperation> _runningOperations = {};

  /// The operation currently considered active.
  _AsyncBuildOperation? _activeOperation;

  /// A rebuild scheduled but not yet started.
  _AsyncBuildOperation? _pendingRebuild;

  /// The latest requested operation, retained after completion so waiting
  /// rebuilds and refreshes can follow its replacement when necessary.
  _AsyncBuildOperation? _latestOperation;

  bool _disposed = false;

  VoidCallback? _onInvalidateOperations;

  /// Registers the callback used to invalidate independent async operations.
  void bindOperationInvalidator(VoidCallback callback) {
    _onInvalidateOperations = callback;
  }

  void _invalidateOperations() {
    _onInvalidateOperations?.call();
  }

  /// Whether [token] belongs to the current generation.
  bool isCurrent(int token) {
    return !_disposed && _generationGuard.isCurrent(token);
  }

  /// Starts the initial operation unless current work already represents it.
  Future<void> startInitial(AsyncBuildExecutor execute) {
    if (_disposed) return Future<void>.value();

    final pending = _pendingRebuild;
    if (pending != null) {
      return _waitForLatestOperation(pending);
    }

    final active = _activeOperation;
    if (active != null && _isCurrentOperation(active)) {
      return _waitForLatestOperation(active);
    }

    _invalidateOperations();

    final operation = _startNewOperation(AsyncBuildReason.initial, execute);

    return _waitForLatestOperation(operation);
  }

  /// Invalidates current work and schedules or joins a rebuild.
  ///
  /// Multiple requests made before execution starts share one pending
  /// operation using the newest generation.
  ///
  /// If an operation becomes outdated while this future is waiting, the
  /// future follows its replacement until the latest relevant operation
  /// completes.
  ///
  /// Errors from outdated operations are ignored. Errors from the current
  /// operation are propagated with their original stack traces.
  Future<void> rebuild(AsyncBuildExecutor execute) {
    if (_disposed) return Future<void>.value();

    _invalidateOperations();

    final token = _generationGuard.next();
    final pending = _pendingRebuild;

    if (pending != null) {
      // Reuse the pending operation, but make it represent the latest request.
      pending.token = token;
      _latestOperation = pending;

      _supersedeOutdatedRunningOperations();

      return _waitForLatestOperation(pending);
    }

    final operation = _AsyncBuildOperation(
      token: token,
      reason: AsyncBuildReason.rebuild,
    );

    _pendingRebuild = operation;
    _latestOperation = operation;

    // Wake callers waiting on previously running operations.
    _supersedeOutdatedRunningOperations();

    scheduleMicrotask(() {
      if (!identical(_pendingRebuild, operation)) return;

      // The token is fixed once execution starts.
      _pendingRebuild = null;

      if (!_isCurrentOperation(operation)) {
        operation.complete();
        return;
      }

      _startOperation(operation, execute);
    });

    return _waitForLatestOperation(operation);
  }

  /// Invalidates pending and running operations without starting replacements.
  ///
  /// Waiting callers are released, and future state updates from invalidated
  /// operations are rejected.
  void invalidate() {
    if (_disposed) return;

    // Invalidate independent operations using the notifier's generation guard.
    _invalidateOperations();

    // Invalidate managed build generations.
    _generationGuard.next();

    // Cancel any rebuild that has not started yet.
    final pending = _pendingRebuild;
    _pendingRebuild = null;
    pending?.invalidate();

    // Invalidate running operations and release their waiting callers.
    for (final operation in _runningOperations.toList()) {
      operation.invalidate();
    }

    _activeOperation = null;
    _latestOperation = null;
  }

  /// Waits for an operation, following its replacement if superseded.
  ///
  /// Waiting resumes when the operation completes or becomes outdated.
  /// Consequently, callers can follow a replacement without waiting for
  /// the outdated operation's underlying asynchronous work to finish.
  ///
  /// Errors from operations replaced while still running are ignored.
  /// Errors from operations that finish before being replaced are propagated
  /// to their waiting callers, even if the manager is invalidated afterward.
  Future<void> _waitForLatestOperation(
    _AsyncBuildOperation initialOperation,
  ) async {
    _AsyncBuildOperation operation = initialOperation;

    while (!_disposed) {
      await operation.changed;

      if (_disposed || operation.isInvalidated) return;

      final wasReplaced = operation.isSuperseded;
      final hasFinished = operation.hasExecutionCompleted;

      // Follow the newer build when this one was replaced.
      // Also follow it when this operation is outdated but hasn't finished.
      if (wasReplaced || (!hasFinished && !_isCurrentOperation(operation))) {
        final _AsyncBuildOperation? replacement = _getLatestReplacement(
          operation,
        );

        if (replacement == null) return;

        operation = replacement;
        continue;
      }

      // Deliver the result of a genuinely completed build.
      if (hasFinished) {
        if (operation.hasError) {
          Error.throwWithStackTrace(operation.error!, operation.stackTrace!);
        }

        return;
      }

      // An operation should not signal a change without reaching
      // a completed, invalidated, or replaced state.
      // coverage:ignore-start
      assert(
        operation.isCompleted,
        'A current build was signalled without completing.',
      );
      // coverage:ignore-end

      return;
    }
  }

  _AsyncBuildOperation? _getLatestReplacement(_AsyncBuildOperation operation) {
    final _AsyncBuildOperation? latest = _latestOperation;

    if (latest == null) return null;
    // coverage:ignore-start
    assert(
      !identical(latest, operation) && _isCurrentOperation(latest),
      'A replaced build must have a current replacement operation.',
    );

    if (identical(latest, operation) || !_isCurrentOperation(latest)) {
      return null;
    }
    // coverage:ignore-end

    return latest;
  }

  /// Joins valid work or starts a fresh refresh.
  ///
  /// When the awaited operation becomes outdated, follows its replacement.
  /// Disposal releases the waiting caller without waiting for underlying
  /// asynchronous work to finish.
  Future<void> refresh(AsyncBuildExecutor execute) async {
    if (_disposed) return;

    _invalidateOperations();

    final pending = _pendingRebuild;

    if (pending != null) {
      await _waitForLatestOperation(pending);
      return;
    }

    final active = _activeOperation;

    if (active != null && _isCurrentOperation(active)) {
      await _waitForLatestOperation(active);
      return;
    }

    // No valid operation is running or pending: refresh starts fresh work.
    final operation = _startNewOperation(AsyncBuildReason.refresh, execute);

    await _waitForLatestOperation(operation);
  }

  _AsyncBuildOperation _startNewOperation(
    AsyncBuildReason reason,
    AsyncBuildExecutor execute,
  ) {
    final operation = _AsyncBuildOperation(
      token: _generationGuard.next(),
      reason: reason,
    );

    _latestOperation = operation;

    // A new generation may have made existing operations obsolete.
    _supersedeOutdatedRunningOperations();

    _startOperation(operation, execute);

    return operation;
  }

  /// Signals running operations that no longer belong to the current
  /// generation so their waiting callers can follow the replacement.
  void _supersedeOutdatedRunningOperations() {
    for (final operation in _runningOperations.toList()) {
      if (!_isCurrentOperation(operation)) {
        operation.markSuperseded();
      }
    }
  }

  void _startOperation(
    _AsyncBuildOperation operation,
    AsyncBuildExecutor execute,
  ) {
    if (!_isCurrentOperation(operation)) {
      operation.complete();
      return;
    }

    _activeOperation = operation;
    _runningOperations.add(operation);

    unawaited(_executeOperation(operation, execute));
  }

  Future<void> _executeOperation(
    _AsyncBuildOperation operation,
    AsyncBuildExecutor execute,
  ) async {
    final token = operation.token;

    try {
      await execute(token, operation.reason);
      operation.completeExecution();
    } catch (error, stackTrace) {
      operation.completeExecutionError(error, stackTrace);
    } finally {
      _runningOperations.remove(operation);

      if (identical(_activeOperation, operation)) {
        _activeOperation = null;
      }
    }
  }

  bool _isCurrentOperation(_AsyncBuildOperation operation) {
    return isCurrent(operation.token);
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _onInvalidateOperations = null;
    _generationGuard.invalidate();

    // Release pending callers.
    _pendingRebuild?.complete();
    _pendingRebuild = null;

    // Release callers awaiting running operations. The underlying asynchronous
    // work may continue, but its results are no longer valid.
    for (final operation in _runningOperations.toList()) {
      operation.complete();
    }

    _runningOperations.clear();
    _activeOperation = null;
    _latestOperation = null;
  }
}

@internal
typedef AsyncBuildExecutor =
    Future<void> Function(int token, AsyncBuildReason reason);

/// Represents one asynchronous build operation and its completion signals.
///
/// Its token can change while pending. Once execution starts, its token
/// remains fixed for the lifetime of the operation.
final class _AsyncBuildOperation {
  _AsyncBuildOperation({required this.token, required this.reason});

  int token;

  final AsyncBuildReason reason;

  final Completer<void> _changedCompleter = Completer<void>();

  bool _isCompleted = false;
  bool _hasError = false;

  Object? _error;
  StackTrace? _stackTrace;

  bool _isInvalidated = false;

  bool _isSuperseded = false;
  bool _hasExecutionCompleted = false;

  bool get isSuperseded => _isSuperseded;
  bool get hasExecutionCompleted => _hasExecutionCompleted;

  bool get isInvalidated => _isInvalidated;

  /// Invalidates the operation and releases its waiting callers.
  void invalidate() {
    if (_isInvalidated) return;

    _isInvalidated = true;
    complete();
  }

  /// Completes when the operation first finishes or becomes outdated.
  Future<void> get changed => _changedCompleter.future;

  bool get isCompleted => _isCompleted;
  bool get hasError => _hasError;

  Object? get error => _error;
  StackTrace? get stackTrace => _stackTrace;

  /// Wakes waiting callers so they can follow the replacement operation.
  void markSuperseded() {
    if (_isSuperseded || _isInvalidated || _isCompleted) return;

    _isSuperseded = true;
    _signalChanged();
  }

  void complete() {
    if (_isCompleted) return;

    _isCompleted = true;
    _signalChanged();
  }

  void completeExecution() {
    if (_isCompleted) return;

    _hasExecutionCompleted = true;
    complete();
  }

  void completeExecutionError(Object error, StackTrace stackTrace) {
    if (_isCompleted) return;

    _hasExecutionCompleted = true;
    _hasError = true;
    _error = error;
    _stackTrace = stackTrace;

    complete();
  }

  void _signalChanged() {
    if (!_changedCompleter.isCompleted) {
      _changedCompleter.complete();
    }
  }
}
