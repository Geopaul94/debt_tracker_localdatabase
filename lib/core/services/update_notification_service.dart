import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../presentation/widgets/update_notification_dialog.dart';

class UpdateNotificationService {
  static const String _lastShownVersionKey = 'last_shown_update_version';
  static const String _currentVersion =
      '1.3.0'; // Update this with each release

  static UpdateNotificationService? _instance;
  static UpdateNotificationService get instance =>
      _instance ??= UpdateNotificationService._();
  UpdateNotificationService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if we should show update notification
  Future<bool> shouldShowUpdateNotification() async {
    final lastShownVersion = _prefs?.getString(_lastShownVersionKey);
    return lastShownVersion != _currentVersion;
  }

  // Mark current version as shown
  Future<void> markUpdateNotificationShown() async {
    await _prefs?.setString(_lastShownVersionKey, _currentVersion);
  }

  // Show update notification dialog
  Future<void> showUpdateNotification(BuildContext context) async {
    if (!await shouldShowUpdateNotification()) return;

    // Define the updates for current version
    final List<String> currentUpdates = _getCurrentVersionUpdates();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => UpdateNotificationDialog(
            version: _currentVersion,
            updates: currentUpdates,
            onClose: () {
              Navigator.of(context).pop();
              markUpdateNotificationShown();
            },
          ),
    );
  }

  // Get updates for current version
  List<String> _getCurrentVersionUpdates() {
    // Update this list with each new version
    switch (_currentVersion) {
      case '1.2.0':
        return [
          '🔐 MAJOR FIX: Authentication now works with ALL security methods!',
          '📱 PIN Users: Your PIN authentication now works perfectly',
          '🔒 Pattern Users:google drive backup',
          '🎨 Pattern Users: Pattern locks now work seamlessly',
          '👆 watch one ad and use 2 hours ad free ',
          '🛡️ Trash bin for 30 days deleted data backup',
          '🚀 Ad free premium features',
          '💯 Universal Compatibility: Works on all Android devices regardless of security setup',
        ];
      case '1.1.9':
        return [
          '🎨 UI Improvements: Enhanced authentication screen design',
          '🐛 Bug fixes and performance optimizations',
        ];
      default:
        return ['🚀 General improvements and bug fixes'];
    }
  }

  // Get current app version
  static String get currentVersion => _currentVersion;
}
