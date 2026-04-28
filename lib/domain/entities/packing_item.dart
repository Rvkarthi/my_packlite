import 'package:flutter/foundation.dart';

enum ShareStatus { personal, sharing, needed }

@immutable
class PackingItem {
  final String id;
  final String name;
  final String category;
  final bool isSelected;
  final bool isPacked;
  final int sortOrder;
  final String? bagId;
  final bool needsToBuy;
  final String? tripId;
  final String? assignedTo;
  final ShareStatus shareStatus;
  final String? sharedBy;
  final String? neededBy;
  final DateTime? claimedAt;
  final String providerName;
  final bool isDeleted;
  final DateTime? updatedAt;

  const PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.isSelected = false,
    this.isPacked = false,
    this.sortOrder = 0,
    this.bagId,
    this.needsToBuy = false,
    this.tripId,
    this.assignedTo,
    this.shareStatus = ShareStatus.personal,
    this.sharedBy,
    this.neededBy,
    this.claimedAt,
    this.providerName = '',
    this.isDeleted = false,
    this.updatedAt,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSelected,
    bool? isPacked,
    int? sortOrder,
    String? bagId,
    bool? needsToBuy,
    String? tripId,
    String? assignedTo,
    ShareStatus? shareStatus,
    String? sharedBy,
    String? neededBy,
    DateTime? claimedAt,
    String? providerName,
    bool? isDeleted,
    DateTime? updatedAt,
    bool clearBagId = false,
    bool clearAssignedTo = false,
    bool clearProviderName = false,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      isPacked: isPacked ?? this.isPacked,
      sortOrder: sortOrder ?? this.sortOrder,
      bagId: clearBagId ? null : (bagId ?? this.bagId),
      needsToBuy: needsToBuy ?? this.needsToBuy,
      tripId: tripId ?? this.tripId,
      assignedTo: clearAssignedTo ? null : (assignedTo ?? this.assignedTo),
      shareStatus: shareStatus ?? this.shareStatus,
      sharedBy: sharedBy ?? this.sharedBy,
      neededBy: neededBy ?? this.neededBy,
      claimedAt: claimedAt ?? this.claimedAt,
      providerName: clearProviderName ? '' : (providerName ?? this.providerName),
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'isSelected': isSelected ? 1 : 0,
        'isPacked': isPacked ? 1 : 0,
        'sortOrder': sortOrder,
        'bagId': bagId,
        'needsToBuy': needsToBuy ? 1 : 0,
        'tripId': tripId,
        'assignedTo': assignedTo,
        'shareStatus': shareStatus.name,
        'sharedBy': sharedBy,
        'neededBy': neededBy,
        'claimedAt': claimedAt?.toIso8601String(),
        'providerName': providerName,
        'isDeleted': isDeleted ? 1 : 0,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory PackingItem.fromJson(Map<String, dynamic> json) => PackingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? 'General',
        isSelected: (json['isSelected'] == 1 || json['isSelected'] == true),
        isPacked: (json['isPacked'] == 1 || json['isPacked'] == true),
        sortOrder: (json['sortOrder'] as int?) ?? 0,
        bagId: json['bagId'] as String?,
        needsToBuy: (json['needsToBuy'] == 1 || json['needsToBuy'] == true),
        tripId: json['tripId'] as String?,
        assignedTo: json['assignedTo'] as String?,
        shareStatus: ShareStatus.values.firstWhere(
          (e) => e.name == json['shareStatus'],
          orElse: () => ShareStatus.personal,
        ),
        sharedBy: json['sharedBy'] as String?,
        neededBy: json['neededBy'] as String?,
        claimedAt: json['claimedAt'] != null
            ? DateTime.tryParse(json['claimedAt'] as String)
            : null,
        providerName: (json['providerName'] as String?) ?? '',
        isDeleted: (json['isDeleted'] == 1 || json['isDeleted'] == true),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          isSelected == other.isSelected &&
          isPacked == other.isPacked &&
          sortOrder == other.sortOrder &&
          bagId == other.bagId &&
          shareStatus == other.shareStatus &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(
        id, name, category, isSelected, isPacked, sortOrder, bagId, shareStatus, isDeleted);

  @override
  String toString() => 'PackingItem(id: $id, name: $name, isPacked: $isPacked)';
}
