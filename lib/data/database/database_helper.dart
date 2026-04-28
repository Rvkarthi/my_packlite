import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'packlite.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS container_objects (
          id TEXT PRIMARY KEY,
          bag_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT DEFAULT 'General',
          quantity INTEGER DEFAULT 1,
          weight_kg REAL,
          is_packed INTEGER DEFAULT 0,
          notes TEXT,
          updated_at TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        locations TEXT DEFAULT '[]',
        start_date TEXT,
        end_date TEXT,
        type TEXT DEFAULT 'individual',
        template_id TEXT,
        group_id TEXT,
        cover_image_url TEXT,
        is_deleted INTEGER DEFAULT 0,
        updated_at TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE packing_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_selected INTEGER DEFAULT 0,
        is_packed INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        bag_id TEXT,
        needs_to_buy INTEGER DEFAULT 0,
        trip_id TEXT,
        assigned_to TEXT,
        share_status TEXT DEFAULT 'personal',
        shared_by TEXT,
        needed_by TEXT,
        claimed_at TEXT,
        provider_name TEXT DEFAULT '',
        is_deleted INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT DEFAULT '#4CAF50',
        icon TEXT DEFAULT 'luggage',
        sort_order INTEGER DEFAULT 0,
        trip_id TEXT,
        is_deleted INTEGER DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER DEFAULT 0,
        is_group INTEGER DEFAULT 0,
        assigned_to TEXT,
        due_date TEXT,
        is_deleted INTEGER DEFAULT 0,
        updated_at TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        item_names TEXT DEFAULT '[]',
        categories TEXT DEFAULT '[]',
        created_at TEXT,
        is_built_in INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        avatar_color TEXT DEFAULT '#4CAF50',
        device_id TEXT,
        firebase_uid TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE container_objects (
        id TEXT PRIMARY KEY,
        bag_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT DEFAULT 'General',
        quantity INTEGER DEFAULT 1,
        weight_kg REAL,
        is_packed INTEGER DEFAULT 0,
        notes TEXT,
        updated_at TEXT
      )
    ''');
  }
}
