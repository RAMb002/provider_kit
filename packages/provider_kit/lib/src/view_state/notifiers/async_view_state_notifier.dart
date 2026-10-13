import 'package:flutter/foundation.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// {@template provider_kit.async_view_state_notifier}
/// An abstract base class for asynchronous notifiers that expose data through
/// [ViewState] and support refresh operations.
///
/// [AsyncViewStateNotifier] provides shared state handling for
/// [FutureNotifier] and [StreamNotifier], including default loading and empty
/// states, error handling, and retry behavior.
///
/// ### Constructor parameters
///
/// - `initialState`: The initial view state. Defaults to [LoadingState].
/// - [disableEmptyState]: If `true`, empty [Iterable] results or stream events
///   are represented by [DataState] instead of [EmptyState]. Defaults to
///   `false`.
///
/// ### State customization
///
/// The following methods provide default state objects and can be overridden
/// by subclasses to customize state presentation:
///
/// - [errorStateObject]: Creates an [ErrorState] for a failed operation.
/// - [loadingStateObject]: Creates a [LoadingState].
/// - [emptyStateObject]: Creates an [EmptyState].
///
/// ### Error handling
///
/// [onError] updates the current state to an [ErrorState] and delegates error
/// notification to the inherited notifier error-handling mechanism.
///
/// By default, [errorStateObject] assigns [refresh] as the error state's retry
/// callback.
///
/// ### Retry behavior
///
/// When an asynchronous notifier is used with [ViewStateBuilder],
/// [ViewStateBuilder.multi], [ViewStateListener], [ViewStateListener.multi],
/// [ViewStateConsumer], or [ViewStateConsumer.multi], retry handling follows
/// these rules:
///
/// 1. If [ErrorState.onRetry] is explicitly provided, that callback takes
///    precedence.
/// 2. If [ErrorState.onRetry] is `null`, the widget uses the notifier's
///    [refresh] method as its retry fallback, where supported by the widget API.
///
/// ### Refreshing
///
/// [refresh] refreshes the data according to the concrete notifier's
/// implementation.
///
/// [refreshSilently] refreshes the data without automatically transitioning
/// to [LoadingState] while the operation is in progress.
///
/// The exact refresh behavior and completion semantics depend on whether the
/// concrete notifier uses a [Future] or a [Stream].
///
/// {@endtemplate}
abstract class AsyncViewStateNotifier<T> extends ViewStateNotifier<T> {
  AsyncViewStateNotifier({
    ViewState<T>? initialState,
    this.disableEmptyState = false,
  }) : super(initialState ?? LoadingState<T>());

  @protected
  final bool disableEmptyState;

  @protected
  Future<void> init();

  Future<void> refresh();

  /// Refreshes data without automatically transitioning to [LoadingState]
  /// while the operation is in progress.
  ///
  /// On completion, the state still transitions to [DataState],
  /// [EmptyState], or [ErrorState], as appropriate.
  ///
  /// If a build is already running, this joins the existing operation.
  Future<void> refreshSilently();

  @protected
  ErrorState<T> errorStateObject(Object error, StackTrace stackTrace) {
    return ErrorState<T>(error, stackTrace, onRetry: refresh);
  }

  @protected
  LoadingState<T> loadingStateObject() {
    return LoadingState<T>();
  }

  @protected
  EmptyState<T> emptyStateObject() {
    return EmptyState<T>();
  }

  @protected
  @mustCallSuper
  @override
  void onError(Object error, StackTrace stackTrace) {
    if (!mounted) return;

    state = errorStateObject(error, stackTrace);
    super.onError(error, stackTrace);
  }
}
