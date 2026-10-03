import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';

/// A mixin that lets you save a [DataState] and restore it later.
///
/// This is useful when you temporarily change your data, such as when
/// filtering or searching, but want to keep the original data available.
///
/// The cache is only updated when [cacheDataState] is called. It does not
/// automatically track changes to [state].
///
/// The cached state and data are stored by reference. No deep copy is created.
///
/// ### ViewStateNotifier
///
/// ```dart
/// class MoviesProvider extends ViewStateNotifier<List<Movie>>
///     with DataStateCacheMixin<List<Movie>> {
///
///   void filter(String query) {
///     final currentState = state;
///     if (currentState is! DataState<List<Movie>>) {
///       return;
///     }
///     if (cachedDataState == null) {
///       cacheDataState(currentState);
///     }
///
///     final filteredMovies = currentState.data
///         .where((movie) => movie.title.contains(query))
///         .toList();
///
///     state = DataState(filteredMovies);
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
/// ### AsyncViewStateNotifier
///
/// With [AsyncViewStateNotifier], you can cache the original data directly
/// inside [fetchData] before returning it.
///
/// ```dart
/// class MoviesProvider extends AsyncViewStateNotifier<List<Movie>>
///     with DataStateCacheMixin<List<Movie>> {
///
///   @override
///   Future<List<Movie>> fetchData() async {
///     final movies = await repository.getMovies();
///     cacheDataState(DataState(movies));
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