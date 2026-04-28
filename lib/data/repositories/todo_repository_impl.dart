import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/local/todo_local_datasource.dart';
import '../models/todo_model.dart';
import '../../services/sync/sync_service.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDatasource _local;
  final SyncService _sync;

  TodoRepositoryImpl(this._local, this._sync);

  @override
  Future<List<Todo>> getTodosByTrip(String tripId) async {
    final models = await _local.getTodosByTrip(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Todo> createTodo(Todo todo) async {
    final model = TodoModel.fromEntity(todo);
    await _local.upsertTodo(model);
    if (todo.isGroup) {
      _sync.queueWrite('todos', todo.id, 'upsert', model.toFirestore());
    }
    return todo;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    final updated = todo.copyWith(updatedAt: DateTime.now());
    final model = TodoModel.fromEntity(updated);
    await _local.upsertTodo(model);
    if (todo.isGroup) {
      _sync.queueWrite('todos', todo.id, 'upsert', model.toFirestore());
    }
    return updated;
  }

  @override
  Future<void> deleteTodo(String id) async {
    await _local.deleteTodo(id);
    _sync.queueWrite('todos', id, 'delete', {'isDeleted': true});
  }

  @override
  Future<void> toggleTodo(String id, bool isDone) async {
    await _local.toggleTodo(id, isDone);
    _sync.queueWrite('todos', id, 'upsert', {
      'isDone': isDone,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
