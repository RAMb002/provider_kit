import 'package:example/widgets/shared/repositories/movies_repository.dart';
import 'package:provider_kit/provider_kit.dart';

class RecommendationsNotifier extends FutureNotifier<List<String>> {
  final MoviesRepository _repository = MoviesRepository();

  @override
  Future<List<String>> build() => _repository.fetchRecommendations();
}
