import 'dart:async';

import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class ItemsProvider extends FutureNotifier<List<Item>> {
  final Repository _repo = Repository();

  @override
  Future<List<Item>> build() => _repo.getItems(10);
}

typedef ItemsViewState = ViewState<List<Item>>;

typedef ItemsInitialState = InitialState<List<Item>>;
typedef ItemsLoadingState = LoadingState<List<Item>>;
typedef ItemsEmptyState = EmptyState<List<Item>>;
typedef ItemsDataState = DataState<List<Item>>;
typedef ItemsErrorState = ErrorState<List<Item>>;

typedef ItemsViewStateBuilder = ViewStateBuilder<List<Item>>;
typedef ItemsViewStateListener = ViewStateListener<List<Item>>;
typedef ItemsViewStateConsumer = ViewStateConsumer<List<Item>>;

class MovieProvider extends FutureNotifier<Movie> {
  final Repository _repo = Repository();

  @override
  Future<Movie> build() => _repo.getMovie();
}

class SimilarMoviesProvider extends FutureNotifier<List<Movie>> {
  final Repository _repo = Repository();

  @override
  Future<List<Movie>> build() => _repo.getSimilarMovies();
}

class TrailersProvider extends FutureNotifier<List<Trailer>> {
  final Repository _repo = Repository();

  @override
  Future<List<Trailer>> build() => _repo.getTrailers();
}
