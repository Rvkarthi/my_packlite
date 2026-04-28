import 'dart:convert';
import '../../domain/entities/trip.dart';

class TripModel {
  final String id;
  final String title;
  final List<TripLocation> locations;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripType type;
  final String? templateId;
  final String? groupId;
  final String? coverImageUrl;
  final bool isDeleted;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const TripModel({
    required this.id,
    required this.title,
    required this.locations,
    this.startDate,
    this.endDate,
    required this.type,
    this.templateId,
    this.groupId,
    this.coverImageUrl,
    required this.isDeleted,
    this.updatedAt,
    this.createdAt,
  });

  factory TripModel.fromDb(Map<String, dynamic> row) {
    final locationsJson = row['locations'] as String? ?? '[]';
    final locationsList = (jsonDecode(locationsJson) as List)
        .map((e) => TripLocation.fromJson(e as Map<String, dynamic>))
        .toList();
    return TripModel(
      id: row['id'] as String,
      title: row['title'] as String,
      locations: locationsList,
      startDate: row['start_date'] != null
          ? DateTime.tryParse(row['start_date'] as String)
          : null,
      endDate: row['end_date'] != null
          ? DateTime.tryParse(row['end_date'] as String)
          : null,
      type: row['type'] == 'group' ? TripType.group : TripType.individual,
      templateId: row['template_id'] as String?,
      groupId: row['group_id'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'title': title,
        'locations': jsonEncode(locations.map((l) => l.toJson()).toList()),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'type': type.name,
        'template_id': templateId,
        'group_id': groupId,
        'cover_image_url': coverImageUrl,
        'is_deleted': isDeleted ? 1 : 0,
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  Trip toEntity() => Trip(
        id: id,
        title: title,
        locations: locations,
        startDate: startDate,
        endDate: endDate,
        type: type,
        templateId: templateId,
        groupId: groupId,
        coverImageUrl: coverImageUrl,
        isDeleted: isDeleted,
        updatedAt: updatedAt,
        createdAt: createdAt,
      );

  factory TripModel.fromEntity(Trip trip) => TripModel(
        id: trip.id,
        title: trip.title,
        locations: trip.locations,
        startDate: trip.startDate,
        endDate: trip.endDate,
        type: trip.type,
        templateId: trip.templateId,
        groupId: trip.groupId,
        coverImageUrl: trip.coverImageUrl,
        isDeleted: trip.isDeleted,
        updatedAt: trip.updatedAt,
        createdAt: trip.createdAt,
      );

  factory TripModel.fromFirestore(Map<String, dynamic> data, String id) {
    final locationsRaw = data['locations'] as List? ?? [];
    final locations = locationsRaw
        .map((e) => TripLocation.fromJson(e as Map<String, dynamic>))
        .toList();
    return TripModel(
      id: id,
      title: data['title'] as String? ?? '',
      locations: locations,
      startDate: data['startDate'] != null
          ? DateTime.tryParse(data['startDate'] as String)
          : null,
      endDate: data['endDate'] != null
          ? DateTime.tryParse(data['endDate'] as String)
          : null,
      type: data['type'] == 'group' ? TripType.group : TripType.individual,
      templateId: data['templateId'] as String?,
      groupId: data['groupId'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'locations': locations.map((l) => l.toJson()).toList(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'type': type.name,
        'templateId': templateId,
        'groupId': groupId,
        'coverImageUrl': coverImageUrl,
        'isDeleted': isDeleted,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
