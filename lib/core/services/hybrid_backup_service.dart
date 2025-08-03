import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import '../entities/backup_info.dart';
import 'backup_permission_service.dart';

class HybridBackupService {
  static HybridBackupService? _instance;
  static HybridBackupService get instance =>
      _instance ??= HybridBackupService._();
  HybridBackupService._();

  SharedPreferences? _prefs;
  Directory? _backupDirectory;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _createBackupDirectory();
    AppLogger.info('Hybrid backup service initialized');
  }

  Future<void> _createBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _backupDirectory = Directory('${appDir.path}/DebtTrackerBackups');

    if (!await _backupDirectory!.exists()) {
      await _backupDirectory!.create(recursive: true);
      AppLogger.info('Created backup directory: ${_backupDirectory!.path}');
    }
  }

  // Create backup (local only)
  Future<bool> createBackup({bool showAd = true}) async {
    try {
      // Check backup permissions if showing ad
      if (showAd) {
        final canBackup =
            await BackupPermissionService.instance.canPerformManualBackup();
        if (!canBackup) {
          final adShown = await BackupPermissionService.instance.showBackupAd();
          if (!adShown) {
            AppLogger.error('User needs to watch ad for backup');
            return false;
          }
        }
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

      // Always create local backup
      final localSuccess = await _createLocalBackup(backupData);
      if (localSuccess) {
        AppLogger.info('Local backup created successfully');
      }

      // Reset backup ad status after successful backup
      if (localSuccess && showAd) {
        await BackupPermissionService.instance.resetBackupAdStatus();
      }

      return localSuccess;
    } catch (e) {
      AppLogger.error('Failed to create backup', e);
      return false;
    }
  }

  Future<bool> _createLocalBackup(Map<String, dynamic> backupData) async {
    try {
      if (_backupDirectory == null) {
        await _createBackupDirectory();
      }

      // Create backup file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        '${_backupDirectory!.path}/debt_tracker_backup_$timestamp.json',
      );

      await backupFile.writeAsString(jsonEncode(backupData));

      // Clean up old backups
      await _cleanupOldBackups();

      AppLogger.info('Local backup created successfully: ${backupFile.path}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to create local backup', e);
      return false;
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final files = _backupDirectory!.listSync();
      final backupFiles =
          files
              .where(
                (file) =>
                    file is File && file.path.contains('debt_tracker_backup_'),
              )
              .cast<File>()
              .toList();

      // Keep only the last 10 backups
      if (backupFiles.length > 10) {
        backupFiles.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
        );

        for (int i = 10; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
          AppLogger.info('Deleted old backup: ${backupFiles[i].path}');
        }
      }
    } catch (e) {
      AppLogger.error('Error cleaning up old backups', e);
    }
  }

  // Get available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final localBackups = await _getLocalBackups();

      // Sort by date (newest first)
      localBackups.sort((a, b) => b.date.compareTo(a.date));

      return localBackups;
    } catch (e) {
      AppLogger.error('Failed to get available backups', e);
      return [];
    }
  }

  Future<List<BackupInfo>> _getLocalBackups() async {
    try {
      if (_backupDirectory == null) {
        await _createBackupDirectory();
      }

      final files = _backupDirectory!.listSync();
      final backupFiles =
          files
              .where(
                (file) =>
                    file is File && file.path.contains('debt_tracker_backup_'),
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

      return backups;
    } catch (e) {
      AppLogger.error('Failed to get local backups', e);
      return [];
    }
  }

  // Restore from backup
  Future<bool> restoreFromBackup(BackupInfo backup) async {
    try {
      if (backup.isLocal) {
        return await _restoreFromLocalBackup(backup.id);
      } else {
        return false; // No cloud backup support
      }
    } catch (e) {
      AppLogger.error('Failed to restore from backup', e);
      return false;
    }
  }

  Future<bool> _restoreFromLocalBackup(String backupPath) async {
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

      return await _restoreTransactions(transactions);
    } catch (e) {
      AppLogger.error('Failed to restore from local backup', e);
      return false;
    }
  }

  Future<bool> _restoreTransactions(List<TransactionModel> transactions) async {
    try {
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

      AppLogger.info('Transactions restored successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to restore transactions', e);
      return false;
    }
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

  // Get user email (returns null for local backup)
  String? get userEmail => null;

  String _formatDate(DateTime date) {
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
}
