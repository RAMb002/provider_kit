class Repository {
  Future<Item> getItem() async {
    return await Future.delayed(const Duration(seconds: 2)).then(
      (_) => Item(label: 'This is the data string that is fetched'),
    );
  }

  Future<List<Item>> getItems(
    int pageSize, [
    int? page,
  ]) async {
    return await Future.delayed(const Duration(seconds: 2)).then(
      (_) => List.generate(
        pageSize,
        (index) => Item(label: index.toString()),
      ),
    );
  }

  Future<Movie> getMovie() async {
    return await Future.delayed(const Duration(seconds: 2)).then(
      (_) => const Movie(
        title: 'The Example Movie',
        year: 2026,
      ),
    );
  }

  Future<List<Movie>> getSimilarMovies() async {
    return await Future.delayed(const Duration(seconds: 2)).then(
      (_) => const [
        Movie(title: 'Similar Movie One', year: 2025),
        Movie(title: 'Similar Movie Two', year: 2024),
        Movie(title: 'Similar Movie Three', year: 2023),
      ],
    );
  }

  Future<List<Trailer>> getTrailers() async {
    return await Future.delayed(const Duration(seconds: 2)).then(
      (_) => const [
        Trailer(
          title: 'Official Trailer',
          url: 'https://example.com/trailer',
        ),
        Trailer(
          title: 'Final Trailer',
          url: 'https://example.com/final-trailer',
        ),
      ],
    );
  }

  Future<void> delay([int delay = 2]) async {
    await Future.delayed(Duration(seconds: delay));
  }
}

class Item {
  final String label;

  Item({required this.label});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.label == label;
  }

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() {
    return 'Item(label: $label)';
  }

  Item copyWith({String? label}) {
    return Item(
      label: label ?? this.label,
    );
  }
}

class Movie {
  const Movie({
    required this.title,
    required this.year,
  });

  final String title;
  final int year;

  @override
  String toString() {
    return 'Movie(title: $title, year: $year)';
  }
}

class Trailer {
  const Trailer({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  String toString() {
    return 'Trailer(title: $title, url: $url)';
  }
}
