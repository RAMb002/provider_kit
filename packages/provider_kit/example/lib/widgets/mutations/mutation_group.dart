import 'package:example/widgets/shared/notifiers/todo_notifier.dart';
import 'package:example/widgets/shared/repositories/todo_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates independent per-item operations using MutationGroup.
class MutationGroupExample extends StatelessWidget {
  const MutationGroupExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoNotifier(),
      child: const _TodoListView(),
    );
  }
}

class _TodoListView extends StatelessWidget {
  const _TodoListView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ViewStateBuilder.of<TodoNotifier, List<Todo>>(
            emptyBuilder: (context, details) => const Center(
              child: Text('All tasks completed!'),
            ),
            dataBuilder: (context, todos, child) {
              final notifier = context.read<TodoNotifier>();

              return SizedBox(
                height: 240,
                child: ListView.separated(
                  itemCount: todos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final todo = todos[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(todo.title),
                      trailing: SizedBox(
                        width: 48,
                        child: StateBuilder.select<TodoNotifier,
                            MutationState<void>>(
                          selector: (notifier) =>
                              notifier.deleteMutation(todo.id),
                          builder: (context, state, child) {
                            return state.when(
                              idle: () => IconButton(
                                tooltip: 'Delete task',
                                onPressed: () => notifier.deleteTodo(todo.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                              ),
                              loading: () => const Center(
                                child: SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              success: (_) => const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              error: (errorInfo, error, stackTrace) =>
                                  IconButton(
                                tooltip: 'Retry',
                                onPressed: () => notifier.deleteTodo(todo.id),
                                icon: const Icon(Icons.refresh),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
