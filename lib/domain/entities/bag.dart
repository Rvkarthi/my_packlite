import 'package:flutter/foundation.dart';

enum ShareStatus { personal, sharing, needed }

@immutable
class Bag {
  final String id;
  final String name;
  final String color;
  final String icon;
  final int sortOrder;
  final String? tripId;
  final bool isDeleted;
  final DateTime? updatedAt;

  const Bag({
    required this.id,
    required this.name,
    this.color = '#4CAF50',
    this.icon = 'luggage',
    this.sortOrder = 0,
    this.tripId,
    this.isDeleted = false,
    this.updatedAt,
  });

  Bag copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    int? sortOrder,
    String? tripId,
    bool? isDeleted,
    DateTime? updatedAt,
    bool clearTripId = false,
  }) {
    return Bag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      tripId: clearTripId ? null : (tripId ?? this.tripId),
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'sortOrder': sortOrder,
        'tripId': tripId,
        'isDeleted': isDeleted ? 1 : 0,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Bag.fromJson(Map<String, dynamic> json) => Bag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: (json['color'] as String?) ?? '#4CAF50',
        icon: (json['icon'] as String?) ?? 'luggage',
        sortOrder: (json['sortOrder'] as int?) ?? 0,
        tripId: json['tripId'] as String?,
        isDeleted: (json['isDeleted'] == 1 || json['isDeleted'] == true),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color &&
          icon == other.icon &&
          sortOrder == other.sortOrder &&
          tripId == other.tripId &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(id, name, color, icon, sortOrder, tripId, isDeleted);

  @override
  String toString() => 'Bag(id: $id, name: $name, tripId: $tripId)';
}
