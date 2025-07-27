import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../presentation/widgets/update_notification_dialog.dart';

class UpdateNotificationService {
  static const String _lastShownVersionKey = 'last_shown_update_version';
  static const String _currentVersion =
      '1.2.0'; // Update this with each release

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
          '🔑 Select the users from the contact list',
          '🎨 Remove the ads for the users ',
          '👆 Biometric Users: Face ID, Touch ID, and Fingerprint still work great',
          '🛡️ Enhanced Security: Better protection for your debt tracking data',
          '🚀 No More Auth Errors: Fixed all authentication-related crashes',
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
