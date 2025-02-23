import 'dart:async';
import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class ProviderKitProvider extends ProviderKit<List<Item>> {
  final Repository _repo = Repository();

  ProviderKitProvider() : super(initialState: const InitialState());

  @override
  Future<void> init() async {
    state = const LoadingState();
    final List<Item> items = await _repo.getItems(10);
    // throw Exception('error');
    if (items.isEmpty) {
      state = emptyStateObject();
      return;
    }
    state = DataState(items);
  }

  @override
  FutureOr<List<Item>> fetchData() => _repo.getItems(10);
}
