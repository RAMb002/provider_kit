import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// {@template provider_kit.asyncViewStateNotifier}
/// An abstract class that extends [AsyncViewStateNotifierInterface] and provides default implementations for state management.
///
/// The [AsyncViewStateNotifier] class is designed to handle common state transitions such as loading, error, and empty states.
/// It guards the initialization and refresh operations, prevents duplicate
/// asynchronous operations while a build is already running, and converts
/// errors into [ErrorState] instances.
/// Override [init] for full customization.
/// ```dart
/// FutureOr<void> init() async {
///   final T data = await fetchData();
///   if (!mounted) return;
///   if (data is Iterable && data.isEmpty) {
///     state = emptyStateObject();
///   } else {
///     state = DataState<T>(data);
///   }
/// }
/// ```
///
/// ### Constructor Parameters:
/// - **`initialState`** (*Optional*) **:** Override the default initial state (which is `LoadingState<T>()`).
/// - **`disableEmptyState`** (*Optional*, default: `false`) **:** If `true`, an empty `Iterable` result will **not** be converted to `EmptyState`; instead, it will be stored as a `DataState` with the empty collection.
///
/// ### Customization:
/// Users can override the following methods to customize state handling inside default init:
/// - **`fetchData`** (*Required*) **:** The method that actually fetches the data. Must be implemented by subclasses.
/// - **`init`** (*Optional*) **:** Customize the initialization and state transition flow.
/// - **`refresh`** (*Optional*): Customize the refresh behavior, which transitions to [LoadingState] before rebuilding when appropriate.
/// - **`refreshSilently`** (*Optional*): Customize the silent refresh behavior, which preserves the current state while fetching without automatically transitioning to [LoadingState].
/// - **`errorStateObject`** (*Optional*) **:** Customize the [ErrorState],
///   including its [ErrorInfo] and retry callback.
/// - **`loadingStateObject`** (*Optional*) **:** Customize the loading state object to define different loading representations.
/// - **`emptyStateObject`** (*Optional*) **:** Customize the empty state object, such as by providing a custom message when there is no data.
///
/// When [AsyncViewStateNotifier] is used inside **ViewStateBuilder, ViewStateListener, ViewStateConsumer, MultiViewStateBuilder, MultiViewStateListener and MultiViewStateConsumer**,
/// the **`onRetry`** function for the `ErrorState` will be determined as follows:
/// 1. If `onRetry` is explicitly set in the `ErrorState`, that function will be used.
/// 2. If `onRetry` is `null`, the provider’s [refresh] function will be automatically used for retrying.
///
/// ### Example Usage:
/// ```dart
/// class MyProvider extends AsyncViewStateNotifier<MyDataType> {
///   MyProvider({super.initialState, super.disableEmptyState});
///
///   @override
///   FutureOr<MyDataType> fetchData() async {
///     // Fetch data from an API or database
///   }
///
/// @override
/// ErrorState<MyDataType> errorStateObject(
///   Object error,
///   StackTrace stackTrace,
/// ) {
///   return ErrorState<MyDataType>(
///     error,
///     stackTrace,
///     errorInfo: const ErrorInfo(
///       message: 'Unable to load data.',
///       code: 'load_failed',
///     ),
///     onRetry: refresh,
///   );
/// }
///
///   @override
///   LoadingState<MyDataType> loadingStateObject() {
///     // Customize the loading state object
///     return LoadingState<MyDataType>('Loading...', 0.0);
///   }
///
///   @override
///   EmptyState<MyDataType> emptyStateObject() {
///     // Customize the empty state object
///     return EmptyState<MyDataType>('No data available');
///   }
///
///   @override
///   Future<void> refresh() async {
///     // Optionally override refresh behavior
///     await super.refresh();
///   }
///
///   @override
///   Future<void> refreshSilently() async {
///     // Optionally override refreshSilently behavior
///     await super.refreshSilently();
///   }
///
///   @override
///   void onError(Object error, StackTrace stackTrace) {
///     // Optionally override error handling
///     super.onError(error, stackTrace);
///   }
/// }
/// ```
///
/// ### Error Handling:
/// - The `onError` method updates the state to [ErrorState] and notifies the configured [NotifierObserver].
/// - The `refresh` method can be used to retry fetching data and will set the state to loading before retrying.
/// - If a build operation is already in progress, additional `refresh` calls reuse the current operation instead of starting another fetch.
///
/// ### Initial State:
/// - By default, the initial state is set to **`LoadingState`**.
/// {@endtemplate}

abstract class AsyncViewStateNotifier<T>
    extends AsyncViewStateNotifierInterface<T> {
  /// {@macro provider_kit.asyncViewStateNotifier}
  AsyncViewStateNotifier({
    super.initialState,
    this._disableEmptyState = false,
  }) {
    scheduleMicrotask(_startInitialBuild);
  }

  final bool _disableEmptyState;
  final _AsyncBuildManager _buildManager = _AsyncBuildManager();

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
  FutureOr<void> init() async {
    // Fetch data.
    final T data = await fetchData();

    if (!mounted) return;
    // Set the state to empty if the data is an empty iterable.
    if (!_disableEmptyState && data is Iterable && data.isEmpty) {
      state = emptyStateObject();
    } else {
      // Set the state to data if the data is not null or empty.
      state = DataState<T>(data);
    }
  }

  @override
  FutureOr<T> fetchData();

  @override
  @protected
  ErrorState<T> errorStateObject(Object error, StackTrace stackTrace) =>
      ErrorState<T>(error, stackTrace, onRetry: refresh);

  @override
  @protected
  LoadingState<T> loadingStateObject() => LoadingState<T>();

  @override
  @protected
  EmptyState<T> emptyStateObject() => EmptyState<T>();

  @protected
  @override
  @mustCallSuper
  /// Handles errors thrown during initialization and updates the state
  /// with an [ErrorState].
  void onError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    state = errorStateObject(error, stackTrace);
    super.onError(error, stackTrace);
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

/// An abstract class that provides the interface for [AsyncViewStateNotifier].
///
/// The [AsyncViewStateNotifierInterface] class defines the methods that must be implemented by subclasses.
/// It extends [ViewStateNotifier] and provides a default initial state of **`LoadingState`**.
///
/// ### Methods:
/// - **`init`** (*Required*) **:** A method that is called during initialization and is responsible for fetching data and setting the appropriate state.
/// - **`refresh`** (*Required*) **:** A method that can be used to retry fetching data.
/// - **`fetchData`** (*Required*) **:** A method that must be implemented by subclasses to fetch data.
/// - **`errorStateObject`** (*Required*) **:** A method that provides the error state object.
/// - **`loadingStateObject`** (*Required*) **:** A method that provides the loading state object.
/// - **`emptyStateObject`** (*Required*) **:** A method that provides the empty state object.
abstract class AsyncViewStateNotifierInterface<T> extends ViewStateNotifier<T> {
  AsyncViewStateNotifierInterface({ViewState<T>? initialState})
    : super(initialState ?? LoadingState<T>());

  FutureOr<void> init();

  Future<void> refresh();

  Future<void> refreshSilently();

  FutureOr<T> fetchData();

  ErrorState<T> errorStateObject(Object error, StackTrace stackTrace);

  LoadingState<T> loadingStateObject();

  EmptyState<T> emptyStateObject();
}

// Coordinates a single in-flight asynchronous build.
///
/// Concurrent callers receive the same future. The active operation is
/// cleared after success or failure, allowing a subsequent build to start.
final class _AsyncBuildManager {
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
