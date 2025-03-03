import 'dart:async';
import 'package:example/repository/repository.dart';
import 'package:provider_kit/provider_kit.dart';

class ItemsProvider extends ProviderKit<List<Item>> {
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

typedef ItemsViewStateBuilder = ViewStateBuilder<ItemsProvider, List<Item>>;
typedef ItemsViewStateListener = ViewStateListener<ItemsProvider, List<Item>>;
typedef ItemsViewStateConsumer = ViewStateConsumer<ItemsProvider, List<Item>>;
