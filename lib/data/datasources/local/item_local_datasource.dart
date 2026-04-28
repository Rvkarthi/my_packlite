import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../models/packing_item_model.dart';

class ItemLocalDatasource {
  final DatabaseHelper _db;
  ItemLocalDatasource(this._db);

  Future<Database> get _database => _db.database;

  Future<List<PackingItemModel>> getItemsByTrip(String tripId) async {
    final db = await _database;
    final rows = await db.query('packing_items',
        where: 'trip_id = ? AND is_deleted = ?',
        whereArgs: [tripId, 0],
        orderBy: 'sort_order ASC');
    return rows.map(PackingItemModel.fromDb).toList();
  }

  Future<List<PackingItemModel>> getAllItems() async {
    final db = await _database;
    final rows = await db.query('packing_items',
        where: 'is_deleted = ?', whereArgs: [0], orderBy: 'sort_order ASC');
    return rows.map(PackingItemModel.fromDb).toList();
  }

  Future<List<PackingItemModel>> getShoppingItems() async {
    final db = await _database;
    final rows = await db.query('packing_items',
        where: 'needs_to_buy = ? AND is_deleted = ?',
        whereArgs: [1, 0]);
    return rows.map(PackingItemModel.fromDb).toList();
  }

  Future<void> upsertItem(PackingItemModel item) async {
    final db = await _database;
    await db.insert('packing_items', item.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertItems(List<PackingItemModel> items) async {
    final db = await _database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('packing_items', item.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItem(String id) async {
    final db = await _database;
    await db.update(
        'packing_items',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> resetPackedStatus(String tripId) async {
    final db = await _database;
    await db.update(
        'packing_items',
        {'is_packed': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'trip_id = ? AND is_deleted = ?',
        whereArgs: [tripId, 0]);
  }

  Future<void> updateSortOrders(List<Map<String, dynamic>> updates) async {
    final db = await _database;
    final batch = db.batch();
    for (final u in updates) {
      batch.update('packing_items', {'sort_order': u['sort_order']},
          where: 'id = ?', whereArgs: [u['id']]);
    }
    await batch.commit(noResult: true);
  }
}
