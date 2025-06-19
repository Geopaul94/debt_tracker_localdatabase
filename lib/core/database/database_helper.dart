import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'debt_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_transactions_type ON transactions(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_name ON transactions(name)
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Example: Add new columns in future versions
      // await db.execute('ALTER TABLE transactions ADD COLUMN category TEXT');
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Helper method to delete database (for testing/debugging)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'debt_tracker.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
