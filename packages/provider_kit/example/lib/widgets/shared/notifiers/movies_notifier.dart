import 'package:provider_kit/provider_kit.dart';

import '../repositories/movies_repository.dart';

class MoviesNotifier extends FutureNotifier<List<String>> {
  MoviesNotifier()
      : super(
          loadingMessage: 'Loading Movies',
          emptyMessage: 'No movies found',
        );

  final MoviesRepository _repository = MoviesRepository();

  @override
  Future<List<String>> build() {
    return _repository.fetchMovies();
  }
}
