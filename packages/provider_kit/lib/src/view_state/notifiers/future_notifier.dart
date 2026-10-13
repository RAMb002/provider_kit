import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/view_state/notifiers/async_view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// {@template provider_kit.future_notifier}
/// An abstract [AsyncViewStateNotifier] that manages asynchronous data
/// retrieval through a [Future].
///
/// [FutureNotifier] handles the initial build, loading and error states,
/// empty results, and refresh operations. It also coordinates concurrent
/// builds to prevent duplicate fetch operations.
///
/// The initial build is scheduled in a microtask so that subclass
/// initialization completes before data loading begins.
///
/// ### Default behavior
///
/// By default, [FutureNotifier]:
///
/// 1. Starts with a [LoadingState], unless an initial state is provided.
/// 2. Calls [init], which awaits [fetchData].
/// 3. Transitions to [EmptyState] if the fetched result is an empty
///    [Iterable], unless [AsyncViewStateNotifier.disableEmptyState] is `true`.
/// 4. Transitions to [DataState] when data is available.
/// 5. Converts errors into an [ErrorState].
///
/// ### Constructor parameters
///
/// - `initialState`: The initial view state. Defaults to [LoadingState].
/// - [AsyncViewStateNotifier.disableEmptyState]: If `true`, empty
///   [Iterable] results are represented by [DataState] instead of
///   [EmptyState]. Defaults to `false`.
///
/// ### Implementing a notifier
///
/// Subclasses must implement [fetchData] to provide the data source.
///
/// ```dart
/// class UserNotifier extends FutureNotifier<User> {
///   UserNotifier({super.initialState, super.disableEmptyState});
///
///   @override
///   Future<User> fetchData() {
///     return repository.fetchUser();
///   }
/// }
/// ```
///
/// ### Customization
///
/// The following methods can be overridden when custom behavior is required:
///
/// - [fetchData]: Provides the data to be fetched.
/// - [init]: Customizes initialization and state transitions.
/// - [refresh]: Customizes the refresh operation.
/// - [refreshSilently]: Customizes refresh behavior without automatically
///   showing a loading state.
/// - [errorStateObject]: Customizes the resulting [ErrorState], including its
///   error information and retry callback.
/// - [loadingStateObject]: Customizes the [LoadingState].
/// - [emptyStateObject]: Customizes the [EmptyState].
/// - [onError]: Customizes error handling.
///
/// The default implementations of error handling and retry behavior are
/// documented in [AsyncViewStateNotifier].
///
/// ### Refreshing
///
/// [refresh] transitions to [LoadingState] before fetching data, unless the
/// current state is already loading.
///
/// [refreshSilently] fetches data without automatically transitioning to
/// [LoadingState] while the operation is in progress.
///
/// Both operations transition to [DataState], [EmptyState], or [ErrorState]
/// as appropriate.
///
/// If a build operation is already in progress, additional refresh calls reuse
/// that operation rather than starting another fetch. The active operation's
/// refresh mode is retained. Once the operation completes, a subsequent
/// refresh can start a new build.
///
///
/// {@endtemplate}

abstract class FutureNotifier<T> extends AsyncViewStateNotifier<T> {
  /// {@macro provider_kit.future_notifier}
  FutureNotifier({super.initialState, super.disableEmptyState}) {
    scheduleMicrotask(_startInitialBuild);
  }

  Future<T> fetchData();

  final _BuildManager _buildManager = _BuildManager();

  void _startInitialBuild() {
    unawaited(
      _build().catchError((Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'provider_kit',
            context: ErrorDescription(
              'while performing the initial build of $runtimeType',
            ),
          ),
        );
      }),
    );
  }

  Future<void> _build({bool silent = false}) {
    if (!mounted) {
      return Future<void>.value();
    }

    return _buildManager.run(() async {
      if (!mounted) return;

      try {
        if (!silent && !state.isLoading) {
          state = loadingStateObject();
        }
        await init();
      } catch (error, stackTrace) {
        if (!mounted) return;

        onError(error, stackTrace);
      }
    });
  }

  @protected
  @override
  Future<void> init() async {
    // Fetch data.
    final T data = await fetchData();

    if (!mounted) return;
    // Set the state to empty if the data is an empty iterable.
    if (!disableEmptyState && data is Iterable && data.isEmpty) {
      state = emptyStateObject();
    } else {
      // Set the state to data if the data is not null or empty.
      state = DataState<T>(data);
    }
  }

  @mustCallSuper
  @override
  /// Refreshes data by transitioning to [LoadingState] before rebuilding,
  /// unless the current state is already loading.
  ///
  /// On completion, the state transitions to [DataState], [EmptyState],
  /// or [ErrorState], as appropriate.
  ///
  /// If a build is already in progress, this joins the existing operation
  /// without starting another fetch. The active build's refresh mode is retained.
  Future<void> refresh() async {
    if (!mounted) {
      return;
    }
    // Reuses the current build operation if one is already running.
    await _build();
  }

  /// Refreshes data without automatically transitioning to [LoadingState]
  /// while the operation is in progress.
  ///
  /// On completion, the state still transitions to [DataState],
  /// [EmptyState], or [ErrorState], as appropriate.
  ///
  /// If a build is already running, this joins the existing operation.
  @mustCallSuper
  @override
  Future<void> refreshSilently() async {
    if (!mounted) {
      return;
    }
    await _build(silent: true);
  }
}

// Coordinates a single in-flight asynchronous build.
///
/// Concurrent callers receive the same future. The active operation is
/// cleared after success or failure, allowing a subsequent build to start.
final class _BuildManager {
  Future<void>? _currentBuild;

  Future<void> run(Future<void> Function() operation) {
    final currentBuild = _currentBuild;

    if (currentBuild != null) {
      return currentBuild;
    }

    final completer = Completer<void>();
    final future = completer.future;

    // Mark the build active before executing user code.
    _currentBuild = future;

    unawaited(_completeOperation(operation, future, completer));

    return future;
  }

  Future<void> _completeOperation(
    Future<void> Function() operation,
    Future<void> future,
    Completer<void> completer,
  ) async {
    try {
      await operation();
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      if (identical(_currentBuild, future)) {
        _currentBuild = null;
      }
    }
  }
}
