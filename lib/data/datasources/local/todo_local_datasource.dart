import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../models/todo_model.dart';

class TodoLocalDatasource {
  final DatabaseHelper _db;
  TodoLocalDatasource(this._db);

  Future<Database> get _database => _db.database;

  Future<List<TodoModel>> getTodosByTrip(String tripId) async {
    final db = await _database;
    final rows = await db.query('todos',
        where: 'trip_id = ? AND is_deleted = ?',
        whereArgs: [tripId, 0],
        orderBy: 'created_at ASC');
    return rows.map(TodoModel.fromDb).toList();
  }

  Future<void> upsertTodo(TodoModel todo) async {
    final db = await _database;
    await db.insert('todos', todo.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTodo(String id) async {
    final db = await _database;
    await db.update(
        'todos',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    final db = await _database;
    await db.update(
        'todos',
        {'is_done': isDone ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }
}
