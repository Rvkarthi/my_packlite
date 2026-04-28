import '../../domain/entities/packing_item.dart';

class PackingItemModel {
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

  const PackingItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isSelected,
    required this.isPacked,
    required this.sortOrder,
    this.bagId,
    required this.needsToBuy,
    this.tripId,
    this.assignedTo,
    required this.shareStatus,
    this.sharedBy,
    this.neededBy,
    this.claimedAt,
    required this.providerName,
    required this.isDeleted,
    this.updatedAt,
  });

  factory PackingItemModel.fromDb(Map<String, dynamic> row) {
    ShareStatus status;
    switch (row['share_status'] as String? ?? 'personal') {
      case 'sharing':
        status = ShareStatus.sharing;
        break;
      case 'needed':
        status = ShareStatus.needed;
        break;
      default:
        status = ShareStatus.personal;
    }
    return PackingItemModel(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      isSelected: (row['is_selected'] as int? ?? 0) == 1,
      isPacked: (row['is_packed'] as int? ?? 0) == 1,
      sortOrder: row['sort_order'] as int? ?? 0,
      bagId: row['bag_id'] as String?,
      needsToBuy: (row['needs_to_buy'] as int? ?? 0) == 1,
      tripId: row['trip_id'] as String?,
      assignedTo: row['assigned_to'] as String?,
      shareStatus: status,
      sharedBy: row['shared_by'] as String?,
      neededBy: row['needed_by'] as String?,
      claimedAt: row['claimed_at'] != null
          ? DateTime.tryParse(row['claimed_at'] as String)
          : null,
      providerName: row['provider_name'] as String? ?? '',
      isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'category': category,
        'is_selected': isSelected ? 1 : 0,
        'is_packed': isPacked ? 1 : 0,
        'sort_order': sortOrder,
        'bag_id': bagId,
        'needs_to_buy': needsToBuy ? 1 : 0,
        'trip_id': tripId,
        'assigned_to': assignedTo,
        'share_status': shareStatus.name,
        'shared_by': sharedBy,
        'needed_by': neededBy,
        'claimed_at': claimedAt?.toIso8601String(),
        'provider_name': providerName,
        'is_deleted': isDeleted ? 1 : 0,
        'updated_at': updatedAt?.toIso8601String(),
      };

  PackingItem toEntity() => PackingItem(
        id: id,
        name: name,
        category: category,
        isSelected: isSelected,
        isPacked: isPacked,
        sortOrder: sortOrder,
        bagId: bagId,
        needsToBuy: needsToBuy,
        tripId: tripId,
        assignedTo: assignedTo,
        shareStatus: shareStatus,
        sharedBy: sharedBy,
        neededBy: neededBy,
        claimedAt: claimedAt,
        providerName: providerName,
        isDeleted: isDeleted,
        updatedAt: updatedAt,
      );

  factory PackingItemModel.fromEntity(PackingItem item) => PackingItemModel(
        id: item.id,
        name: item.name,
        category: item.category,
        isSelected: item.isSelected,
        isPacked: item.isPacked,
        sortOrder: item.sortOrder,
        bagId: item.bagId,
        needsToBuy: item.needsToBuy,
        tripId: item.tripId,
        assignedTo: item.assignedTo,
        shareStatus: item.shareStatus,
        sharedBy: item.sharedBy,
        neededBy: item.neededBy,
        claimedAt: item.claimedAt,
        providerName: item.providerName,
        isDeleted: item.isDeleted,
        updatedAt: item.updatedAt,
      );

  factory PackingItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    ShareStatus status;
    switch (data['shareStatus'] as String? ?? 'personal') {
      case 'sharing':
        status = ShareStatus.sharing;
        break;
      case 'needed':
        status = ShareStatus.needed;
        break;
      default:
        status = ShareStatus.personal;
    }
    return PackingItemModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      isSelected: data['isSelected'] as bool? ?? false,
      isPacked: data['isPacked'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      bagId: data['bagId'] as String?,
      needsToBuy: data['needsToBuy'] as bool? ?? false,
      tripId: data['tripId'] as String?,
      assignedTo: data['assignedTo'] as String?,
      shareStatus: status,
      sharedBy: data['sharedBy'] as String?,
      neededBy: data['neededBy'] as String?,
      claimedAt: data['claimedAt'] != null
          ? DateTime.tryParse(data['claimedAt'] as String)
          : null,
      providerName: data['providerName'] as String? ?? '',
      isDeleted: data['isDeleted'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'isSelected': isSelected,
        'isPacked': isPacked,
        'sortOrder': sortOrder,
        'bagId': bagId,
        'needsToBuy': needsToBuy,
        'tripId': tripId,
        'assignedTo': assignedTo,
        'shareStatus': shareStatus.name,
        'sharedBy': sharedBy,
        'neededBy': neededBy,
        'claimedAt': claimedAt?.toIso8601String(),
        'providerName': providerName,
        'isDeleted': isDeleted,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
