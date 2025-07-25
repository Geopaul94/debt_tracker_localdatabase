import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'premium_service.dart';
import 'local_backup_service.dart';
import 'google_drive_service.dart';
import 'backup_permission_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      AppLogger.info('Background task started: $task');

      switch (task) {
        case AutoBackupService.dailyBackupTaskName:
          return await AutoBackupService._performBackgroundBackup();
        case AutoBackupService.cleanupTaskName:
          return await AutoBackupService._performBackgroundCleanup();
        default:
          AppLogger.error('Unknown background task: $task');
          return false;
      }
    } catch (e) {
      AppLogger.error('Background task failed: $task', e);
      return false;
    }
  });
}

class AutoBackupService {
  static const String dailyBackupTaskName = 'daily_backup_task';
  static const String cleanupTaskName = 'cleanup_old_backups_task';
  static const String _lastAutoBackupKey = 'last_auto_backup_date';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';

  static AutoBackupService? _instance;
  static AutoBackupService get instance => _instance ??= AutoBackupService._();
  AutoBackupService._();

  SharedPreferences? _prefs;
  Timer? _periodicTimer;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );

    // Check if we should enable auto backup for premium users
    await _checkAndEnableAutoBackup();

    // Start periodic check (every hour in foreground)
    _startPeriodicCheck();

    AppLogger.info('Auto backup service initialized');
  }

  Future<void> _checkAndEnableAutoBackup() async {
    try {
      final isPremium = await PremiumService.instance.isPremiumUnlocked();
      final isSignedIn = await LocalBackupService.instance.isSignedIn();

      if (isPremium && isSignedIn) {
        await enableAutoBackup();
      } else {
        await disableAutoBackup();
      }
    } catch (e) {
      AppLogger.error('Error checking auto backup status', e);
    }
  }

  Future<void> enableAutoBackup() async {
    try {
      await _prefs?.setBool(_autoBackupEnabledKey, true);

      // Cancel existing tasks
      await Workmanager().cancelAll();

      // Schedule daily backup (runs every 24 hours)
      await Workmanager().registerPeriodicTask(
        dailyBackupTaskName,
        dailyBackupTaskName,
        frequency: Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      // Schedule weekly cleanup (runs every 7 days)
      await Workmanager().registerPeriodicTask(
        cleanupTaskName,
        cleanupTaskName,
        frequency: Duration(days: 7),
        constraints: Constraints(networkType: NetworkType.connected),
      );

      AppLogger.info('Auto backup enabled successfully');
    } catch (e) {
      AppLogger.error('Failed to enable auto backup', e);
    }
  }

  Future<void> disableAutoBackup() async {
    try {
      await _prefs?.setBool(_autoBackupEnabledKey, false);
      await Workmanager().cancelAll();
      AppLogger.info('Auto backup disabled');
    } catch (e) {
      AppLogger.error('Failed to disable auto backup', e);
    }
  }

  Future<bool> isAutoBackupEnabled() async {
    return _prefs?.getBool(_autoBackupEnabledKey) ?? false;
  }

  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(Duration(hours: 1), (_) async {
      await _checkAndPerformBackup();
    });
  }

  Future<void> _checkAndPerformBackup() async {
    try {
      final isEnabled = await isAutoBackupEnabled();
      if (!isEnabled) return;

      final isPremium = await PremiumService.instance.isPremiumUnlocked();
      if (!isPremium) {
        await disableAutoBackup();
        return;
      }

      final shouldBackup = await _shouldPerformAutoBackup();
      if (shouldBackup) {
        await _performAutoBackup();
      }
    } catch (e) {
      AppLogger.error('Error in periodic backup check', e);
    }
  }

  Future<bool> _shouldPerformAutoBackup() async {
    final lastBackupString = _prefs?.getString(_lastAutoBackupKey);
    if (lastBackupString == null) return true;

    try {
      final lastBackup = DateTime.parse(lastBackupString);
      final hoursSinceBackup = DateTime.now().difference(lastBackup).inHours;
      return hoursSinceBackup >= 24; // Backup once every 24 hours
    } catch (e) {
      return true; // If parsing fails, perform backup
    }
  }

  Future<void> _performAutoBackup() async {
    try {
      final isSignedIn = await LocalBackupService.instance.isSignedIn();
      if (!isSignedIn) {
        AppLogger.info(
          'User not signed in to Google Drive, skipping auto backup',
        );
        return;
      }

      final success = await LocalBackupService.instance.createBackup();
      if (success) {
        await _prefs?.setString(
          _lastAutoBackupKey,
          DateTime.now().toIso8601String(),
        );
        AppLogger.info('Auto backup completed successfully');
      } else {
        AppLogger.error('Auto backup failed');
      }
    } catch (e) {
      AppLogger.error('Error performing auto backup', e);
    }
  }

  // Background task methods (static for Workmanager)
  static Future<bool> _performBackgroundBackup() async {
    try {
      // Initialize required services
      await PremiumService.create();
      await LocalBackupService.instance.initialize();
      await GoogleDriveService.instance.initialize();
      await BackupPermissionService.instance.initialize();

      // Check if backup should run based on user type and schedule
      final shouldBackup =
          await BackupPermissionService.instance.shouldRunAutoBackup();
      if (!shouldBackup) {
        AppLogger.info('Backup not needed yet based on schedule');
        return true;
      }

      bool success = false;

      // Always create local backup
      final localSuccess = await LocalBackupService.instance.createBackup();
      if (localSuccess) {
        success = true;
        AppLogger.info('Local auto backup completed successfully');
      }

      // Try cloud backup if available
      try {
        final isSignedIn = await GoogleDriveService.instance.isSignedIn();
        if (isSignedIn) {
          final cloudSuccess = await GoogleDriveService.instance.createBackup();
          if (cloudSuccess) {
            success = true;
            AppLogger.info('Cloud auto backup completed successfully');
          }
        }
      } catch (e) {
        AppLogger.error(
          'Cloud auto backup failed, but local backup succeeded',
          e,
        );
      }

      if (success) {
        // Mark auto backup as completed
        await BackupPermissionService.instance.markAutoBackupCompleted();
        AppLogger.info('Background backup completed successfully');
      } else {
        AppLogger.error('Background backup failed');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error in background backup', e);
      return false;
    }
  }

  static Future<bool> _performBackgroundCleanup() async {
    try {
      AppLogger.info('Performing background cleanup...');

      // Initialize required services
      await LocalBackupService.instance.initialize();

      final isSignedIn = await LocalBackupService.instance.isSignedIn();
      if (!isSignedIn) {
        AppLogger.info('User not signed in, skipping cleanup');
        return true;
      }

      // Note: The cleanup is handled automatically in GoogleDriveService.createBackup()
      // This task serves as a periodic check
      AppLogger.info('Background cleanup completed');
      return true;
    } catch (e) {
      AppLogger.error('Background cleanup failed', e);
      return false;
    }
  }

  DateTime? get lastAutoBackupDate {
    final lastBackupString = _prefs?.getString(_lastAutoBackupKey);
    if (lastBackupString == null) return null;
    try {
      return DateTime.parse(lastBackupString);
    } catch (e) {
      return null;
    }
  }

  Future<void> triggerManualAutoBackup() async {
    await _performAutoBackup();
  }

  void dispose() {
    _periodicTimer?.cancel();
  }
}
