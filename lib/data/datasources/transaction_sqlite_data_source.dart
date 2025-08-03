import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/logger.dart';
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

  // Add dispose method for cleanup
  void dispose();
}

class TransactionSQLiteDataSourceImpl implements TransactionSQLiteDataSource {
  final DatabaseHelper _databaseHelper;
  StreamController<List<TransactionModel>>? _transactionController;
  bool _isInitialized = false;
  bool _isDisposed = false;

  TransactionSQLiteDataSourceImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  static const String _tableName = 'transactions';

  // Lazy initialization of stream controller
  StreamController<List<TransactionModel>> get _controller {
    if (_isDisposed) {
      throw StateError('DataSource has been disposed');
    }
    return _transactionController ??=
        StreamController<List<TransactionModel>>.broadcast();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized || _isDisposed) return;

    try {
      // Initialize database schema only
      await _databaseHelper.database;
      _isInitialized = true;
    } catch (e) {
      AppLogger.error('Database initialization error', e);
      _isInitialized = true;
    }
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    if (_isDisposed) return [];

    await _ensureInitialized();
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'created_at DESC',
      );

      final transactions =
          maps.map((map) => TransactionModel.fromMap(map)).toList();
      return transactions;
    } catch (e) {
      AppLogger.error('Error getting all transactions', e);
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
    if (_isDisposed) {
      return const Stream.empty();
    }

    // Initialize and get initial data
    _ensureInitialized().then((_) => _notifyListeners());

    return _controller.stream;
  }

  Future<void> _notifyListeners() async {
    if (_isDisposed ||
        _transactionController == null ||
        _transactionController!.isClosed) {
      return;
    }

    try {
      final transactions = await getAllTransactions();
      _controller.add(transactions);
    } catch (e) {
      AppLogger.error('Error notifying listeners', e);
      if (!_controller.isClosed) {
        _controller.addError(e);
      }
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _transactionController?.close();
    _transactionController = null;
    AppLogger.info('TransactionSQLiteDataSource disposed');
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
}
