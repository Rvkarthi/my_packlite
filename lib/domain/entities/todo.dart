import 'package:flutter/foundation.dart';

@immutable
class Todo {
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

  const Todo({
    required this.id,
    required this.tripId,
    required this.title,
    this.isDone = false,
    this.isGroup = false,
    this.assignedTo,
    this.dueDate,
    this.isDeleted = false,
    this.updatedAt,
    this.createdAt,
  });

  Todo copyWith({
    String? id,
    String? tripId,
    String? title,
    bool? isDone,
    bool? isGroup,
    String? assignedTo,
    DateTime? dueDate,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? createdAt,
    bool clearAssignedTo = false,
    bool clearDueDate = false,
  }) {
    return Todo(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      isGroup: isGroup ?? this.isGroup,
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'isGroup': isGroup ? 1 : 0,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'isDeleted': isDeleted ? 1 : 0,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        title: json['title'] as String,
        isDone: (json['isDone'] == 1 || json['isDone'] == true),
        isGroup: (json['isGroup'] == 1 || json['isGroup'] == true),
        assignedTo: json['assignedTo'] as String?,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
        isDeleted: (json['isDeleted'] == 1 || json['isDeleted'] == true),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tripId == other.tripId &&
          title == other.title &&
          isDone == other.isDone &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(id, tripId, title, isDone, isDeleted);

  @override
  String toString() => 'Todo(id: $id, title: $title, isDone: $isDone)';
}
