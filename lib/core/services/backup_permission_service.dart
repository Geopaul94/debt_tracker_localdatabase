import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'premium_service.dart';
import 'ad_service.dart';
import '../utils/logger.dart';

class BackupPermissionService {
  static const String _lastManualBackupKey = 'last_manual_backup_date';
  static const String _backupAdWatchedKey = 'backup_ad_watched';
  static const String _lastAutoBackupKey = 'last_auto_backup_date';

  static BackupPermissionService? _instance;
  static BackupPermissionService get instance =>
      _instance ??= BackupPermissionService._();
  BackupPermissionService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if user can perform manual backup (premium users or after watching ad)
  Future<bool> canPerformManualBackup() async {
    try {
      // Premium users can always backup
      final isPremium = await PremiumService.instance.isPremiumUnlocked();
      if (isPremium) {
        AppLogger.info('Premium user - manual backup allowed');
        return true;
      }

      // Check if user has watched an ad for backup
      final hasWatchedAd = _prefs?.getBool(_backupAdWatchedKey) ?? false;
      if (hasWatchedAd) {
        AppLogger.info('User has watched backup ad - manual backup allowed');
        return true;
      }

      AppLogger.info('User needs to watch ad for manual backup');
      return false;
    } catch (e) {
      AppLogger.error('Error checking manual backup permission', e);
      return false;
    }
  }

  // Mark that user has watched an ad for backup
  Future<void> markBackupAdWatched() async {
    await _prefs?.setBool(_backupAdWatchedKey, true);
    AppLogger.info('Backup ad watched - manual backup now allowed');
  }

  // Reset backup ad status (called after successful backup)
  Future<void> resetBackupAdStatus() async {
    await _prefs?.setBool(_backupAdWatchedKey, false);
    AppLogger.info('Backup ad status reset');
  }

  // Check if auto backup should run (every 4 days for non-premium users)
  Future<bool> shouldRunAutoBackup() async {
    try {
      // Premium users get daily auto backup
      final isPremium = await PremiumService.instance.isPremiumUnlocked();
      if (isPremium) {
        return true; // Auto backup service handles premium users
      }

      // For non-premium users, check if 4 days have passed since last auto backup
      final lastAutoBackup = _prefs?.getString(_lastAutoBackupKey);
      if (lastAutoBackup == null) {
        AppLogger.info('No previous auto backup - should run');
        return true;
      }

      final lastAutoBackupDate = DateTime.parse(lastAutoBackup);
      final daysSinceLastBackup =
          DateTime.now().difference(lastAutoBackupDate).inDays;

      final shouldRun = daysSinceLastBackup >= 4;
      AppLogger.info(
        'Days since last auto backup: $daysSinceLastBackup, should run: $shouldRun',
      );

      return shouldRun;
    } catch (e) {
      AppLogger.error('Error checking auto backup schedule', e);
      return false;
    }
  }

  // Mark auto backup as completed
  Future<void> markAutoBackupCompleted() async {
    await _prefs?.setString(
      _lastAutoBackupKey,
      DateTime.now().toIso8601String(),
    );
    AppLogger.info('Auto backup marked as completed');
  }

  // Get last auto backup date
  DateTime? get lastAutoBackupDate {
    final dateString = _prefs?.getString(_lastAutoBackupKey);
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get next auto backup date (4 days from last backup for non-premium)
  DateTime? get nextAutoBackupDate {
    final lastBackup = lastAutoBackupDate;
    if (lastBackup == null) return null;
    return lastBackup.add(const Duration(days: 4));
  }

  // Check if user has watched backup ad
  bool get hasWatchedBackupAd => _prefs?.getBool(_backupAdWatchedKey) ?? false;

  // Show reward ad for backup access
  Future<bool> showBackupAd() async {
    try {
      final success = await AdService.instance.showRewardedAd(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          markBackupAdWatched();
          AppLogger.info(
            'User earned reward for backup access: ${reward.amount} ${reward.type}',
          );
        },
      );

      if (success) {
        AppLogger.info('Backup ad shown successfully');
        return true;
      } else {
        AppLogger.error('Failed to show backup ad');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error showing backup ad', e);
      return false;
    }
  }
}
