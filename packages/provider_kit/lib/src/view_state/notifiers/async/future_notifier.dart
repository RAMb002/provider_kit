part of 'async_notifiers.dart';

/// {@template provider_kit.future_notifier.basic_usage}
/// An asynchronous notifier that load data through a [Future].
///
/// Subclasses implement [build] to load data for the current inputs. ProviderKit manages
/// loading, data, empty, and error states, along with refreshes and rebuilds.
///
/// ### Basic Usage
///
/// ```dart
/// class ProductsNotifier extends FutureNotifier<List<Product>> {
///   ProductsNotifier(this._repository);
///
///   final ProductRepository _repository;
///
///   @override
///   Future<List<Product>> build() {
///     return _repository.fetchProducts();
///   }
/// }
/// ```
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.constructors_param}
///
/// {@template provider_kit.future_notifier.default_behaviour}
/// ### Default behavior
///
/// ProviderKit publishes the value returned by [build] automatically:
///
/// - A non-empty result becomes [DataState].
/// - An empty [Iterable] becomes [EmptyState], unless [enableEmptyState]
///   is `false`.
/// - A failure transitions to [ErrorState] when no usable data is available.
///
/// You can provide an [initialState] when data is already available.
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.state_messages}
///
/// {@template provider_kit.future_notifier.about}
///
/// ### Load cached data on startup
///
/// You can publish cached data while waiting for a fresh result. Assign the
/// cached value to [state], then return the remote result:
///
/// ```dart
/// @override
/// Future<List<Product>> build() async {
///   try {
///     final cached = await _cache.readProducts();
///
///     if (cached != null) {
///       state = DataState<List<Product>>(cached);
///     }
///   } catch (_) {
///     // Cache is optional. Continue to the remote request.
///   }
///
///   return _repository.fetchProducts();
/// }
/// ```
///
/// When the remote request succeeds, ProviderKit publishes its returned
/// result as the final state. You don't need to assign it to [state] yourself.
///
/// If the remote request fails after cached data has been published, the
/// existing [DataState] is preserved by default. If no usable data is
/// available, the notifier transitions to [ErrorState].
///
/// If you want a remote failure to replace cached data with an error state,
/// assign an [ErrorState] explicitly before rethrowing the error:
///
/// ```dart
/// try {
///   return await _repository.fetchProducts();
/// } catch (error, stackTrace) {
///   state = ErrorState<List<Product>>(error, stackTrace);
///   Error.throwWithStackTrace(error, stackTrace);
/// }
/// ```
///
/// Explicit state assignments inside [build] take effect immediately and can
/// override the default state policy. When the build succeeds, its returned
/// value becomes the final state.
///
/// Handle cache errors inside [build] when the cache is optional and a cache
/// failure shouldn't prevent the remote request from running.
///
/// ### Refresh data
///
/// Call [refresh] to run [build] again using the current inputs:
///
/// ```dart
/// try {
///   await refresh();
/// } catch (error, stackTrace) {
///   // The refresh failed, but existing usable data may remain available.
/// }
/// ```
///
/// When [DataState] is available, it remains visible while refreshing. If the
/// refresh fails, existing data is preserved by default, but an explicitly
/// awaited [refresh] still throws the original failure with its stack trace.
///
/// Without usable data, the notifier shows [LoadingState] while loading and
/// transitions to [ErrorState] if the operation fails.
///
/// If valid build work is already running, [refresh] joins that operation.
/// If the operation becomes outdated while [refresh] is waiting, it follows
/// the replacement operation.
///
/// Since [build] can publish intermediate states, [refresh] follows the state
/// transitions defined by your override. Explicit state assignments can
/// override the default refresh behavior, including preserving existing data
/// while refreshing.
///
/// ### Rebuild when inputs change
///
/// Call [rebuild] when an input used by [build] changes, such as a query or
/// filter:
///
/// ```dart
/// class ProductsNotifier extends FutureNotifier<List<Product>> {
///   ProductsNotifier(this._repository);
///
///   final ProductRepository _repository;
///   String _query = '';
///
///   @override
///   Future<List<Product>> build() {
///     return _repository.fetchProducts(query: _query);
///   }
///
///   void updateQuery(String query) {
///     if (_query == query) return;
///
///     _query = query;
///     rebuild();
///   }
/// }
/// ```
///
/// Calling [rebuild] reruns [build] with the latest inputs. The previous build
/// is invalidated, and its stale state assignments and results are ignored.
/// The underlying asynchronous work isn't necessarily cancelled.
///
/// A rebuild clears the previous data when it starts because the data may no
/// longer match the updated inputs.
///
/// Multiple rebuild requests made before a scheduled rebuild starts are
/// coalesced into a single operation using the latest inputs.
///
/// If a build is superseded while a caller is awaiting [rebuild], the returned
/// future follows the replacement operation rather than waiting for the
/// outdated operation to finish. Errors from outdated operations are ignored;
/// an error from the current relevant operation is propagated with its
/// original stack trace.
///
/// ### Invalidate the current build
///
/// Call [invalidateBuild] to invalidate the current build without starting
/// a replacement:
///
/// ```dart
/// void cancelSearch() {
///   invalidateBuild();
/// }
/// ```
///
/// This invalidates the current generation. Any pending or running build
/// becomes outdated, and its returned result and state assignments are ignored.
///
/// The underlying Future isn't cancelled by ProviderKit. It may continue
/// executing, but its result and state assignments are ignored.
///
/// If an operation is awaiting [refresh] or [rebuild] when invalidation
/// occurs, its waiting future completes normally. This does not guarantee
/// that new data was loaded.
///
/// [invalidateBuild] does not change the current [ViewState] and does not
/// automatically start another build. The existing state remains unchanged.
/// Use [setInitial] or another state-setting method when a state reset is
/// required.
///
/// Call [refresh] to start another build with the current inputs, or
/// [rebuild] when you need to build again with updated inputs.
/// {@endtemplate}
///
/// {@macro provider_kit.async_view_state_notifier_base.state_setters}
///
/// {@macro provider_kit.async_view_state_notifier_base.check_staleness}
abstract class FutureNotifier<T> extends _AsyncViewStateNotifierBase<T> {
  /// {@macro provider_kit.future_notifier.basic_usage}
  /// {@macro provider_kit.async_view_state_notifier_base.constructors_param}
  /// {@macro provider_kit.future_notifier.default_behaviour}
  /// {@macro provider_kit.async_view_state_notifier_base.state_messages}
  /// {@macro provider_kit.future_notifier.about}
  /// {@macro provider_kit.async_view_state_notifier_base.state_setters}
  /// {@macro provider_kit.async_view_state_notifier_base.check_staleness}
  FutureNotifier({
    super.initialState,
    super.startInitialBuild,
    super.enableEmptyState,
    super.loadingMessage,
    super.emptyMessage,
  });

  /// Loads data for the current inputs.
  ///
  /// Override this method to fetch data. ProviderKit publishes the returned
  /// result automatically. Assign [state] directly only for intermediate
  /// state updates.
  @protected
  Future<T> build();

  @override
  Future<void> _executeBuild(int token, AsyncBuildReason reason) async {
    if (!_isCurrentBuild(token)) return;

    try {
      _prepareBuild(reason);

      if (!_isCurrentBuild(token)) return;

      // The build's generation follows its asynchronous execution, including
      // state assignments made after await.
      final result = await runZoned<Future<T>>(
        build,
        zoneValues: {_buildZoneKey: token},
      );

      _handleBuildResult(token, result);
    } catch (error, stackTrace) {
      _handleBuildError(token, error, stackTrace);
    }
  }

  /// Publishes the returned result if the build is still current.
  void _handleBuildResult(int token, T result) {
    if (!_isCurrentBuild(token)) return;

    if (_isEmptyState(result)) {
      setEmpty();
    } else {
      state = DataState<T>(result);
    }
  }

  /// Applies the default error policy to a failed build.
  ///
  /// Existing data is preserved and the error is reported. Without usable
  /// data, the notifier transitions to [ErrorState].
  ///
  /// The wrapper allows refresh to propagate the original failure, while
  /// fire-and-forget builds avoid duplicate error reporting.
  void _handleBuildError(int token, Object error, StackTrace stackTrace) {
    if (!_isCurrentBuild(token)) return;

    if (state.isData || state.isError) {
      dispatchErrorToObserver(error, stackTrace);
    } else {
      setError(error, stackTrace);
    }

    // Error handlers and observers can synchronously trigger another rebuild.
    if (!_isCurrentBuild(token)) return;

    Error.throwWithStackTrace(error, stackTrace);
  }
}
