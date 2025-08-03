import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';
import '../utils/logger.dart';

class TrashService {
  static TrashService? _instance;
  static TrashService get instance => _instance ??= TrashService._();
  TrashService._();

  static const int _retentionDays = 30;
  Timer? _cleanupTimer;

  Future<void> initialize() async {
    // Start periodic cleanup (check every 24 hours)
    _cleanupTimer = Timer.periodic(
      Duration(hours: 24),
      (_) => _cleanupExpiredItems(),
    );

    // Run initial cleanup
    await _cleanupExpiredItems();
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  // Move transaction to trash (soft delete)
  Future<bool> moveToTrash(String transactionId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get the transaction
      final transactionMaps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (transactionMaps.isEmpty) {
        AppLogger.error('Transaction not found for trash: $transactionId');
        return false;
      }

      final transaction = TransactionModel.fromMap(transactionMaps.first);

      // Insert into trash table
      await db.insert('trash', {
        'id': transaction.id,
        'name': transaction.name,
        'description': transaction.description,
        'amount': transaction.amount,
        'type': transaction.type.toString().split('.').last,
        'date': transaction.date.toIso8601String(),
        'created_at': transaction.createdAt.toIso8601String(),
        'updated_at': transaction.updatedAt.toIso8601String(),
        'deleted_at': DateTime.now().toIso8601String(),
        'currency_code': transaction.currency.code,
        'currency_symbol': transaction.currency.symbol,
        'currency_name': transaction.currency.name,
        'currency_flag': transaction.currency.flag,
      });

      // Remove from transactions table
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      AppLogger.info('Transaction moved to trash: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to move transaction to trash', e);
      return false;
    }
  }

  // Get all items in trash
  Future<List<TrashItem>> getTrashItems() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final trashMaps = await db.query('trash', orderBy: 'deleted_at DESC');

      return trashMaps.map((map) => TrashItem.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Failed to get trash items', e);
      return [];
    }
  }

  // Restore transaction from trash
  Future<bool> restoreFromTrash(String transactionId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get the trash item
      final trashMaps = await db.query(
        'trash',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (trashMaps.isEmpty) {
        AppLogger.error('Trash item not found: $transactionId');
        return false;
      }

      final trashItem = TrashItem.fromMap(trashMaps.first);

      // Insert back into transactions table
      await db.insert('transactions', {
        'id': trashItem.id,
        'name': trashItem.name,
        'description': trashItem.description,
        'amount': trashItem.amount,
        'type': trashItem.type,
        'date': trashItem.date.toIso8601String(),
        'created_at': trashItem.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(), // Update timestamp
        'currency_code': trashItem.currencyCode,
        'currency_symbol': trashItem.currencySymbol,
        'currency_name': trashItem.currencyName,
        'currency_flag': trashItem.currencyFlag,
      });

      // Remove from trash table
      await db.delete('trash', where: 'id = ?', whereArgs: [transactionId]);

      AppLogger.info('Transaction restored from trash: $transactionId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to restore transaction from trash', e);
      return false;
    }
  }

  // Permanently delete from trash
  Future<bool> permanentlyDelete(String transactionId) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final rowsAffected = await db.delete(
        'trash',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (rowsAffected > 0) {
        AppLogger.info('Transaction permanently deleted: $transactionId');
        return true;
      } else {
        AppLogger.error(
          'Trash item not found for permanent deletion: $transactionId',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to permanently delete transaction', e);
      return false;
    }
  }

  // Empty entire trash
  Future<bool> emptyTrash() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.delete('trash');
      AppLogger.info('Trash emptied successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to empty trash', e);
      return false;
    }
  }

  // Clean up expired items (older than 30 days)
  Future<void> _cleanupExpiredItems() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final cutoffDate = DateTime.now().subtract(
        Duration(days: _retentionDays),
      );

      final expiredItems = await db.query(
        'trash',
        where: 'deleted_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      if (expiredItems.isNotEmpty) {
        await db.delete(
          'trash',
          where: 'deleted_at < ?',
          whereArgs: [cutoffDate.toIso8601String()],
        );

        AppLogger.info('Cleaned up ${expiredItems.length} expired trash items');
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup expired trash items', e);
    }
  }

  // Get count of items in trash
  Future<int> getTrashCount() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM trash');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get trash count', e);
      return 0;
    }
  }

  // Get items expiring soon (within 7 days)
  Future<List<TrashItem>> getItemsExpiringSoon() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final cutoffDate = DateTime.now().subtract(
        Duration(days: _retentionDays - 7),
      );

      final trashMaps = await db.query(
        'trash',
        where: 'deleted_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
        orderBy: 'deleted_at ASC',
      );

      return trashMaps.map((map) => TrashItem.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('Failed to get items expiring soon', e);
      return [];
    }
  }
}

class TrashItem {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String type;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime deletedAt;
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final String currencyFlag;

  const TrashItem({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
    required this.currencyFlag,
  });

  factory TrashItem.fromMap(Map<String, dynamic> map) {
    return TrashItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: DateTime.parse(map['deleted_at'] as String),
      currencyCode: map['currency_code'] as String? ?? 'USD',
      currencySymbol: map['currency_symbol'] as String? ?? '\$',
      currencyName: map['currency_name'] as String? ?? 'US Dollar',
      currencyFlag: map['currency_flag'] as String? ?? '🇺🇸',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt.toIso8601String(),
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_name': currencyName,
      'currency_flag': currencyFlag,
    };
  }

  // Convert to TransactionModel for restoration
  TransactionModel toTransactionModel() {
    return TransactionModel(
      id: id,
      name: name,
      description: description,
      amount: amount,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.$type',
        orElse: () => TransactionType.iOwe,
      ),
      date: date,
      currency: TransactionCurrency(
        code: currencyCode,
        symbol: currencySymbol,
        name: currencyName,
        flag: currencyFlag,
      ),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Days remaining before permanent deletion
  int get daysUntilDeletion {
    final deletionDate = deletedAt.add(Duration(days: 30));
    final remaining = deletionDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  // Formatted deletion date
  String get formattedDeletedAt {
    return '${deletedAt.day}/${deletedAt.month}/${deletedAt.year}';
  }

  // Is this item expiring soon?
  bool get isExpiringSoon {
    return daysUntilDeletion <= 7;
  }
}
