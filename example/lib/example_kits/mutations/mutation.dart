import 'package:example/example_kits/mutations/data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class MutationExample extends StatelessWidget {
  const MutationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: ChangeNotifierProvider(
        create: (_) => TodoNotifier(),
        child: const _TodoListScreen(),
      ),
    );
  }
}

class _TodoListScreen extends StatefulWidget {
  const _TodoListScreen();

  @override
  State<_TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<_TodoListScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoNotifier>();
    final todos = notifier.state;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Enter todo'),
                ),
              ),
              const SizedBox(width: 8),
              StateBuilder<Mutation<int>, MutationState<int>>(
                provider: notifier.addMutation,
                builder: (context, state, child) {
                  return state.when(
                    idle: () => ElevatedButton(
                      onPressed: () {
                        final title = _controller.text;
                        if (title.isNotEmpty) {
                          notifier.addTodo(title);
                          _controller.clear();
                        }
                      },
                      child: const Text('Add'),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    success: (_) =>
                        const Icon(Icons.check, color: Colors.green),
                    error: (err, st) => IconButton(
                      icon: const Icon(Icons.error, color: Colors.red),
                      onPressed: () {
                        notifier.addMutation.reset();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(title: Text(todo.title));
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TodoNotifier extends StateNotifier<List<Todo>> {
  final Mutation<int> _addMutation = Mutation<int>();

  TodoNotifier() : super([]);

  Mutation<int> get addMutation => _addMutation;

  Future<void> addTodo(String title) async {
    final newId = await _addMutation.run(() => Api.addTodo(title));
    state = [...state, Todo(newId, title)];
  }

  @override
  void dispose() {
    _addMutation.dispose();
    super.dispose();
  }
}
