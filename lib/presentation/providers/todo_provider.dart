import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/todo.dart';

final todoTabProvider = NotifierProvider<_IntNotifier, int>(_IntNotifier.new);

class _IntNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setTab(int i) => state = i;
}

// Riverpod 3.x family: factory receives arg, notifier stores it
final tripTodosProvider =
    AsyncNotifierProvider.family<TripTodosNotifier, List<Todo>, String>(
        (arg) => TripTodosNotifier(arg));

class TripTodosNotifier extends AsyncNotifier<List<Todo>> {
  final String _tripId;
  TripTodosNotifier(this._tripId);

  String get tripId => _tripId;

  @override
  Future<List<Todo>> build() async {
    return ref.read(todoRepositoryProvider).getTodosByTrip(_tripId);
  }

  Future<void> addTodo({
    required String title,
    bool isGroup = false,
    String? assignedTo,
    DateTime? dueDate,
  }) async {
    final todo = Todo(
      id: const Uuid().v4(),
      tripId: _tripId,
      title: title,
      isGroup: isGroup,
      assignedTo: assignedTo,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final current = state.value ?? [];
    state = AsyncData([...current, todo]);
    try {
      await ref.read(todoRepositoryProvider).createTodo(todo);
    } catch (_) {
      await _reload();
    }
  }

  Future<void> toggleTodo(String id) async {
    final current = state.value ?? [];
    final todo = current.firstWhere((t) => t.id == id);
    final updated = todo.copyWith(isDone: !todo.isDone);
    state = AsyncData(current.map((t) => t.id == id ? updated : t).toList());
    await ref.read(todoRepositoryProvider).toggleTodo(id, updated.isDone);
  }

  Future<void> updateTodo(Todo todo) async {
    final current = state.value ?? [];
    state = AsyncData(current.map((t) => t.id == todo.id ? todo : t).toList());
    await ref.read(todoRepositoryProvider).updateTodo(todo);
  }

  Future<void> deleteTodo(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != id).toList());
    await ref.read(todoRepositoryProvider).deleteTodo(id);
  }

  Future<void> _reload() async {
    state = AsyncData(
        await ref.read(todoRepositoryProvider).getTodosByTrip(_tripId));
  }
}
