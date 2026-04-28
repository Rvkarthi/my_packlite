import 'package:flutter/foundation.dart';

enum TripType { individual, group }

@immutable
class TripLocation {
  final String name;
  final String? country;
  final double? lat;
  final double? lng;
  final DateTime? arrivalDate;
  final DateTime? departureDate;
  final double? tempCelsius;
  final String? weatherCondition;

  const TripLocation({
    required this.name,
    this.country,
    this.lat,
    this.lng,
    this.arrivalDate,
    this.departureDate,
    this.tempCelsius,
    this.weatherCondition,
  });

  TripLocation copyWith({
    String? name,
    String? country,
    double? lat,
    double? lng,
    DateTime? arrivalDate,
    DateTime? departureDate,
    double? tempCelsius,
    String? weatherCondition,
  }) {
    return TripLocation(
      name: name ?? this.name,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      departureDate: departureDate ?? this.departureDate,
      tempCelsius: tempCelsius ?? this.tempCelsius,
      weatherCondition: weatherCondition ?? this.weatherCondition,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'lat': lat,
        'lng': lng,
        'arrivalDate': arrivalDate?.toIso8601String(),
        'departureDate': departureDate?.toIso8601String(),
        'tempCelsius': tempCelsius,
        'weatherCondition': weatherCondition,
      };

  factory TripLocation.fromJson(Map<String, dynamic> json) => TripLocation(
        name: json['name'] as String,
        country: json['country'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        arrivalDate: json['arrivalDate'] != null
            ? DateTime.tryParse(json['arrivalDate'] as String)
            : null,
        departureDate: json['departureDate'] != null
            ? DateTime.tryParse(json['departureDate'] as String)
            : null,
        tempCelsius: (json['tempCelsius'] as num?)?.toDouble(),
        weatherCondition: json['weatherCondition'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLocation &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          country == other.country;

  @override
  int get hashCode => Object.hash(name, country, lat, lng);

  @override
  String toString() => 'TripLocation(name: $name, country: $country)';
}

@immutable
class Trip {
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

  const Trip({
    required this.id,
    required this.title,
    this.locations = const [],
    this.startDate,
    this.endDate,
    this.type = TripType.individual,
    this.templateId,
    this.groupId,
    this.coverImageUrl,
    this.isDeleted = false,
    this.updatedAt,
    this.createdAt,
  });

  Trip copyWith({
    String? id,
    String? title,
    List<TripLocation>? locations,
    DateTime? startDate,
    DateTime? endDate,
    TripType? type,
    String? templateId,
    String? groupId,
    String? coverImageUrl,
    bool? isDeleted,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      locations: locations ?? this.locations,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      templateId: templateId ?? this.templateId,
      groupId: groupId ?? this.groupId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'locations': locations.map((l) => l.toJson()).toList(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'type': type.name,
        'templateId': templateId,
        'groupId': groupId,
        'coverImageUrl': coverImageUrl,
        'isDeleted': isDeleted ? 1 : 0,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    List<TripLocation> locations = [];
    if (rawLocations is List) {
      locations = rawLocations
          .map((e) => TripLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (rawLocations is String && rawLocations.isNotEmpty) {
      // stored as JSON string in SQLite
      try {
        final decoded = _decodeJsonList(rawLocations);
        locations = decoded
            .map((e) => TripLocation.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      locations: locations,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      type: TripType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TripType.individual,
      ),
      templateId: json['templateId'] as String?,
      groupId: json['groupId'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      isDeleted: (json['isDeleted'] == 1 || json['isDeleted'] == true),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static List<dynamic> _decodeJsonList(String s) {
    // minimal JSON list decoder fallback — real usage goes through dart:convert
    return [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(id, title, type, isDeleted);

  @override
  String toString() => 'Trip(id: $id, title: $title, type: $type)';
}
