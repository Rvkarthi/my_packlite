import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/local/trip_local_datasource.dart';
import '../models/trip_model.dart';
import '../../services/sync/sync_service.dart';

class TripRepositoryImpl implements TripRepository {
  final TripLocalDatasource _local;
  final SyncService _sync;

  TripRepositoryImpl(this._local, this._sync);

  @override
  Future<List<Trip>> getAllTrips() async {
    final models = await _local.getAllTrips();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final model = await _local.getTripById(id);
    return model?.toEntity();
  }

  @override
  Future<Trip> createTrip(Trip trip) async {
    final model = TripModel.fromEntity(trip);
    await _local.upsertTrip(model);
    _sync.queueWrite('trips', trip.id, 'upsert', model.toFirestore());
    return trip;
  }

  @override
  Future<Trip> updateTrip(Trip trip) async {
    final updated = trip.copyWith(updatedAt: DateTime.now());
    final model = TripModel.fromEntity(updated);
    await _local.upsertTrip(model);
    _sync.queueWrite('trips', trip.id, 'upsert', model.toFirestore());
    return updated;
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _local.deleteTrip(id);
    _sync.queueWrite('trips', id, 'delete', {'isDeleted': true});
  }

  @override
  Future<void> syncTrips() async {
    await _sync.syncCollection('trips');
  }
}
