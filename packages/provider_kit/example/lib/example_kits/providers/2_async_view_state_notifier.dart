import 'dart:async';

import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class ItemsProvider extends AsyncViewStateNotifier<List<Item>> {
  final Repository _repo = Repository();

  @override
  FutureOr<List<Item>> fetchData() => _repo.getItems(10);
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

class MovieProvider extends AsyncViewStateNotifier<Movie> {
  final Repository _repo = Repository();

  @override
  FutureOr<Movie> fetchData() => _repo.getMovie();
}

class SimilarMoviesProvider extends AsyncViewStateNotifier<List<Movie>> {
  final Repository _repo = Repository();

  @override
  FutureOr<List<Movie>> fetchData() => _repo.getSimilarMovies();
}

class TrailersProvider extends AsyncViewStateNotifier<List<Trailer>> {
  final Repository _repo = Repository();

  @override
  FutureOr<List<Trailer>> fetchData() => _repo.getTrailers();
}
