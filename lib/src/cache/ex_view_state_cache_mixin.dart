import 'package:provider_kit/src/notifiers/notifiers.dart';
import 'package:provider_kit/src/base/state_observer/change.dart';
import 'package:provider_kit/src/states/view_states.dart';

/// A mixin that provides extended caching functionality for various [ViewState] types in a [ViewStateNotifier].
///
/// The [ExViewStateCacheMixin] is designed to cache the last known state for each [ViewState] type.
/// This can be useful for preserving the state across different operations or restoring the state after certain actions.
///
/// ### Example Usage:
/// ```dart
/// class MyStateNotifier extends ViewStateNotifier<MyData> with ExViewStateCacheMixin<MyData> {
///   void updateState(ViewState<MyData> newState) {
///     state = newState;
///   }
///
/// ```
///
/// ### Methods:
/// - **`clearCache`**: Clears the cached states for all [ViewState] types.
///
/// ### Lifecycle:
/// The mixin ensures that the cache is cleared when the notifier is disposed.
///
/// ### Parameters:
/// - **`T`**: The type of the data object contained in the [ViewState].
mixin ExViewStateCacheMixin<T> on ViewStateNotifier<T> {
  InitialState<T>? _exInitialState;
  LoadingState<T>? _exLoadingState;
  EmptyState<T>? _exEmptyState;
  ErrorState<T>? _exErrorState;
  DataState<T>? _exDataState;
  T? _exDataStateObject;

  InitialState<T>? get exInitialState => _exInitialState;
  LoadingState<T>? get exLoadingState => _exLoadingState;
  EmptyState<T>? get exEmptyState => _exEmptyState;
  ErrorState<T>? get exErrorState => _exErrorState;
  DataState<T>? get exDataState => _exDataState;
  T? get exDataStateObject => _exDataStateObject;

  @override
  void onChange(Change<ViewState<T>> change) {
    super.onChange(change);
    final exState = change.currentState;
    exState.map(
      initialState: (initialState) => _exInitialState = initialState,
      loadingState: (loadingState) => _exLoadingState = loadingState,
      dataState: (dataState) {
        _exDataState = dataState;
        _exDataStateObject = dataState.data;
      },
      emptyState: (emptyState) => _exEmptyState = emptyState,
      errorState: (errorState) => _exErrorState = errorState,
    );
  }

  void clearCache() {
    _exInitialState = null;
    _exLoadingState = null;
    _exEmptyState = null;
    _exErrorState = null;
    _exDataState = null;
    _exDataStateObject = null;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
