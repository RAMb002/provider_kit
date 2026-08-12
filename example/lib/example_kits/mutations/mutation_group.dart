import 'package:example/example_kits/mutations/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider_kit/provider_kit.dart';

class MutationGroupExample extends StatefulWidget {
  const MutationGroupExample({super.key});

  @override
  State<MutationGroupExample> createState() => _MutationGroupExampleState();
}

class _MutationGroupExampleState extends State<MutationGroupExample> {
  final List<Todo> todos = List.generate(500, (index) {
    return Todo(index + 1, 'Todo item ${index + 1}');
  });

  final deleteTodoGroup = MutationGroup<void>(
      // keepAliveStates: {KeepAliveState.success, KeepAliveState.error}
    );

  @override
  void dispose() {
    deleteTodoGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          final deleteMutation = deleteTodoGroup(todo.id);
          return TodoItem(
            todo: todo,
            deleteMutation: deleteMutation,
          );
        },
      ),
    );
  }
}

class TodoItem extends StatefulWidget {
  final Todo todo;
  final Mutation<void> deleteMutation;

  const TodoItem({
    super.key,
    required this.todo,
    required this.deleteMutation,
  });

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  @override
  dispose() {
    // widget.deleteMutation.dispose(); //forceDispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<Mutation<void>, MutationState<void>>(
      provider: widget.deleteMutation,
      builder: (context, state, child) {
        return ListTile(
          leading: state.when(
            idle: () => IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => widget.deleteMutation
                  .run(() => Api.deleteTodo(widget.todo.id)),
            ),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            success: (_) => const Icon(Icons.check, color: Colors.green),
            error: (err, st) => IconButton(
              icon: const Icon(Icons.error, color: Colors.red),
              onPressed: () {},
            ),
          ),
          title: Text(widget.todo.title),
        );
      },
    );
  }
}
