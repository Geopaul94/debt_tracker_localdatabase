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
      version: 4,
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
        updated_at TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'USD',
        currency_symbol TEXT NOT NULL DEFAULT '\$',
        currency_name TEXT NOT NULL DEFAULT 'US Dollar',
        currency_flag TEXT NOT NULL DEFAULT '🇺🇸',
        attachments TEXT DEFAULT '[]'
      )
    ''');

    // Create trash table for soft deletes
    await db.execute('''
      CREATE TABLE trash (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'USD',
        currency_symbol TEXT NOT NULL DEFAULT '\$',
        currency_name TEXT NOT NULL DEFAULT 'US Dollar',
        currency_flag TEXT NOT NULL DEFAULT '🇺🇸',
        attachments TEXT DEFAULT '[]'
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

    await db.execute('''
      CREATE INDEX idx_trash_deleted_at ON trash(deleted_at)
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add trash table for soft deletes
      await db.execute('''
        CREATE TABLE trash (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_trash_deleted_at ON trash(deleted_at)
      ''');
    }

    if (oldVersion < 3) {
      // Add currency fields to existing tables
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'USD'
      ''');
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN currency_symbol TEXT NOT NULL DEFAULT '\$'
      ''');
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN currency_name TEXT NOT NULL DEFAULT 'US Dollar'
      ''');
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN currency_flag TEXT NOT NULL DEFAULT '🇺🇸'
      ''');

      await db.execute('''
        ALTER TABLE trash ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'USD'
      ''');
      await db.execute('''
        ALTER TABLE trash ADD COLUMN currency_symbol TEXT NOT NULL DEFAULT '\$'
      ''');
      await db.execute('''
        ALTER TABLE trash ADD COLUMN currency_name TEXT NOT NULL DEFAULT 'US Dollar'
      ''');
      await db.execute('''
        ALTER TABLE trash ADD COLUMN currency_flag TEXT NOT NULL DEFAULT '🇺🇸'
      ''');
    }

    if (oldVersion < 4) {
      // Add attachments support
      await db.execute('''
        ALTER TABLE transactions ADD COLUMN attachments TEXT DEFAULT '[]'
      ''');
      await db.execute('''
        ALTER TABLE trash ADD COLUMN attachments TEXT DEFAULT '[]'
      ''');
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
