import '../entities/packing_item.dart';

abstract class ItemRepository {
  Future<List<PackingItem>> getItemsByTrip(String tripId);
  Future<List<PackingItem>> getAllItems();
  Future<PackingItem> createItem(PackingItem item);
  Future<PackingItem> updateItem(PackingItem item);
  Future<void> deleteItem(String id);
  Future<void> resetPackedStatus(String tripId);
  Future<void> updateSortOrders(List<PackingItem> items);
  Future<List<PackingItem>> getShoppingItems();
}
