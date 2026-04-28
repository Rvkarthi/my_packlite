import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/container_object.dart';

// Riverpod 3.x family keyed by bagId
final bagObjectsProvider =
    AsyncNotifierProvider.family<BagObjectsNotifier, List<ContainerObject>, String>(
        (arg) => BagObjectsNotifier(arg));

class BagObjectsNotifier extends AsyncNotifier<List<ContainerObject>> {
  final String _bagId;
  BagObjectsNotifier(this._bagId);

  @override
  Future<List<ContainerObject>> build() async {
    return _fetchFromDb();
  }

  Future<List<ContainerObject>> _fetchFromDb() async {
    final db = await ref.read(databaseHelperProvider).database;
    final rows = await db.query(
      'container_objects',
      where: 'bag_id = ?',
      whereArgs: [_bagId],
      orderBy: 'updated_at DESC',
    );
    return rows.map((r) => ContainerObject.fromJson(_mapRow(r))).toList();
  }

  Future<void> addObject({
    required String name,
    String? description,
    String category = 'General',
    int quantity = 1,
    double? weightKg,
    String? notes,
  }) async {
    final obj = ContainerObject(
      id: const Uuid().v4(),
      bagId: _bagId,
      name: name,
      description: description,
      category: category,
      quantity: quantity,
      weightKg: weightKg,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    final current = state.value ?? [];
    state = AsyncData([obj, ...current]);
    final db = await ref.read(databaseHelperProvider).database;
    await db.insert('container_objects', _toRow(obj),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> togglePacked(String id) async {
    final current = state.value ?? [];
    final obj = current.firstWhere((o) => o.id == id);
    final updated = obj.copyWith(isPacked: !obj.isPacked, updatedAt: DateTime.now());
    state = AsyncData(current.map((o) => o.id == id ? updated : o).toList());
    final db = await ref.read(databaseHelperProvider).database;
    await db.update('container_objects', _toRow(updated),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteObject(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((o) => o.id != id).toList());
    final db = await ref.read(databaseHelperProvider).database;
    await db.delete('container_objects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateObject(ContainerObject obj) async {
    final current = state.value ?? [];
    state = AsyncData(current.map((o) => o.id == obj.id ? obj : o).toList());
    final db = await ref.read(databaseHelperProvider).database;
    await db.update('container_objects', _toRow(obj),
        where: 'id = ?', whereArgs: [obj.id]);
  }

  Map<String, dynamic> _toRow(ContainerObject o) => {
        'id': o.id,
        'bag_id': o.bagId,
        'name': o.name,
        'description': o.description,
        'category': o.category,
        'quantity': o.quantity,
        'weight_kg': o.weightKg,
        'is_packed': o.isPacked ? 1 : 0,
        'notes': o.notes,
        'updated_at': o.updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> _mapRow(Map<String, dynamic> r) => {
        'id': r['id'],
        'bagId': r['bag_id'],
        'name': r['name'],
        'description': r['description'],
        'category': r['category'],
        'quantity': r['quantity'],
        'weightKg': r['weight_kg'],
        'isPacked': r['is_packed'],
        'notes': r['notes'],
        'updatedAt': r['updated_at'],
      };
}
