import 'package:flutter/foundation.dart';

/// A freeform object stored inside a container (bag).
/// Unlike PackingItems (which come from the catalog/trip),
/// ContainerObjects are arbitrary things the user adds directly to a bag.
@immutable
class ContainerObject {
  final String id;
  final String bagId;
  final String name;
  final String? description;
  final String category;
  final int quantity;
  final double? weightKg;
  final bool isPacked;
  final String? notes;
  final DateTime? updatedAt;

  const ContainerObject({
    required this.id,
    required this.bagId,
    required this.name,
    this.description,
    this.category = 'General',
    this.quantity = 1,
    this.weightKg,
    this.isPacked = false,
    this.notes,
    this.updatedAt,
  });

  ContainerObject copyWith({
    String? id,
    String? bagId,
    String? name,
    String? description,
    String? category,
    int? quantity,
    double? weightKg,
    bool? isPacked,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ContainerObject(
      id: id ?? this.id,
      bagId: bagId ?? this.bagId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      weightKg: weightKg ?? this.weightKg,
      isPacked: isPacked ?? this.isPacked,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bagId': bagId,
        'name': name,
        'description': description,
        'category': category,
        'quantity': quantity,
        'weightKg': weightKg,
        'isPacked': isPacked ? 1 : 0,
        'notes': notes,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ContainerObject.fromJson(Map<String, dynamic> json) =>
      ContainerObject(
        id: json['id'] as String,
        bagId: json['bagId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: (json['category'] as String?) ?? 'General',
        quantity: (json['quantity'] as int?) ?? 1,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        isPacked: (json['isPacked'] == 1 || json['isPacked'] == true),
        notes: json['notes'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContainerObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bagId == other.bagId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, bagId, name);

  @override
  String toString() => 'ContainerObject(id: $id, name: $name, bagId: $bagId)';
}
