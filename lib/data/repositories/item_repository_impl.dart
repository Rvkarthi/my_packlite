import '../../domain/entities/packing_item.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/local/item_local_datasource.dart';
import '../models/packing_item_model.dart';
import '../../services/sync/sync_service.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ItemLocalDatasource _local;
  final SyncService _sync;

  ItemRepositoryImpl(this._local, this._sync);

  @override
  Future<List<PackingItem>> getItemsByTrip(String tripId) async {
    final models = await _local.getItemsByTrip(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PackingItem>> getAllItems() async {
    final models = await _local.getAllItems();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PackingItem> createItem(PackingItem item) async {
    final model = PackingItemModel.fromEntity(item);
    await _local.upsertItem(model);
    _sync.queueWrite('packing_items', item.id, 'upsert', model.toFirestore());
    return item;
  }

  @override
  Future<PackingItem> updateItem(PackingItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    final model = PackingItemModel.fromEntity(updated);
    await _local.upsertItem(model);
    _sync.queueWrite('packing_items', item.id, 'upsert', model.toFirestore());
    return updated;
  }

  @override
  Future<void> deleteItem(String id) async {
    await _local.deleteItem(id);
    _sync.queueWrite('packing_items', id, 'delete', {'isDeleted': true});
  }

  @override
  Future<void> resetPackedStatus(String tripId) async {
    await _local.resetPackedStatus(tripId);
  }

  @override
  Future<void> updateSortOrders(List<PackingItem> items) async {
    final updates = items
        .map((i) => {'id': i.id, 'sort_order': i.sortOrder})
        .toList();
    await _local.updateSortOrders(updates);
  }

  @override
  Future<List<PackingItem>> getShoppingItems() async {
    final models = await _local.getShoppingItems();
    return models.map((m) => m.toEntity()).toList();
  }
}
