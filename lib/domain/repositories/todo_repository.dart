import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodosByTrip(String tripId);
  Future<Todo> createTodo(Todo todo);
  Future<Todo> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
  Future<void> toggleTodo(String id, bool isDone);
}
