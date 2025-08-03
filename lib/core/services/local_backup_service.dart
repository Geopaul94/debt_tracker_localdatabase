import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class LocalBackupService {
  static const String _backupFolderName = 'DebtTrackerBackups';
  static const String _backupFilePrefix = 'debt_tracker_backup_';
  static const String _lastBackupDateKey = 'last_local_backup_date';
  static const int _maxBackupRetentionDays = 30;

  static LocalBackupService? _instance;
  static LocalBackupService get instance =>
      _instance ??= LocalBackupService._();
  LocalBackupService._();

  SharedPreferences? _prefs;
  Directory? _backupDirectory;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _createBackupDirectory();
    AppLogger.info('Local backup service initialized');
  }

  Future<void> _createBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _backupDirectory = Directory('${appDir.path}/$_backupFolderName');

    if (!await _backupDirectory!.exists()) {
      await _backupDirectory!.create(recursive: true);
      AppLogger.info('Created backup directory: ${_backupDirectory!.path}');
    }
  }

  // Create a local backup
  Future<bool> createBackup() async {
    try {
      if (_backupDirectory == null) {
        await _createBackupDirectory();
      }

      // Get all transactions from database
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final transactionMaps = await db.query('transactions');
      final transactions =
          transactionMaps.map((map) => TransactionModel.fromMap(map)).toList();

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      // Create backup file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        '${_backupDirectory!.path}/$_backupFilePrefix$timestamp.json',
      );

      await backupFile.writeAsString(jsonEncode(backupData));

      // Update last backup date
      await _prefs?.setString(
        _lastBackupDateKey,
        DateTime.now().toIso8601String(),
      );

      // Clean up old backups
      await _cleanupOldBackups();

      AppLogger.info('Local backup created successfully: ${backupFile.path}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to create local backup', e);
      return false;
    }
  }

  // Get available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      if (_backupDirectory == null) {
        await _createBackupDirectory();
      }

      final files = _backupDirectory!.listSync();
      final backupFiles =
          files
              .where(
                (file) => file is File && file.path.contains(_backupFilePrefix),
              )
              .cast<File>()
              .toList();

      final backups = <BackupInfo>[];

      for (final file in backupFiles) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final timestamp = DateTime.parse(data['timestamp'] as String);

          backups.add(
            BackupInfo(
              id: file.path,
              name: 'Local Backup - ${_formatDate(timestamp)}',
              date: timestamp,
              size: await file.length(),
              isLocal: true,
            ),
          );
        } catch (e) {
          AppLogger.error('Error reading backup file: ${file.path}', e);
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b.date.compareTo(a.date));

      return backups;
    } catch (e) {
      AppLogger.error('Failed to get available backups', e);
      return [];
    }
  }

  // Restore from backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        AppLogger.error('Backup file not found: $backupPath');
        return false;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final transactions =
          (data['transactions'] as List)
              .map((t) => TransactionModel.fromMap(t as Map<String, dynamic>))
              .toList();

      // Clear existing data and restore
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        // Clear existing transactions
        await txn.delete('transactions');

        // Insert restored transactions
        for (final transaction in transactions) {
          await txn.insert('transactions', transaction.toMap());
        }
      });

      AppLogger.info('Local backup restored successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to restore from local backup', e);
      return false;
    }
  }

  // Clean up old backups
  Future<void> _cleanupOldBackups() async {
    try {
      final files = _backupDirectory!.listSync();
      final backupFiles =
          files
              .where(
                (file) => file is File && file.path.contains(_backupFilePrefix),
              )
              .cast<File>()
              .toList();

      final cutoffDate = DateTime.now().subtract(
        const Duration(days: _maxBackupRetentionDays),
      );

      for (final file in backupFiles) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final timestamp = DateTime.parse(data['timestamp'] as String);

          if (timestamp.isBefore(cutoffDate)) {
            await file.delete();
            AppLogger.info('Deleted old backup: ${file.path}');
          }
        } catch (e) {
          AppLogger.error('Error checking backup file: ${file.path}', e);
        }
      }
    } catch (e) {
      AppLogger.error('Error cleaning up old backups', e);
    }
  }

  // Get last backup date
  DateTime? get lastBackupDate {
    final dateString = _prefs?.getString(_lastBackupDateKey);
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Check if backup is needed
  Future<bool> shouldPerformBackup() async {
    final lastBackup = lastBackupDate;
    if (lastBackup == null) return true;

    final daysSinceLastBackup = DateTime.now().difference(lastBackup).inDays;
    return daysSinceLastBackup >= 1; // Backup daily
  }

  // Sign in method (always returns true for local backup)
  Future<bool> signIn() async {
    await initialize();
    return true;
  }

  // Sign out method (no-op for local backup)
  Future<void> signOut() async {
    // No sign out needed for local backup
  }

  // Check if signed in (always true for local backup)
  Future<bool> isSignedIn() async {
    return true;
  }

  // Get user email (returns device info for local backup)
  String get userEmail => 'Local Device Backup';

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class BackupInfo {
  final String id;
  final String name;
  final DateTime date;
  final int size;
  final bool isLocal;

  BackupInfo({
    required this.id,
    required this.name,
    required this.date,
    required this.size,
    this.isLocal = false,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final backupDate = DateTime(date.year, date.month, date.day);

    if (backupDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (backupDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
