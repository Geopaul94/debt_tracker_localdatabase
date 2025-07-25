import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _firstLaunchKey = 'first_launch';
  static const String _installDateKey = 'install_date';
  static const String _adsEnabledKey = 'ads_enabled';
  static const String _sampleDataAddedKey = 'sample_data_added';
  static const String _hasDummyDataKey = 'has_dummy_data';
  static const String _hasRealTransactionKey = 'has_real_transaction';
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

  // Dummy data management methods
  Future<bool> hasDummyData() async {
    return _prefs?.getBool(_hasDummyDataKey) ?? false;
  }

  Future<void> setHasDummyData(bool hasData) async {
    await _prefs?.setBool(_hasDummyDataKey, hasData);
  }

  Future<bool> hasRealTransaction() async {
    return _prefs?.getBool(_hasRealTransactionKey) ?? false;
  }

  Future<void> setHasRealTransaction(bool hasReal) async {
    await _prefs?.setBool(_hasRealTransactionKey, hasReal);
  }

  // App session tracking
  Future<int> getAppSessionCount() async {
    return _prefs?.getInt(_appSessionCountKey) ?? 0;
  }

  Future<void> incrementAppSession() async {
    final currentCount = await getAppSessionCount();
    await _prefs?.setInt(_appSessionCountKey, currentCount + 1);
  }

  // Check if dummy data should be cleaned up
  Future<bool> shouldCleanupDummyData() async {
    final hasDummy = await hasDummyData();
    final hasReal = await hasRealTransaction();
    final sessionCount = await getAppSessionCount();

    // Clean up if user has added real transaction OR after 1 app session (first view)
    return hasDummy && (hasReal || sessionCount >= 1);
  }

  // Check if sample data is currently being displayed
  Future<bool> isSampleDataDisplayed() async {
    final hasDummy = await hasDummyData();
    final hasReal = await hasRealTransaction();

    // Sample data is displayed if we have dummy data but no real transactions yet
    return hasDummy && !hasReal;
  }

  // Reset dummy data flags
  Future<void> resetDummyDataFlags() async {
    await setHasDummyData(false);
  }

  // Force cleanup after first view
  Future<void> markFirstViewCompleted() async {
    final sessionCount = await getAppSessionCount();
    if (sessionCount == 1) {
      // After first view, mark that dummy data should be cleaned up
      await setHasDummyData(false);
    }
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

  Future<void> removeSampleDataFlag() async {
    await _prefs?.setBool(_sampleDataAddedKey, false);
  }
}
