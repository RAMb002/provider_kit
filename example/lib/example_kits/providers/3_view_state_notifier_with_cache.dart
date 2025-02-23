
import 'package:provider_kit/provider_kit.dart';

import 'package:example/repository/repository.dart';

class ViewStateProvider extends ViewStateNotifier<List<Item>>
    with DataStateCopyCacheMixin, ExViewStateCacheMixin {
  final Repository _repo = Repository();

  ViewStateProvider([super.state = const InitialState()]) {
    init();
  }

  Future<void> init() async {
    try {
      await _repo.delay(1);
      state = const LoadingState();
      final List<Item> items = await _repo.getItems(10);
      if (items.isEmpty) {
        state = const EmptyState();
        return;
      }
      state = DataState(items);
      saveDataStateCopy(state);
    } catch (e) {
      state = ErrorState(e.toString());
    }
  }
}
