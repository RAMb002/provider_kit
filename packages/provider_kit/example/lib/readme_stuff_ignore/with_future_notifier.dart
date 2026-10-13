import 'dart:async';

import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class FeedProvider extends FutureNotifier<List<Item>> {
  @override
  Future<List<Item>> fetchData() => Repository().getItems(10);
}

// Via Snippet
typedef FeedViewState = ViewState<List<Item>>;

typedef FeedInitialState = InitialState<List<Item>>;
typedef FeedLoadingState = LoadingState<List<Item>>;
typedef FeedEmptyState = EmptyState<List<Item>>;
typedef FeedDataState = DataState<List<Item>>;
typedef FeedErrorState = ErrorState<List<Item>>;

typedef FeedViewStateBuilder = ViewStateBuilder<List<Item>>;
typedef FeedViewStateListener = ViewStateListener<List<Item>>;
typedef FeedViewStateConsumer = ViewStateConsumer<List<Item>>;
