import 'package:example/widgets/shared/repositories/todo_repository.dart';
import 'package:provider_kit/provider_kit.dart';

class TodoNotifier extends FutureNotifier<List<Todo>>
    with NotifierResourcesMixin {
  TodoNotifier() : _repository = TodoRepository();

  final TodoRepository _repository;

  late final _deleteMutations = mutationGroup<void>();

  @override
  Future<List<Todo>> build() {
    return _repository.fetchTodos();
  }

  Mutation<void> deleteMutation(int id) {
    return _deleteMutations(id);
  }

  Future<MutationResult<void>> deleteTodo(int id) async {
    final result = await deleteMutation(id).run(
      () => _repository.deleteTodo(id),
      onSuccess: (data) => refresh(),
    );

    return result;
  }
}
