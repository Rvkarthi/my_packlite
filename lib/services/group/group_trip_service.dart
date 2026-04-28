import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/group_trip.dart';

/// All Firestore operations for group trips.
/// Collection: group_trips/{groupId}
///   Sub-collections: todos, containers (bags), containers/{bagId}/objects
class GroupTripService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _groups => _db.collection('group_trips');

  String? get _uid => _auth.currentUser?.uid;
  String? get _displayName => _auth.currentUser?.displayName;

  // ── Create ────────────────────────────────────────────────────────────────

  Future<GroupTrip> createGroup({
    required String tripId,
    required String tripTitle,
    required String inviteCode,
  }) async {
    final uid = _uid!;
    final now = DateTime.now();
    final docRef = _groups.doc();
    final member = GroupMember(
      id: uid,
      name: _displayName ?? 'Organizer',
      avatarColor: '#4CAF50',
    );
    final group = GroupTrip(
      id: docRef.id,
      inviteCode: inviteCode,
      organizerId: uid,
      tripId: tripId,
      members: [member],
      createdAt: now,
    );
    await docRef.set({
      ...group.toJson(),
      'tripTitle': tripTitle,
      'createdAt': now.toIso8601String(),
    });
    return group;
  }

  // ── Join ──────────────────────────────────────────────────────────────────

  /// Returns the GroupTrip if found, throws if not found.
  Future<GroupTrip> joinByCode(String inviteCode) async {
    final uid = _uid!;
    final snap = await _groups
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) throw Exception('Group not found');
    final doc = snap.docs.first;
    final data = doc.data() as Map<String, dynamic>;

    // Add member if not already in
    final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
    final alreadyIn = members.any((m) => m['id'] == uid);
    if (!alreadyIn) {
      members.add(GroupMember(
        id: uid,
        name: _displayName ?? 'Member',
        avatarColor: '#2196F3',
      ).toJson());
      await doc.reference.update({'members': members});
    }
    return GroupTrip.fromJson({...data, 'id': doc.id, 'members': members});
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Stream of groups the current user belongs to.
  Stream<List<GroupTrip>> myGroupsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _groups.snapshots().map((snap) {
      return snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return GroupTrip.fromJson({...data, 'id': d.id});
          })
          .where((g) => g.members.any((m) => m.id == uid))
          .toList();
    });
  }

  /// Stream of a single group by id.
  Stream<GroupTrip?> groupStream(String groupId) {
    return _groups.doc(groupId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      return GroupTrip.fromJson({...data, 'id': snap.id});
    });
  }

  // ── Group Todos ───────────────────────────────────────────────────────────

  CollectionReference _todosRef(String groupId) =>
      _groups.doc(groupId).collection('todos');

  Stream<List<Map<String, dynamic>>> groupTodosStream(String groupId) {
    return _todosRef(groupId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
            .toList());
  }

  Future<void> addGroupTodo(String groupId, Map<String, dynamic> todo) async {
    await _todosRef(groupId).doc(todo['id']).set(todo);
  }

  Future<void> updateGroupTodo(
      String groupId, String todoId, Map<String, dynamic> data) async {
    await _todosRef(groupId).doc(todoId).update(data);
  }

  Future<void> deleteGroupTodo(String groupId, String todoId) async {
    await _todosRef(groupId).doc(todoId).delete();
  }

  // ── Group Containers (Bags) ───────────────────────────────────────────────

  CollectionReference _containersRef(String groupId) =>
      _groups.doc(groupId).collection('containers');

  Stream<List<Map<String, dynamic>>> groupContainersStream(String groupId) {
    return _containersRef(groupId).snapshots().map((snap) => snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .toList());
  }

  Future<void> addGroupContainer(
      String groupId, Map<String, dynamic> bag) async {
    await _containersRef(groupId).doc(bag['id']).set(bag);
  }

  Future<void> deleteGroupContainer(String groupId, String bagId) async {
    await _containersRef(groupId).doc(bagId).delete();
    // Also delete all objects in this container
    final objs = await _objectsRef(groupId, bagId).get();
    for (final d in objs.docs) {
      await d.reference.delete();
    }
  }

  // ── Group Container Objects ───────────────────────────────────────────────

  CollectionReference _objectsRef(String groupId, String bagId) =>
      _containersRef(groupId).doc(bagId).collection('objects');

  Stream<List<Map<String, dynamic>>> groupObjectsStream(
      String groupId, String bagId) {
    return _objectsRef(groupId, bagId).snapshots().map((snap) => snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'id': d.id})
        .toList());
  }

  Future<void> addGroupObject(
      String groupId, String bagId, Map<String, dynamic> obj) async {
    await _objectsRef(groupId, bagId).doc(obj['id']).set(obj);
  }

  Future<void> updateGroupObject(String groupId, String bagId, String objId,
      Map<String, dynamic> data) async {
    await _objectsRef(groupId, bagId).doc(objId).update(data);
  }

  Future<void> deleteGroupObject(
      String groupId, String bagId, String objId) async {
    await _objectsRef(groupId, bagId).doc(objId).delete();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the groupId for a given tripId (if any).
  Future<String?> groupIdForTrip(String tripId) async {
    final snap = await _groups
        .where('tripId', isEqualTo: tripId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// Returns groups the current user has been invited to but hasn't joined yet.
  /// (For home screen banner — groups where user is NOT organizer but IS a member)
  Stream<List<GroupTrip>> pendingInvitesStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _groups.snapshots().map((snap) {
      return snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return GroupTrip.fromJson({...data, 'id': d.id});
          })
          .where((g) =>
              g.organizerId != uid && g.members.any((m) => m.id == uid))
          .toList();
    });
  }
}
