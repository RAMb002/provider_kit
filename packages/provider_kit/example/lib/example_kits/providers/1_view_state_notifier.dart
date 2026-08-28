import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class ViewStateProviderOne extends ViewStateNotifier<List<Item>> {
  final Repository _repo = Repository();

  ViewStateProviderOne([super.state = const InitialState()]) {
    init();
  }

  Future<void> init() async {
    try {
      await _repo.delay();
      if (!mounted) return;
      state = const LoadingState();
      final List<Item> items = await _repo.getItems(10);
      if (!mounted) return;
      if (items.isEmpty) {
        state = const EmptyState();
        return;
      }
      state = DataState(items);
    } catch (e, s) {
      state = ErrorState(
        e,
        s,
        onRetry: onRetry,
      );
    }
  }

  void onRetry() {
    state = const LoadingState();
    init();
  }
}

class ViewStateProviderTwo extends ViewStateNotifier<List<Item>>
    with DataStateCopyCacheMixin, ExViewStateCacheMixin {
  final Repository _repo = Repository();

  ViewStateProviderTwo([super.state = const InitialState()]) {
    init();
  }

  Future<void> init() async {
    try {
      await _repo.delay(1);
      if (!mounted) return;

      state = const LoadingState();
      final List<Item> items = await _repo.getItems(10);
      if (!mounted) return;
      if (items.isEmpty) {
        state = const EmptyState();
        return;
      }
      state = DataState(items);
      saveDataStateCopy(state);
    } catch (e, s) {
      state = ErrorState(
        e,
        s,
      );
    }
  }
}
