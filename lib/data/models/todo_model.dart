import '../../domain/entities/todo.dart';

class TodoModel {
  final String id;
  final String tripId;
  final String title;
  final bool isDone;
  final bool isGroup;
  final String? assignedTo;
  final DateTime? dueDate;
  final bool isDeleted;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const TodoModel({
    required this.id,
    required this.tripId,
    required this.title,
    required this.isDone,
    required this.isGroup,
    this.assignedTo,
    this.dueDate,
    required this.isDeleted,
    this.updatedAt,
    this.createdAt,
  });

  factory TodoModel.fromDb(Map<String, dynamic> row) => TodoModel(
        id: row['id'] as String,
        tripId: row['trip_id'] as String,
        title: row['title'] as String,
        isDone: (row['is_done'] as int? ?? 0) == 1,
        isGroup: (row['is_group'] as int? ?? 0) == 1,
        assignedTo: row['assigned_to'] as String?,
        dueDate: row['due_date'] != null
            ? DateTime.tryParse(row['due_date'] as String)
            : null,
        isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
        updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toDb() => {
        'id': id,
        'trip_id': tripId,
        'title': title,
        'is_done': isDone ? 1 : 0,
        'is_group': isGroup ? 1 : 0,
        'assigned_to': assignedTo,
        'due_date': dueDate?.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  Todo toEntity() => Todo(
        id: id,
        tripId: tripId,
        title: title,
        isDone: isDone,
        isGroup: isGroup,
        assignedTo: assignedTo,
        dueDate: dueDate,
        isDeleted: isDeleted,
        updatedAt: updatedAt,
        createdAt: createdAt,
      );

  factory TodoModel.fromEntity(Todo todo) => TodoModel(
        id: todo.id,
        tripId: todo.tripId,
        title: todo.title,
        isDone: todo.isDone,
        isGroup: todo.isGroup,
        assignedTo: todo.assignedTo,
        dueDate: todo.dueDate,
        isDeleted: todo.isDeleted,
        updatedAt: todo.updatedAt,
        createdAt: todo.createdAt,
      );

  factory TodoModel.fromFirestore(Map<String, dynamic> data, String id) =>
      TodoModel(
        id: id,
        tripId: data['tripId'] as String? ?? '',
        title: data['title'] as String? ?? '',
        isDone: data['isDone'] as bool? ?? false,
        isGroup: data['isGroup'] as bool? ?? false,
        assignedTo: data['assignedTo'] as String?,
        dueDate: data['dueDate'] != null
            ? DateTime.tryParse(data['dueDate'] as String)
            : null,
        isDeleted: data['isDeleted'] as bool? ?? false,
        updatedAt: data['updatedAt'] != null
            ? DateTime.tryParse(data['updatedAt'] as String)
            : null,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toFirestore() => {
        'tripId': tripId,
        'title': title,
        'isDone': isDone,
        'isGroup': isGroup,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'isDeleted': isDeleted,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
