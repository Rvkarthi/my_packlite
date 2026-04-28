import '../../domain/entities/bag.dart';

class BagModel {
  final String id;
  final String name;
  final String color;
  final String icon;
  final int sortOrder;
  final String? tripId;
  final bool isDeleted;
  final DateTime? updatedAt;

  const BagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.sortOrder,
    this.tripId,
    required this.isDeleted,
    this.updatedAt,
  });

  factory BagModel.fromDb(Map<String, dynamic> row) => BagModel(
        id: row['id'] as String,
        name: row['name'] as String,
        color: row['color'] as String? ?? '#4CAF50',
        icon: row['icon'] as String? ?? 'luggage',
        sortOrder: row['sort_order'] as int? ?? 0,
        tripId: row['trip_id'] as String?,
        isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
        updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'sort_order': sortOrder,
        'trip_id': tripId,
        'is_deleted': isDeleted ? 1 : 0,
        'updated_at': updatedAt?.toIso8601String(),
      };

  Bag toEntity() => Bag(
        id: id,
        name: name,
        color: color,
        icon: icon,
        sortOrder: sortOrder,
        tripId: tripId,
        isDeleted: isDeleted,
        updatedAt: updatedAt,
      );

  factory BagModel.fromEntity(Bag bag) => BagModel(
        id: bag.id,
        name: bag.name,
        color: bag.color,
        icon: bag.icon,
        sortOrder: bag.sortOrder,
        tripId: bag.tripId,
        isDeleted: bag.isDeleted,
        updatedAt: bag.updatedAt,
      );
}
