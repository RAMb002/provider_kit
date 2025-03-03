import 'package:provider_kit/src/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/states/view_states.dart';

/// A mixin that provides caching functionality for [DataState] in a [ViewStateNotifier].
///
/// The [DataStateCopyCacheMixin] is designed to cache the last known [DataState] and its associated data object.
/// This can be useful for preserving the state across different operations or restoring the state after certain actions.
///
/// ### Example Usage:
/// ```dart
/// class MyStateNotifier extends ViewStateNotifier<MyData> with DataStateCopyCacheMixin<MyData> {
///   void updateData(ViewState<MyData> newDataState) {
///     saveDataStateCopy(newDataState);
///     state = newDataState;
///   }
///
///   void restoreData() {
///     if (dataStateCopy != null) {
///       state = dataStateCopy!;
///     }
///   }
/// }
/// ```
///
/// ### Methods:
/// - **`saveDataStateCopy`**: Saves the provided [DataState] and its data object to the cache.
/// - **`clearDataStateCopy`**: Clears the cached [DataState] and its data object.
/// - **`dataStateCopy`**: Returns the cached [DataState].
/// - **`dataObjectCopy`**: Returns the cached data object.
///
/// ### Lifecycle:
/// The mixin ensures that the cache is cleared when the notifier is disposed.
///
/// ### Parameters:
/// - **`T`**: The type of the data object contained in the [DataState].
mixin DataStateCopyCacheMixin<T> on ViewStateNotifier<T> {
  DataState<T>? _dataStateCopy;
  T? _dataObjectCopy;

  DataState<T>? get dataStateCopy => _dataStateCopy;
  T? get dataObjectCopy => _dataObjectCopy;

  void saveDataStateCopy(ViewState<T>? newDataState) {
    if (newDataState is DataState<T>) {
      _dataStateCopy = newDataState;
      _dataObjectCopy = newDataState.data;
    }
  }

  void clearDataStateCopy() {
    _dataStateCopy = null;
    _dataObjectCopy = null;
  }

  @override
  void dispose() {
    clearDataStateCopy();
    super.dispose();
  }
}
