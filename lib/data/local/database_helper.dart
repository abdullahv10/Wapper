import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wapper.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    debugPrint('🚀 [DatabaseHelper] Initializing database at $path');
    
    // ⬆️ BUMPED VERSION TO 2
    return await openDatabase(
      path, 
      version: 2, 
      onConfigure: _onConfigure, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Added migration handler
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    debugPrint('✅ [DatabaseHelper] Foreign keys enabled.');
  }

  Future _createDB(Database db, int version) async {
    debugPrint('🚀 [DatabaseHelper] Creating new database schema (v$version)...');
    
    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        image TEXT,
        active INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE wallpapers (
        id TEXT PRIMARY KEY,
        collectionId TEXT NOT NULL,
        filePath TEXT NOT NULL,
        FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        collectionId TEXT NOT NULL,
        timeRange TEXT NOT NULL,
        FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE
      )
    ''');

    // 🏗️ MOVED: Creating the settings table here for new installs
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY, 
        value TEXT
      )
    ''');
    
    debugPrint('✅ [DatabaseHelper] Database schema created successfully.');
  }

  // 🏗️ NEW: Handles upgrading existing users from v1 to v2 without losing data
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🚀 [DatabaseHelper] Upgrading database from v$oldVersion to v$newVersion...');
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT)');
      debugPrint('✅ [DatabaseHelper] Migrated to v2: app_settings table added.');
    }
  }

  // ==========================================
  // --- COLLECTIONS CRUD ---
  // ==========================================
  
  Future<void> insertCollection(Map<String, dynamic> collection) async {
    final db = await instance.database;
    final data = Map<String, dynamic>.from(collection);
    data['active'] = data['active'] == true ? 1 : 0; 
    
    await db.insert('collections', data, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ [DatabaseHelper] Inserted collection: ${data['id']}');
  }

  Future<List<Map<String, dynamic>>> fetchCollections() async {
    final db = await instance.database;
    final result = await db.query('collections');
    
    return result.map((map) {
      final m = Map<String, dynamic>.from(map);
      m['active'] = m['active'] == 1; 
      return m;
    }).toList();
  }

  Future<void> deleteCollection(String id) async {
    final db = await instance.database;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
    debugPrint('✅ [DatabaseHelper] Deleted collection: $id');
  }

  // ==========================================
  // --- WALLPAPERS CRUD ---
  // ==========================================
  
  Future<void> insertWallpaper(Map<String, dynamic> wallpaper) async {
    final db = await instance.database;
    await db.insert('wallpapers', wallpaper, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ [DatabaseHelper] Inserted wallpaper: ${wallpaper['id']}');
  }

  Future<List<Map<String, dynamic>>> fetchWallpapers(String collectionId) async {
    final db = await instance.database;
    return await db.query('wallpapers', where: 'collectionId = ?', whereArgs: [collectionId]);
  }

  Future<void> deleteWallpaper(String id) async {
    final db = await instance.database;
    await db.delete('wallpapers', where: 'id = ?', whereArgs: [id]);
    debugPrint('✅ [DatabaseHelper] Deleted wallpaper: $id');
  }

  // ==========================================
  // --- SCHEDULES CRUD ---
  // ==========================================
  
  Future<void> insertSchedule(Map<String, dynamic> schedule) async {
    final db = await instance.database;
    await db.insert('schedules', schedule, conflictAlgorithm: ConflictAlgorithm.replace);
    debugPrint('✅ [DatabaseHelper] Inserted schedule rule: ${schedule['id']}');
  }

  Future<List<Map<String, dynamic>>> fetchSchedules() async {
    final db = await instance.database;
    return await db.query('schedules');
  }

  Future<void> deleteSchedule(String id) async {
    final db = await instance.database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
    debugPrint('✅ [DatabaseHelper] Deleted schedule rule: $id');
  }

  // ==========================================
  // --- SINGLE SOURCE OF TRUTH: LAST WALLPAPER ---
  // ==========================================
  
  Future<void> saveLastAppliedWallpaper(String filePath) async {
    final db = await instance.database; // Fixed: Use instance.database consistently
    
    await db.insert(
      'app_settings', 
      {'key': 'last_wallpaper', 'value': filePath}, 
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('✅ [DatabaseHelper] Saved last applied wallpaper to DB.');
  }

  Future<String?> getLastAppliedWallpaper() async {
    final db = await instance.database; // Fixed: Use instance.database consistently
    
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['last_wallpaper']);
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }
}