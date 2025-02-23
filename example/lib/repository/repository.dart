class Repository {
  Future<Item> getItem() async {
    return await Future.delayed((const Duration(seconds: 2)))
        .then((_) => Item(label: "This is the data string that is fetched"));
  }

  Future<List<Item>> getItems(
    int pageSize, [
    int? page,
  ]) async {
    return await Future.delayed((const Duration(seconds: 2))).then((_) =>
        List.generate(pageSize, (index) => Item(label: (index).toString())));
  }

  Future<void> delay([int delay = 2]) async {
    await Future.delayed( Duration(seconds: delay));
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
