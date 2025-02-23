import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/view_states.dart';

/// An abstract class that extends [ProviderKitInterface] and provides default implementations for state management.
///
/// The [ProviderKit] class is designed to handle common state transitions such as loading, error, and empty states.
/// It ensures that the `init` method is guarded and automatically converts exceptions to error states.
/// Override `init` method for full customization.
/// ```dart
/// FutureOr<void> init() async {
///   if (state is! LoadingState<T>) {
///     state = loadingStateObject();
///   }
///   T? data = await fetchData();
///   if (data == null || (data is Iterable && data.isEmpty)) {
///     state = emptyStateObject();
///   } else {
///     state = DataState<T>(data);
///   }
/// }
/// ```
/// ### Customization:
/// Users can override the following methods to customize state handling inside default init:
/// - **`errorStateObject`** (*Optional*) **:** Customize the error state object, allowing you to define a custom error message, additional metadata, or override how errors are handled.
/// - **`loadingStateObject`** (*Optional*) **:** Customize the loading state object to define different loading representations.
/// - **`emptyStateObject`** (*Optional*) **:** Customize the empty state object, such as by providing a custom message when there is no data.
///
/// When [ProviderKit] is used inside **ViewStateBuilder, ViewStateListener, ViewStateConsumer, MultiViewStateBuilder, and MultiViewStateConsumer**, 
/// the **`onRetry`** function for the `ErrorState` will be determined as follows:
/// 1. If `onRetry` is explicitly set in the `ErrorState`, that function will be used.
/// 2. If `onRetry` is `null`, the provider’s `refresh()` function will be automatically used for retrying.
///
/// ### Example Usage:
/// ```dart
/// class MyProvider extends ProviderKit<MyDataType> {
///   @override
///   FutureOr<MyDataType> fetchData() async {
///     // Fetch data from an API or database
///   }
///
///   @override
///   ErrorState<MyDataType> errorStateObject(Object error, StackTrace stackTrace) {
///     // Customize the error state object
///     return ErrorState<MyDataType>('Custom error message', error, stackTrace);
///   }
///
///   @override
///   LoadingState<MyDataType> loadingStateObject() {
///     // Customize the loading state object
///     return LoadingState<MyDataType>();
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
///     super.refresh();
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
/// - The `onError` method is called when an error occurs and registers the error in the state observer log.
/// - The `refresh` method can be used to retry fetching data and will set the state to loading before retrying.
///
/// ### Initial State:
/// - By default, the initial state is set to **`LoadingState`**.
abstract class ProviderKit<T> extends ProviderKitInterface<T> {
  ProviderKit({
    super.initialState,
  }) {
    _build();
  }

  FutureOr<void> _build() async {
    try {
      await init();
    } catch (e, s) {
      onError(e, s);
    }
  }

  @protected
  @override
  FutureOr<void> init() async {
    // Set the state to loading if it is not already in a loading state.
    if (state is! LoadingState<T>) {
      state = loadingStateObject();
    }
    // Fetch data.
    T? data = await fetchData();
    // Set the state to empty if the data is null or an empty iterable.
    if (data == null || (data is Iterable && data.isEmpty)) {
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
      ErrorState<T>(error.toString(), error, stackTrace);

  @override
  @protected
  LoadingState<T> loadingStateObject() => LoadingState<T>();

  @override
  @protected
  EmptyState<T> emptyStateObject() => EmptyState<T>();

  @protected
  @override
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    state = errorStateObject(error, stackTrace);
    super.onError(error, stackTrace);
  }

  @mustCallSuper
  @override
  Future<void> refresh() async {
    if (state is! LoadingState<T>) {
      state = loadingStateObject();
    }
    await _build();
  }
}

/// An abstract class that provides the interface for [ProviderKit].
///
/// The [ProviderKitInterface] class defines the methods that must be implemented by subclasses.
/// It extends [ViewStateNotifier] and provides a default initial state of **`LoadingState`**.
///
/// ### Methods:
/// - **`init`** (*Required*) **:** A method that is called during initialization and is responsible for fetching data and setting the appropriate state.
/// - **`refresh`** (*Required*) **:** A method that can be used to retry fetching data.
/// - **`fetchData`** (*Required*) **:** A method that must be implemented by subclasses to fetch data.
/// - **`errorStateObject`** (*Required*) **:** A method that provides the error state object.
/// - **`loadingStateObject`** (*Required*) **:** A method that provides the loading state object.
/// - **`emptyStateObject`** (*Required*) **:** A method that provides the empty state object.
abstract class ProviderKitInterface<T> extends ViewStateNotifier<T> {
  ProviderKitInterface({
    ViewState<T>? initialState,
  }) : super(initialState ?? LoadingState<T>());

  @protected
  FutureOr<void>? init();

  FutureOr<void> refresh();

  FutureOr<T> fetchData();

  ErrorState<T> errorStateObject(Object error, StackTrace stackTrace);

  LoadingState<T> loadingStateObject();

  EmptyState<T> emptyStateObject();
}
