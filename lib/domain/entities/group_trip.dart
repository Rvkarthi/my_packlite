import 'package:flutter/foundation.dart';

@immutable
class GroupMember {
  final String id;
  final String name;
  final String avatarColor;
  final bool isDependent;
  final String? managedBy;
  final String? deviceId;

  const GroupMember({
    required this.id,
    required this.name,
    this.avatarColor = '#4CAF50',
    this.isDependent = false,
    this.managedBy,
    this.deviceId,
  });

  GroupMember copyWith({
    String? id,
    String? name,
    String? avatarColor,
    bool? isDependent,
    String? managedBy,
    String? deviceId,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      isDependent: isDependent ?? this.isDependent,
      managedBy: managedBy ?? this.managedBy,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarColor': avatarColor,
        'isDependent': isDependent,
        'managedBy': managedBy,
        'deviceId': deviceId,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarColor: (json['avatarColor'] as String?) ?? '#4CAF50',
        isDependent: (json['isDependent'] == true || json['isDependent'] == 1),
        managedBy: json['managedBy'] as String?,
        deviceId: json['deviceId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'GroupMember(id: $id, name: $name)';
}

@immutable
class GroupTrip {
  final String id;
  final String inviteCode;
  final String organizerId;
  final String tripId;
  final List<GroupMember> members;
  final DateTime? createdAt;

  const GroupTrip({
    required this.id,
    required this.inviteCode,
    required this.organizerId,
    required this.tripId,
    this.members = const [],
    this.createdAt,
  });

  GroupTrip copyWith({
    String? id,
    String? inviteCode,
    String? organizerId,
    String? tripId,
    List<GroupMember>? members,
    DateTime? createdAt,
  }) {
    return GroupTrip(
      id: id ?? this.id,
      inviteCode: inviteCode ?? this.inviteCode,
      organizerId: organizerId ?? this.organizerId,
      tripId: tripId ?? this.tripId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'inviteCode': inviteCode,
        'organizerId': organizerId,
        'tripId': tripId,
        'members': members.map((m) => m.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory GroupTrip.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    List<GroupMember> members = [];
    if (rawMembers is List) {
      members = rawMembers
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return GroupTrip(
      id: json['id'] as String,
      inviteCode: json['inviteCode'] as String,
      organizerId: json['organizerId'] as String,
      tripId: json['tripId'] as String,
      members: members,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupTrip &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inviteCode == other.inviteCode;

  @override
  int get hashCode => Object.hash(id, inviteCode);

  @override
  String toString() => 'GroupTrip(id: $id, inviteCode: $inviteCode)';
}
