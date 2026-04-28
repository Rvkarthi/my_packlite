import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/trip.dart';
import '../providers/group_provider.dart';

final tripsProvider =
    AsyncNotifierProvider<TripsNotifier, List<Trip>>(TripsNotifier.new);

class TripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    return ref.read(tripRepositoryProvider).getAllTrips();
  }

  Future<Trip> createTrip({
    required String title,
    required List<TripLocation> locations,
    DateTime? startDate,
    DateTime? endDate,
    TripType type = TripType.individual,
    String? templateId,
  }) async {
    final trip = Trip(
      id: const Uuid().v4(),
      title: title,
      locations: locations,
      startDate: startDate,
      endDate: endDate,
      type: type,
      templateId: templateId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // Optimistic update
    state = AsyncData([trip, ...state.value ?? []]);
    try {
      final saved = await ref.read(tripRepositoryProvider).createTrip(trip);

      // Auto-create Firebase group for group trips
      if (type == TripType.group) {
        try {
          final group = await ref
              .read(groupActionProvider.notifier)
              .createGroup(tripId: saved.id, tripTitle: title);
          // Store groupId back on the trip
          final tripWithGroup = saved.copyWith(groupId: group.id);
          await ref.read(tripRepositoryProvider).updateTrip(tripWithGroup);
        } catch (_) {
          // Group creation failure is non-fatal — trip is still saved locally
        }
      }

      await _reload();
      return saved;
    } catch (e) {
      await _reload();
      rethrow;
    }
  }

  Future<void> updateTrip(Trip trip) async {
    final current = state.value ?? [];
    // Optimistic update
    state = AsyncData(current.map((t) => t.id == trip.id ? trip : t).toList());
    try {
      await ref.read(tripRepositoryProvider).updateTrip(trip);
    } catch (_) {
      await _reload();
    }
  }

  Future<void> deleteTrip(String id) async {
    final current = state.value ?? [];
    // Optimistic remove
    state = AsyncData(current.where((t) => t.id != id).toList());
    try {
      await ref.read(tripRepositoryProvider).deleteTrip(id);
    } catch (_) {
      await _reload();
    }
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(tripRepositoryProvider).getAllTrips());
  }

  Future<void> refresh() => _reload();
}

final selectedTripProvider =
    NotifierProvider<_SelectedTripNotifier, Trip?>(_SelectedTripNotifier.new);

class _SelectedTripNotifier extends Notifier<Trip?> {
  @override
  Trip? build() => null;
  void select(Trip? trip) => state = trip;
}

