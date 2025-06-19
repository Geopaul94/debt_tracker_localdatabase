import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';


abstract class TransactionSQLiteDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<TransactionModel?> getTransactionById(String id);
  Future<void> saveTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Stream<List<TransactionModel>> watchTransactions();

  // Advanced queries for production features
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type);
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<List<TransactionModel>> searchTransactions(String query);
  Future<Map<String, double>> getTransactionSummary();
}

class TransactionSQLiteDataSourceImpl implements TransactionSQLiteDataSource {
  final DatabaseHelper _databaseHelper;
  StreamController<List<TransactionModel>> _transactionController =
      StreamController<List<TransactionModel>>.broadcast();
  bool _isInitialized = false;

  TransactionSQLiteDataSourceImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  static const String _tableName = 'transactions';

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      // Initialize database schema only, don't add sample data yet
      await _databaseHelper.database;
      _isInitialized = true;

      // Now safely initialize sample data
      await _initializeSampleDataSafely();
    } catch (e) {
      print('Database initialization error: $e');
      // Continue without sample data
      _isInitialized = true;
    }
  }

  Future<void> _initializeSampleDataSafely() async {
    try {
      // Check if we already have data without going through getAllTransactions
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final count = result.first['count'] as int? ?? 0;

      if (count == 0) {
        // Add sample data on first run
        final sampleTransactions = [
          TransactionModel(
            id: 't1',
            name: "John Doe",
            description: 'Lunch with Sarah',
            amount: 15.50,
            type: TransactionType.iOwe,
            date: DateTime.now().subtract(Duration(days: 2)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TransactionModel(
            id: 't2',
            name: "Alice Smith",
            description: 'Project payment from Client X',
            amount: 250.00,
            type: TransactionType.owesMe,
            date: DateTime.now().subtract(Duration(days: 1)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TransactionModel(
            id: 't3',
            name: "Bob Wilson",
            description: 'Movie tickets',
            amount: 22.00,
            type: TransactionType.iOwe,
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Insert directly without using saveTransaction to avoid _ensureInitialized loop
        for (final transaction in sampleTransactions) {
          await db.insert(
            _tableName,
            transaction.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      print('Error initializing sample data: $e');
      // Don't throw - let the app continue without sample data
    }
  }

  Future<void> _initializeSampleData() async {
    // This method is now deprecated, keeping for backward compatibility
    // The actual initialization is done in _initializeSampleDataSafely
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        _tableName,
        orderBy: 'date DESC', // Most recent first
      );

      return maps.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TransactionModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by id: $e');
      return null;
    }
  }

  @override
  Future<void> saveTransaction(TransactionModel transaction) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      await db.insert(
        _tableName,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _notifyListeners();
    } catch (e) {
      print('Error saving transaction: $e');
      throw e;
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        _tableName,
        updatedTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      _notifyListeners();
    } catch (e) {
      print('Error updating transaction: $e');
      throw e;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);

      _notifyListeners();
    } catch (e) {
      print('Error deleting transaction: $e');
      throw e;
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    if (_transactionController.isClosed) {
      _transactionController =
          StreamController<List<TransactionModel>>.broadcast();
    }

    // Initialize with current data immediately
    _loadInitialData();

    return _transactionController.stream;
  }

  Future<void> _loadInitialData() async {
    try {
      final transactions = await getAllTransactions();
      if (!_transactionController.isClosed) {
        _transactionController.add(transactions);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (!_transactionController.isClosed) {
        _transactionController.add([]);
      }
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(
    TransactionType type,
  ) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        _tableName,
        where: 'type = ?',
        whereArgs: [type.toString().split('.').last],
        orderBy: 'date DESC',
      );

      return maps.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting transactions by type: $e');
      return [];
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        _tableName,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );

      return maps.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  @override
  Future<List<TransactionModel>> searchTransactions(String query) async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        _tableName,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      print('Error searching transactions: $e');
      return [];
    }
  }

  @override
  Future<Map<String, double>> getTransactionSummary() async {
    await _ensureInitialized();

    try {
      final db = await _databaseHelper.database;

      final iOweResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_tableName WHERE type = ?',
        ['iOwe'],
      );

      final owesMeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_tableName WHERE type = ?',
        ['owesMe'],
      );

      final totalIOwe = (iOweResult.first['total'] as double?) ?? 0.0;
      final totalOwesMe = (owesMeResult.first['total'] as double?) ?? 0.0;

      return {
        'iOwe': totalIOwe,
        'owesMe': totalOwesMe,
        'net': totalOwesMe - totalIOwe,
      };
    } catch (e) {
      print('Error getting transaction summary: $e');
      return {'iOwe': 0.0, 'owesMe': 0.0, 'net': 0.0};
    }
  }

  Future<void> _notifyListeners() async {
    try {
      final transactions = await getAllTransactions();
      if (!_transactionController.isClosed) {
        _transactionController.add(transactions);
      }
    } catch (e) {
      print('Error notifying listeners: $e');
    }
  }

  void dispose() {
    _transactionController.close();
  }
}
