class MoviesException implements Exception {
  const MoviesException();
}

class MoviesRepository {
  int _attempt = 0;

  Future<List<String>> fetchMovies([bool? giveData]) async {
    if(giveData == true) _attempt = 2;
    // Simulate a network request.
    await Future.delayed(const Duration(seconds: 2));

    switch (_attempt++) {
      case 0:
         throw const MoviesException();

      case 1:
        return const [];

      default:
        return const [
          'Interstellar',
          'The Martian',
          'I am Legend',
        ];
    }
  }

  Future<List<String>> fetchRecommendations() async {
    await Future.delayed(const Duration(seconds: 3));

    return const [
      'Arrival',
      'Gravity',
      'The Prestige',
    ];
  }
}

