import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/preference_service.dart';
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

  // Dummy data management
  Future<void> cleanupDummyDataIfNeeded();
  Future<void> addDummyDataIfNeeded();
}

class TransactionSQLiteDataSourceImpl implements TransactionSQLiteDataSource {
  final DatabaseHelper _databaseHelper;
  StreamController<List<TransactionModel>> _transactionController =
      StreamController<List<TransactionModel>>.broadcast();
  bool _isInitialized = false;

  // Dummy transaction IDs for identification
  static const List<String> _dummyTransactionIds = [
    'dummy_1',
    'dummy_2',
    'dummy_3',
  ];

  TransactionSQLiteDataSourceImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  static const String _tableName = 'transactions';

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      // Initialize database schema only
      await _databaseHelper.database;
      _isInitialized = true;

      // Add dummy data if needed and clean up if necessary
      await addDummyDataIfNeeded();
      await cleanupDummyDataIfNeeded();
    } catch (e) {
      print('Database initialization error: $e');
      _isInitialized = true;
    }
  }

  @override
  Future<void> addDummyDataIfNeeded() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final count = result.first['count'] as int? ?? 0;
      final hasDummyData = await PreferenceService.instance.hasDummyData();

      // Add dummy data only if no transactions exist and no dummy data flag is set
      if (count == 0 && !hasDummyData) {
        final dummyTransactions = _createDummyTransactions();

        for (final transaction in dummyTransactions) {
          await db.insert(
            _tableName,
            transaction.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Mark that we have dummy data
        await PreferenceService.instance.setHasDummyData(true);
        print('Dummy data added for new user experience');
      }
    } catch (e) {
      print('Error adding dummy data: $e');
    }
  }

  @override
  Future<void> cleanupDummyDataIfNeeded() async {
    try {
      final shouldCleanup =
          await PreferenceService.instance.shouldCleanupDummyData();

      if (shouldCleanup) {
        await _removeDummyTransactions();
        await PreferenceService.instance.resetDummyDataFlags();
        print('Dummy data cleaned up');
      }
    } catch (e) {
      print('Error cleaning up dummy data: $e');
    }
  }

  List<TransactionModel> _createDummyTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'dummy_1',
        name: "Sample Transaction 1",
        description: 'Lunch at cafe (Sample)',
        amount: 25.50,
        type: TransactionType.iOwe,
        date: now.subtract(Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
      ),
      TransactionModel(
        id: 'dummy_2',
        name: "Sample Transaction 2",
        description: 'Freelance project payment (Sample)',
        amount: 150.00,
        type: TransactionType.owesMe,
        date: now.subtract(Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
      TransactionModel(
        id: 'dummy_3',
        name: "Sample Transaction 3",
        description: 'Movie tickets (Sample)',
        amount: 18.00,
        type: TransactionType.iOwe,
        date: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> _removeDummyTransactions() async {
    try {
      final db = await _databaseHelper.database;

      for (final dummyId in _dummyTransactionIds) {
        await db.delete(_tableName, where: 'id = ?', whereArgs: [dummyId]);
      }

      _notifyListeners();
    } catch (e) {
      print('Error removing dummy transactions: $e');
    }
  }

  Future<void> _initializeSampleDataSafely() async {
    // This method is now replaced by addDummyDataIfNeeded
    // Keeping for backward compatibility
  }

  Future<void> _initializeSampleData() async {
    // This method is now deprecated, keeping for backward compatibility
    // The actual initialization is done in addDummyDataIfNeeded
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
      rethrow;
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

      // Check if this is the user's first real transaction
      final hasRealTransaction =
          await PreferenceService.instance.hasRealTransaction();
      if (!hasRealTransaction &&
          !_dummyTransactionIds.contains(transaction.id)) {
        await PreferenceService.instance.setHasRealTransaction(true);
        // Clean up dummy data when user adds first real transaction
        await cleanupDummyDataIfNeeded();
      }

      await db.insert(
        _tableName,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _notifyListeners();
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
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
      rethrow;
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
      rethrow;
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
