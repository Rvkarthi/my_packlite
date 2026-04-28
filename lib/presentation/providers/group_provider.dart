import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/group_trip.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/bag.dart';
import '../../domain/entities/container_object.dart';
import '../../services/group/group_trip_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final groupTripServiceProvider = Provider<GroupTripService>((_) => GroupTripService());

// ── My groups stream ──────────────────────────────────────────────────────────

final myGroupsProvider = StreamProvider<List<GroupTrip>>((ref) {
  return ref.watch(groupTripServiceProvider).myGroupsStream();
});

// ── Single group stream ───────────────────────────────────────────────────────

final groupStreamProvider =
    StreamProvider.family<GroupTrip?, String>((ref, groupId) {
  return ref.watch(groupTripServiceProvider).groupStream(groupId);
});

// ── Group id for a trip ───────────────────────────────────────────────────────

final groupIdForTripProvider =
    FutureProvider.family<String?, String>((ref, tripId) async {
  return ref.read(groupTripServiceProvider).groupIdForTrip(tripId);
});

// ── Create / Join notifier ────────────────────────────────────────────────────

final groupActionProvider =
    AsyncNotifierProvider<GroupActionNotifier, void>(GroupActionNotifier.new);

class GroupActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<GroupTrip> createGroup({
    required String tripId,
    required String tripTitle,
  }) async {
    state = const AsyncLoading();
    try {
      final code = _generateCode();
      final group = await ref
          .read(groupTripServiceProvider)
          .createGroup(tripId: tripId, tripTitle: tripTitle, inviteCode: code);
      state = const AsyncData(null);
      ref.invalidate(myGroupsProvider);
      return group;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<GroupTrip> joinGroup(String inviteCode) async {
    state = const AsyncLoading();
    try {
      final group =
          await ref.read(groupTripServiceProvider).joinByCode(inviteCode);
      state = const AsyncData(null);
      ref.invalidate(myGroupsProvider);
      return group;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  String _generateCode() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = ts.substring(ts.length - 6);
    return '${suffix.substring(0, 3)}-${suffix.substring(3)}';
  }
}

// ── Group Todos ───────────────────────────────────────────────────────────────

final groupTodosProvider =
    StreamProvider.family<List<Todo>, String>((ref, groupId) {
  return ref
      .watch(groupTripServiceProvider)
      .groupTodosStream(groupId)
      .map((list) => list.map((m) {
            return Todo(
              id: m['id'] as String,
              tripId: m['tripId'] as String? ?? '',
              title: m['title'] as String,
              isDone: m['isDone'] == true || m['isDone'] == 1,
              isGroup: true,
              assignedTo: m['assignedTo'] as String?,
              createdAt: m['createdAt'] != null
                  ? DateTime.tryParse(m['createdAt'] as String)
                  : null,
              updatedAt: m['updatedAt'] != null
                  ? DateTime.tryParse(m['updatedAt'] as String)
                  : null,
            );
          }).toList());
});

final groupTodoActionsProvider =
    AsyncNotifierProvider.family<GroupTodoActions, void, String>(
        (arg) => GroupTodoActions(arg));

class GroupTodoActions extends AsyncNotifier<void> {
  final String _groupId;
  GroupTodoActions(this._groupId);

  @override
  Future<void> build() async {}

  Future<void> addTodo(String title) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'Member';
    final todo = {
      'id': const Uuid().v4(),
      'tripId': '',
      'title': title,
      'isDone': false,
      'isGroup': true,
      'assignedTo': name,
      'createdBy': uid,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await ref.read(groupTripServiceProvider).addGroupTodo(_groupId, todo);
  }

  Future<void> toggleTodo(String todoId, bool current) async {
    await ref.read(groupTripServiceProvider).updateGroupTodo(
        _groupId, todoId, {'isDone': !current, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<void> deleteTodo(String todoId) async {
    await ref.read(groupTripServiceProvider).deleteGroupTodo(_groupId, todoId);
  }
}

// ── Group Containers ──────────────────────────────────────────────────────────

final groupContainersProvider =
    StreamProvider.family<List<Bag>, String>((ref, groupId) {
  return ref
      .watch(groupTripServiceProvider)
      .groupContainersStream(groupId)
      .map((list) => list
          .map((m) => Bag(
                id: m['id'] as String,
                name: m['name'] as String,
                color: (m['color'] as String?) ?? '#4CAF50',
                icon: (m['icon'] as String?) ?? 'luggage',
                tripId: m['tripId'] as String?,
              ))
          .toList());
});

final groupContainerActionsProvider =
    AsyncNotifierProvider.family<GroupContainerActions, void, String>(
        (arg) => GroupContainerActions(arg));

class GroupContainerActions extends AsyncNotifier<void> {
  final String _groupId;
  GroupContainerActions(this._groupId);

  @override
  Future<void> build() async {}

  Future<void> addContainer(String name, String color) async {
    final bag = {
      'id': const Uuid().v4(),
      'name': name,
      'color': color,
      'icon': 'luggage',
      'tripId': '',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await ref
        .read(groupTripServiceProvider)
        .addGroupContainer(_groupId, bag);
  }

  Future<void> deleteContainer(String bagId) async {
    await ref
        .read(groupTripServiceProvider)
        .deleteGroupContainer(_groupId, bagId);
  }
}

// ── Group Container Objects ───────────────────────────────────────────────────

final groupObjectsProvider =
    StreamProvider.family<List<ContainerObject>, GroupBagKey>(
        (ref, key) {
  return ref
      .watch(groupTripServiceProvider)
      .groupObjectsStream(key.groupId, key.bagId)
      .map((list) => list
          .map((m) => ContainerObject(
                id: m['id'] as String,
                bagId: m['bagId'] as String? ?? key.bagId,
                name: m['name'] as String,
                description: m['description'] as String?,
                category: (m['category'] as String?) ?? 'General',
                quantity: (m['quantity'] as int?) ?? 1,
                isPacked: m['isPacked'] == true || m['isPacked'] == 1,
                notes: m['notes'] as String?,
              ))
          .toList());
});

final groupObjectActionsProvider =
    AsyncNotifierProvider.family<GroupObjectActions, void, GroupBagKey>(
        (arg) => GroupObjectActions(arg));

class GroupObjectActions extends AsyncNotifier<void> {
  final GroupBagKey _key;
  GroupObjectActions(this._key);

  @override
  Future<void> build() async {}

  Future<void> addObject({
    required String name,
    String? description,
    String category = 'General',
    int quantity = 1,
    String? notes,
  }) async {
    final obj = {
      'id': const Uuid().v4(),
      'bagId': _key.bagId,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'isPacked': false,
      'notes': notes,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await ref
        .read(groupTripServiceProvider)
        .addGroupObject(_key.groupId, _key.bagId, obj);
  }

  Future<void> togglePacked(String objId, bool current) async {
    await ref.read(groupTripServiceProvider).updateGroupObject(
        _key.groupId, _key.bagId, objId, {'isPacked': !current});
  }

  Future<void> deleteObject(String objId) async {
    await ref
        .read(groupTripServiceProvider)
        .deleteGroupObject(_key.groupId, _key.bagId, objId);
  }
}

// ── Key for family providers ──────────────────────────────────────────────────

class GroupBagKey {
  final String groupId;
  final String bagId;
  const GroupBagKey(this.groupId, this.bagId);

  @override
  bool operator ==(Object other) =>
      other is GroupBagKey &&
      other.groupId == groupId &&
      other.bagId == bagId;

  @override
  int get hashCode => Object.hash(groupId, bagId);
}

// Expose key constructor publicly
GroupBagKey groupBagKey(String groupId, String bagId) =>
    GroupBagKey(groupId, bagId);
