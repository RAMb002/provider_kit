import 'package:provider_kit/src/base/state_notifier_base.dart';
import 'package:provider_kit/src/base/state_observer/change.dart';
import 'package:provider_kit/states/view_states.dart';

mixin ExViewStateCacheMixin<T> on StateNotifierBase<ViewState<T>> {
  InitialState<T>? _exInitialState;
  LoadingState<T>? _exLoadingState;
  EmptyState<T>? _exEmptyState;
  ErrorState<T>? _exErrorState;
  DataState<T>? _exDataState;

  InitialState<T>? get exInitialState => _exInitialState;
  LoadingState<T>? get exLoadingState => _exLoadingState;
  EmptyState<T>? get exEmptyState => _exEmptyState;
  ErrorState<T>? get exErrorState => _exErrorState;
  DataState<T>? get exDataState => _exDataState;

  @override
  void onChange(Change<ViewState<T>> change) {
    super.onChange(change);
    final exState = change.currentState;
    exState.map(
        initialState: (initialState) => _exInitialState = initialState,
        loadingState: (loadingState) => _exLoadingState = loadingState,
        dataState: (dataState) => _exDataState = dataState,
        emptyState: (emptyState) => _exEmptyState = emptyState,
        errorState: (errorState) => _exErrorState = errorState);
  }

  void clearCache() {
    _exInitialState = null;
    _exLoadingState = null;
    _exEmptyState = null;
    _exErrorState = null;
    _exDataState = null;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
