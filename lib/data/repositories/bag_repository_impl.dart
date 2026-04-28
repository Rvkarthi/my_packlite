import '../../domain/entities/bag.dart';
import '../../domain/repositories/bag_repository.dart';
import '../datasources/local/bag_local_datasource.dart';
import '../models/bag_model.dart';
import '../../services/sync/sync_service.dart';

class BagRepositoryImpl implements BagRepository {
  final BagLocalDatasource _local;
  // ignore: unused_field
  final SyncService _sync;

  BagRepositoryImpl(this._local, this._sync);

  @override
  Future<List<Bag>> getBagsByTrip(String tripId) async {
    final models = await _local.getBagsByTrip(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Bag> createBag(Bag bag) async {
    final model = BagModel.fromEntity(bag);
    await _local.upsertBag(model);
    return bag;
  }

  @override
  Future<Bag> updateBag(Bag bag) async {
    final updated = bag.copyWith(updatedAt: DateTime.now());
    final model = BagModel.fromEntity(updated);
    await _local.upsertBag(model);
    return updated;
  }

  @override
  Future<void> deleteBag(String id) async {
    await _local.deleteBag(id);
  }
}
