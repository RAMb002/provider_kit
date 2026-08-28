class Api {
  static Future<void> deleteTodo(int id) async {
    await Future.delayed(const Duration(seconds: 2));
    if (id == 2) throw Exception('Failed to delete todo 2');
  }

  static Future<int> addTodo(String title) async {
    await Future.delayed(const Duration(seconds: 2));
    if (title.isEmpty) throw Exception('Title cannot be empty');
    return DateTime.now().millisecondsSinceEpoch; // fake id
  }
}

class Todo {
  final int id;
  final String title;
  const Todo(this.id, this.title);
}
