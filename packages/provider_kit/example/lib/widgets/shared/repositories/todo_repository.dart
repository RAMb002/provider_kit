class Todo {
  const Todo({
    required this.id,
    required this.title,
  });

  final int id;
  final String title;
}

class TodoRepository {
  final List<Todo> _todos = [
    const Todo(id: 1, title: 'Review pull requests'),
    const Todo(id: 2, title: 'Update documentation'),
    const Todo(id: 3, title: 'Fix navigation issue'),
    const Todo(id: 4, title: 'Prepare release notes'),
    const Todo(id: 5, title: 'Write unit tests'),
  ];

  Future<List<Todo>> fetchTodos() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_todos);
  }

  Future<void> deleteTodo(int id) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _todos.removeWhere((todo) => todo.id == id);
  }
}
