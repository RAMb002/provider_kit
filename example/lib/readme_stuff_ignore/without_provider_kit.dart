import 'package:equatable/equatable.dart';
import 'package:example/repository/repository.dart';
import 'package:flutter/foundation.dart';

class FeedProvider extends ValueNotifier<FeedViewState> {
  FeedProvider() : super(const FeedLoadingState()) {
    _build();
  }
  bool _disposed = false;
  bool get mounted => !_disposed;

  Future<void> _build() async {
    if (!mounted) return;
    try {
      value = const FeedLoadingState();
      await init();
    } catch (e, s) {
      if (!mounted) return;
      value = FeedErrorState(e.toString(), e, s, refresh);
    }
  }

  @protected
  Future<void> init() async {
    final List<Item> data = await fetchData();
    if (!mounted) return;
    if (data.isEmpty) {
      value = const FeedEmptyState();
    } else {
      value = FeedDataState(data);
    }
  }

  Future<List<Item>> fetchData() async {
    return Repository().getItems(10);
  }

  Future<void> refresh() async {
    if (!mounted) return;
    value = const FeedLoadingState();
    await _build();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

sealed class FeedViewState extends Equatable {
  const FeedViewState();
}

class FeedInitialState extends FeedViewState {
  const FeedInitialState();

  @override
  List<Object?> get props => [];
}

class FeedLoadingState extends FeedViewState {
  const FeedLoadingState();

  @override
  List<Object?> get props => [];
}

class FeedEmptyState extends FeedViewState {
  const FeedEmptyState();

  @override
  List<Object?> get props => [];
}

class FeedDataState extends FeedViewState {
  const FeedDataState(this.data);

  final List<Item> data;

  @override
  List<Object?> get props => [data];
}

class FeedErrorState extends FeedViewState {
  const FeedErrorState(
    this.message,
    this.error,
    this.stackTrace,
    this.onRetry,
  );

  final String message;
  final Object error;
  final StackTrace stackTrace;
  final Future<void> Function() onRetry;

  @override
  List<Object?> get props => [
        message,
        error,
        stackTrace,
        onRetry,
      ];
}
