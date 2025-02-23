import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/view_states.dart';

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
    if (state is! LoadingState<T>) {
      state = loadingStateObject();
    }
    T? data = await fetchData();
    if (data == null) {
      state = emptyStateObject();
    } else if (data is Iterable && data.isEmpty) {
      state = emptyStateObject();
    } else {
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

  @override
  Future<void> refresh() async {
    if (state is! LoadingState<T>) {
      state = loadingStateObject();
    }
    await _build();
  }
}

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
