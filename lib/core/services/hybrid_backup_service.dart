import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';
import '../entities/backup_info.dart';
import 'google_drive_service.dart' hide BackupInfo;
import 'backup_permission_service.dart';

class HybridBackupService {
  static HybridBackupService? _instance;
  static HybridBackupService get instance =>
      _instance ??= HybridBackupService._();
  HybridBackupService._();

  SharedPreferences? _prefs;
  Directory? _backupDirectory;
  bool _isGoogleDriveAvailable = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _createBackupDirectory();
    await _checkGoogleDriveAvailability();
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

  Future<void> _checkGoogleDriveAvailability() async {
    try {
      await GoogleDriveService.instance.initialize();
      _isGoogleDriveAvailable = true;
      AppLogger.info('Google Drive is available');
    } catch (e) {
      _isGoogleDriveAvailable = false;
      AppLogger.info('Google Drive not available: $e');
    }
  }

  // Create backup (local + cloud if available)
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

      bool success = false;

      // Always create local backup
      final localSuccess = await _createLocalBackup(backupData);
      if (localSuccess) {
        success = true;
        AppLogger.info('Local backup created successfully');
      }

      // Try cloud backup if available
      if (_isGoogleDriveAvailable) {
        try {
          final cloudSuccess = await _createCloudBackup(backupData);
          if (cloudSuccess) {
            success = true;
            AppLogger.info('Cloud backup created successfully');
          }
        } catch (e) {
          AppLogger.error('Cloud backup failed, but local backup succeeded', e);
        }
      }

      // Reset backup ad status after successful backup
      if (success && showAd) {
        await BackupPermissionService.instance.resetBackupAdStatus();
      }

      return success;
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File(
        '${_backupDirectory!.path}/debt_tracker_backup_$timestamp.json',
      );

      await backupFile.writeAsString(jsonEncode(backupData));
      await _prefs?.setString(
        'last_local_backup_date',
        DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      AppLogger.error('Failed to create local backup', e);
      return false;
    }
  }

  Future<bool> _createCloudBackup(Map<String, dynamic> backupData) async {
    try {
      // Check if signed in to Google Drive
      final isSignedIn = await GoogleDriveService.instance.isSignedIn();
      if (!isSignedIn) {
        AppLogger.info('Not signed in to Google Drive, skipping cloud backup');
        return false;
      }

      // Create cloud backup
      final success = await GoogleDriveService.instance.createBackup();
      return success;
    } catch (e) {
      AppLogger.error('Failed to create cloud backup', e);
      return false;
    }
  }

  // Get available backups (local + cloud)
  Future<List<BackupInfo>> getAvailableBackups() async {
    final backups = <BackupInfo>[];

    // Get local backups
    final localBackups = await _getLocalBackups();
    backups.addAll(localBackups);

    // Get cloud backups if available
    if (_isGoogleDriveAvailable) {
      try {
        final isSignedIn = await GoogleDriveService.instance.isSignedIn();
        if (isSignedIn) {
          final cloudBackups =
              await GoogleDriveService.instance.getAvailableBackups();
          // Convert cloud backups to our BackupInfo format
          for (final cloudBackup in cloudBackups) {
            backups.add(
              BackupInfo(
                id: cloudBackup.id,
                name: cloudBackup.name,
                date: cloudBackup.createdAt,
                size: cloudBackup.size,
                isLocal: false,
                userEmail: GoogleDriveService.instance.userEmail,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.error('Failed to get cloud backups', e);
      }
    }

    // Sort by date (newest first)
    backups.sort((a, b) => b.date.compareTo(a.date));

    return backups;
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
        return await _restoreFromCloudBackup(backup.id);
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

  Future<bool> _restoreFromCloudBackup(String backupId) async {
    try {
      final success = await GoogleDriveService.instance.restoreFromBackup(
        backupId,
      );
      return success;
    } catch (e) {
      AppLogger.error('Failed to restore from cloud backup', e);
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

  // Sign in to Google Drive
  Future<bool> signInToGoogleDrive() async {
    try {
      final success = await GoogleDriveService.instance.signIn();
      if (success) {
        _isGoogleDriveAvailable = true;
        AppLogger.info('Successfully signed in to Google Drive');
      }
      return success;
    } catch (e) {
      AppLogger.error('Failed to sign in to Google Drive', e);
      return false;
    }
  }

  // Check if signed in to Google Drive
  Future<bool> isSignedInToGoogleDrive() async {
    try {
      return await GoogleDriveService.instance.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  // Get user email for Google Drive
  String? get googleDriveUserEmail => GoogleDriveService.instance.userEmail;

  // Get last backup date
  DateTime? get lastBackupDate {
    final dateString = _prefs?.getString('last_local_backup_date');
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Check if Google Drive is available
  bool get isGoogleDriveAvailable => _isGoogleDriveAvailable;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
