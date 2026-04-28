import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../models/bag_model.dart';

class BagLocalDatasource {
  final DatabaseHelper _db;
  BagLocalDatasource(this._db);

  Future<Database> get _database => _db.database;

  Future<List<BagModel>> getBagsByTrip(String tripId) async {
    final db = await _database;
    final rows = await db.query('bags',
        where: 'trip_id = ? AND is_deleted = ?',
        whereArgs: [tripId, 0],
        orderBy: 'sort_order ASC');
    return rows.map(BagModel.fromDb).toList();
  }

  Future<void> upsertBag(BagModel bag) async {
    final db = await _database;
    await db.insert('bags', bag.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBag(String id) async {
    final db = await _database;
    await db.update(
        'bags',
        {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id]);
  }
}
