import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// A mixin that lets you cache a [DataState] and restore it later.
///
/// This is useful when you temporarily change your data, such as when
/// filtering or searching, but want to keep the original data available.
///
/// The cache is only updated when [cacheDataState] is called. It does not
/// automatically track changes to [state].
///
/// The cached state and data are stored by reference. No deep copy is created.
///
/// With `FutureNotifier`, you can cache the original data inside
/// `FutureNotifier.build` before returning it.
///
/// ```dart
/// class MoviesNotifier extends FutureNotifier<List<Movie>>
///     with DataStateCacheMixin<List<Movie>> {
///
///   MoviesNotifier(this._repository);
///
///   final MovieRepository _repository;
///
///   @override
///   Future<List<Movie>> build() async {
///     final movies = await _repository.getMovies();
///
///     cacheDataState(DataState(movies));
///
///     return movies;
///   }
///
///   void clearFilter() {
///     final originalState = cachedDataState;
///
///     if (originalState != null) {
///       state = originalState;
///       clearDataStateCache();
///     }
///   }
/// }
/// ```
///
/// ### API
///
/// - [cacheDataState] saves a [DataState] for later use.
/// - [cachedDataState] returns the saved [DataState].
/// - [cachedData] returns the data from the saved [DataState].
/// - [clearDataStateCache] clears the saved state and data.
///
/// The cache is automatically cleared when the notifier is disposed.
mixin DataStateCacheMixin<T> on ViewStateNotifier<T> {
  DataState<T>? _cachedDataState;
  T? _cachedData;

  DataState<T>? get cachedDataState => _cachedDataState;
  T? get cachedData => _cachedData;

  void cacheDataState(DataState<T> dataState) {
    _cachedDataState = dataState;
    _cachedData = dataState.data;
  }

  void clearDataStateCache() {
    _cachedDataState = null;
    _cachedData = null;
  }

  @override
  void dispose() {
    clearDataStateCache();
    super.dispose();
  }
}
