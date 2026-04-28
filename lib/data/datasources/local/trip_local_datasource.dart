import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../models/trip_model.dart';

class TripLocalDatasource {
  final DatabaseHelper _db;
  TripLocalDatasource(this._db);

  Future<Database> get _database => _db.database;

  Future<List<TripModel>> getAllTrips() async {
    final db = await _database;
    final rows = await db.query('trips',
        where: 'is_deleted = ?', whereArgs: [0], orderBy: 'created_at DESC');
    return rows.map(TripModel.fromDb).toList();
  }

  Future<TripModel?> getTripById(String id) async {
    final db = await _database;
    final rows =
        await db.query('trips', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TripModel.fromDb(rows.first);
  }

  Future<void> upsertTrip(TripModel trip) async {
    final db = await _database;
    await db.insert('trips', trip.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTrip(String id) async {
    final db = await _database;
    await db.update('trips', {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hardDeleteTrip(String id) async {
    final db = await _database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }
}
