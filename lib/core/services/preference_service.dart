import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _firstLaunchKey = 'first_launch';
  static const String _installDateKey = 'install_date';
  static const String _adsEnabledKey = 'ads_enabled';
  static const String _appSessionCountKey = 'app_session_count';

  static PreferenceService? _instance;
  static PreferenceService get instance => _instance ??= PreferenceService._();
  PreferenceService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Set install date if not already set
    if (!await isInstallDateSet()) {
      await setInstallDate(DateTime.now());
    }
  }

  // First launch methods
  Future<bool> isFirstLaunch() async {
    return _prefs?.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    await _prefs?.setBool(_firstLaunchKey, false);
  }

  // Install date methods
  Future<bool> isInstallDateSet() async {
    return _prefs?.containsKey(_installDateKey) ?? false;
  }

  Future<void> setInstallDate(DateTime date) async {
    await _prefs?.setString(_installDateKey, date.toIso8601String());
  }

  Future<DateTime?> getInstallDate() async {
    final dateString = _prefs?.getString(_installDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // App session tracking
  Future<int> getAppSessionCount() async {
    return _prefs?.getInt(_appSessionCountKey) ?? 0;
  }

  Future<void> incrementAppSession() async {
    final currentCount = await getAppSessionCount();
    await _prefs?.setInt(_appSessionCountKey, currentCount + 1);
  }

  // Ads methods
  Future<bool> shouldShowAds() async {
    final installDate = await getInstallDate();
    if (installDate == null) return false;

    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    return daysSinceInstall >= 0;
  }

  Future<bool> areAdsEnabled() async {
    return _prefs?.getBool(_adsEnabledKey) ?? false;
  }

  Future<void> setAdsEnabled(bool enabled) async {
    await _prefs?.setBool(_adsEnabledKey, enabled);
  }
}
