import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/packing_item.dart';

enum PackingMode { catalog, suitcase }

final packingModeProvider =
    NotifierProvider<_PackingModeNotifier, PackingMode>(_PackingModeNotifier.new);

class _PackingModeNotifier extends Notifier<PackingMode> {
  @override
  PackingMode build() => PackingMode.catalog;
  void set(PackingMode mode) => state = mode;
}

final hidePackedProvider =
    NotifierProvider<_BoolNotifier, bool>(_BoolNotifier.new);

class _BoolNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void setValue(bool v) => state = v;
}

final selectedItemIdsProvider =
    NotifierProvider<_SetNotifier, Set<String>>(_SetNotifier.new);

class _SetNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void toggle(String id) {
    final s = Set<String>.from(state);
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    state = s;
  }
  void clear() => state = {};
}

// Riverpod 3.x family: factory receives arg, notifier stores it
final tripItemsProvider = AsyncNotifierProvider.family<TripItemsNotifier,
    List<PackingItem>, String>((arg) => TripItemsNotifier(arg));

class TripItemsNotifier extends AsyncNotifier<List<PackingItem>> {
  final String _tripId;
  TripItemsNotifier(this._tripId);

  String get tripId => _tripId;

  @override
  Future<List<PackingItem>> build() async {
    return ref.read(itemRepositoryProvider).getItemsByTrip(_tripId);
  }

  Future<void> addItem({
    required String name,
    required String category,
    String? bagId,
  }) async {
    final current = state.value ?? [];
    final item = PackingItem(
      id: const Uuid().v4(),
      name: name,
      category: category,
      tripId: _tripId,
      bagId: bagId,
      sortOrder: current.length,
      isSelected: true,
      updatedAt: DateTime.now(),
    );
    state = AsyncData([...current, item]);
    try {
      await ref.read(itemRepositoryProvider).createItem(item);
    } catch (_) {
      await _reload();
    }
  }

  Future<void> toggleSelected(String itemId) async {
    final current = state.value ?? [];
    final item = current.firstWhere((i) => i.id == itemId);
    final updated =
        item.copyWith(isSelected: !item.isSelected, updatedAt: DateTime.now());
    _applyOptimistic(updated);
    await ref.read(itemRepositoryProvider).updateItem(updated);
  }

  Future<void> togglePacked(String itemId) async {
    final current = state.value ?? [];
    final item = current.firstWhere((i) => i.id == itemId);
    final updated =
        item.copyWith(isPacked: !item.isPacked, updatedAt: DateTime.now());
    _applyOptimistic(updated);
    await ref.read(itemRepositoryProvider).updateItem(updated);
  }

  Future<void> updateItem(PackingItem item) async {
    _applyOptimistic(item);
    await ref.read(itemRepositoryProvider).updateItem(item);
  }

  Future<void> deleteItem(String itemId) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((i) => i.id != itemId).toList());
    await ref.read(itemRepositoryProvider).deleteItem(itemId);
  }

  Future<void> resetPacked() async {
    final current = state.value ?? [];
    state = AsyncData(current.map((i) => i.copyWith(isPacked: false)).toList());
    await ref.read(itemRepositoryProvider).resetPackedStatus(_tripId);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = List<PackingItem>.from(state.value ?? []);
    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);
    final reordered = current
        .asMap()
        .entries
        .map((e) => e.value.copyWith(sortOrder: e.key))
        .toList();
    state = AsyncData(reordered);
    await ref.read(itemRepositoryProvider).updateSortOrders(reordered);
  }

  Future<void> addItemsFromSuggestions(
      List<String> names, String category) async {
    final current = state.value ?? [];
    final newItems = names
        .map((name) => PackingItem(
              id: const Uuid().v4(),
              name: name,
              category: category,
              tripId: _tripId,
              sortOrder: current.length,
              isSelected: true,
              updatedAt: DateTime.now(),
            ))
        .toList();
    state = AsyncData([...current, ...newItems]);
    for (final item in newItems) {
      await ref.read(itemRepositoryProvider).createItem(item);
    }
  }

  void _applyOptimistic(PackingItem updated) {
    final current = state.value ?? [];
    state = AsyncData(
        current.map((i) => i.id == updated.id ? updated : i).toList());
  }

  Future<void> _reload() async {
    state = AsyncData(
        await ref.read(itemRepositoryProvider).getItemsByTrip(_tripId));
  }

  double get progress {
    final items = state.value ?? [];
    final selected = items.where((i) => i.isSelected).length;
    if (selected == 0) return 0.0;
    final packed = items.where((i) => i.isSelected && i.isPacked).length;
    return packed / selected;
  }
}
