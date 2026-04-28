import 'package:flutter/foundation.dart';

@immutable
class PackingTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> itemNames;
  final List<String> categories;
  final DateTime? createdAt;
  final bool isBuiltIn;

  const PackingTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.itemNames = const [],
    this.categories = const [],
    this.createdAt,
    this.isBuiltIn = false,
  });

  PackingTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? itemNames,
    List<String>? categories,
    DateTime? createdAt,
    bool? isBuiltIn,
  }) {
    return PackingTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemNames: itemNames ?? this.itemNames,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'itemNames': itemNames,
        'categories': categories,
        'createdAt': createdAt?.toIso8601String(),
        'isBuiltIn': isBuiltIn ? 1 : 0,
      };

  factory PackingTemplate.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw is List) return raw.cast<String>();
      if (raw is String && raw.isNotEmpty) {
        // stored as comma-separated in SQLite
        return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return PackingTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      itemNames: parseStringList(json['itemNames']),
      categories: parseStringList(json['categories']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      isBuiltIn: (json['isBuiltIn'] == 1 || json['isBuiltIn'] == true),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'PackingTemplate(id: $id, name: $name)';
}
