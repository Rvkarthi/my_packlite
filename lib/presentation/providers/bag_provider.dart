import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/bag.dart';

// Riverpod 3.x family: factory receives arg, notifier stores it
final tripBagsProvider =
    AsyncNotifierProvider.family<TripBagsNotifier, List<Bag>, String>(
        (arg) => TripBagsNotifier(arg));

class TripBagsNotifier extends AsyncNotifier<List<Bag>> {
  final String _tripId;
  TripBagsNotifier(this._tripId);

  String get tripId => _tripId;

  @override
  Future<List<Bag>> build() async {
    return ref.read(bagRepositoryProvider).getBagsByTrip(_tripId);
  }

  Future<Bag> createBag({
    required String name,
    String color = '#4CAF50',
    String icon = 'luggage',
  }) async {
    final bag = Bag(
      id: const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
      tripId: _tripId,
      sortOrder: (state.value ?? []).length,
      updatedAt: DateTime.now(),
    );
    final current = state.value ?? [];
    state = AsyncData([...current, bag]);
    await ref.read(bagRepositoryProvider).createBag(bag);
    return bag;
  }

  Future<void> updateBag(Bag bag) async {
    final current = state.value ?? [];
    state = AsyncData(current.map((b) => b.id == bag.id ? bag : b).toList());
    await ref.read(bagRepositoryProvider).updateBag(bag);
  }

  Future<void> deleteBag(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((b) => b.id != id).toList());
    await ref.read(bagRepositoryProvider).deleteBag(id);
  }
}
