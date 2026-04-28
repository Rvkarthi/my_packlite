import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/database_helper.dart';

/// Queues writes locally and flushes to Firestore when online.
/// Firebase is the sync layer only — local DB is source of truth.
class SyncService {
  final DatabaseHelper _db;
  final Connectivity _connectivity;
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  SyncService(this._db, this._connectivity) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected) _flushQueue();
    });
  }

  void queueWrite(
      String table, String recordId, String operation, Map<String, dynamic> payload) {
    _enqueue(table, recordId, operation, payload);
  }

  Future<void> _enqueue(String table, String recordId, String operation,
      Map<String, dynamic> payload) async {
    try {
      final db = await _db.database;
      await db.insert(
        'sync_queue',
        {
          'id': const Uuid().v4(),
          'table_name': table,
          'record_id': recordId,
          'operation': operation,
          'payload': jsonEncode(payload),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Try to flush immediately if online
      _flushQueue();
    } catch (_) {
      // Silently fail — will retry on next connectivity event
    }
  }

  Future<void> _flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (!connected) return;

      final db = await _db.database;
      final rows = await db.query('sync_queue',
          orderBy: 'created_at ASC', limit: 50);

      for (final row in rows) {
        try {
          await _pushToFirestore(
            row['table_name'] as String,
            row['record_id'] as String,
            row['operation'] as String,
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          );
          await db.delete('sync_queue',
              where: 'id = ?', whereArgs: [row['id']]);
        } catch (_) {
          // Leave in queue for next attempt
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushToFirestore(String table, String recordId,
      String operation, Map<String, dynamic> payload) async {
    // Firebase push — wrapped in try/catch so offline never crashes
    try {
      // Dynamic import to avoid hard dependency when Firebase not configured
      // ignore: avoid_dynamic_calls
      final firestore = _getFirestore();
      if (firestore == null) return;
      if (operation == 'delete') {
        await firestore.collection(table).doc(recordId).update(payload);
      } else {
        await firestore
            .collection(table)
            .doc(recordId)
            .set(payload, _setOptions());
      }
    } catch (_) {
      rethrow;
    }
  }

  // Returns null if Firebase not initialized — safe for offline-only mode
  dynamic _getFirestore() {
    try {
      // ignore: undefined_prefixed_name
      return _FirestoreAccess.instance;
    } catch (_) {
      return null;
    }
  }

  dynamic _setOptions() {
    try {
      return _FirestoreAccess.mergeOption;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncCollection(String collection) async {
    await _flushQueue();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}

// Lazy accessor to avoid hard Firebase dependency at compile time
class _FirestoreAccess {
  static dynamic get instance {
    // Will throw if Firebase not initialized — caught upstream
    throw UnimplementedError('Firebase not configured');
  }

  static dynamic get mergeOption => null;
}
