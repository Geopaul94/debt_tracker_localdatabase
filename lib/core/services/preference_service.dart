import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _firstLaunchKey = 'first_launch';
  static const String _installDateKey = 'install_date';
  static const String _adsEnabledKey = 'ads_enabled';
  static const String _appSessionCountKey = 'app_session_count';
  
  // Dummy data preferences
  static const String _dummyDataShownKey = 'dummy_data_shown';
  static const String _shouldShowDummyDataKey = 'should_show_dummy_data';

  // PacketSDK preferences
  static const String _packetSdkEnabledKey = 'packet_sdk_enabled';
  static const String _packetSdkConsentShownKey = 'packet_sdk_consent_shown';
  static const String _packetSdkLastRevenueKey = 'packet_sdk_last_revenue';

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

    // Enable dummy data for first-time users
    if (await isFirstLaunch()) {
      await setShouldShowDummyData(true);
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

  // Ads methods - simplified to show ads normally when enabled
  Future<bool> shouldShowAds() async {
    // Check if ads are explicitly disabled
    final adsEnabled = _prefs?.getBool(_adsEnabledKey);

    // If ads are explicitly disabled, don't show them
    if (adsEnabled == false) {
      return false;
    }

    // Otherwise, ads are enabled by default
    return true;
  }

  Future<bool> areAdsEnabled() async {
    return _prefs?.getBool(_adsEnabledKey) ?? true; // Default to true
  }

  Future<void> setAdsEnabled(bool enabled) async {
    await _prefs?.setBool(_adsEnabledKey, enabled);
  }

  // PacketSDK preferences methods
  Future<bool> isPacketSdkEnabled() async {
    return _prefs?.getBool(_packetSdkEnabledKey) ?? false; // Default to false
  }

  Future<void> setPacketSdkEnabled(bool enabled) async {
    await _prefs?.setBool(_packetSdkEnabledKey, enabled);
  }

  Future<bool> wasPacketSdkConsentShown() async {
    return _prefs?.getBool(_packetSdkConsentShownKey) ?? false;
  }

  Future<void> setPacketSdkConsentShown(bool shown) async {
    await _prefs?.setBool(_packetSdkConsentShownKey, shown);
  }

  Future<double> getPacketSdkLastRevenue() async {
    return _prefs?.getDouble(_packetSdkLastRevenueKey) ?? 0.0;
  }

  Future<void> setPacketSdkLastRevenue(double revenue) async {
    await _prefs?.setDouble(_packetSdkLastRevenueKey, revenue);
  }

  // Helper method to check if we should show PacketSDK consent
  Future<bool> shouldShowPacketSdkConsent() async {
    final consentShown = await wasPacketSdkConsentShown();
    final packetEnabled = await isPacketSdkEnabled();

    // Show consent if it hasn't been shown and PacketSDK is not enabled
    return !consentShown && !packetEnabled;
  }

  // Dummy data methods
  Future<bool> shouldShowDummyData() async {
    return _prefs?.getBool(_shouldShowDummyDataKey) ?? false;
  }

  Future<void> setShouldShowDummyData(bool show) async {
    await _prefs?.setBool(_shouldShowDummyDataKey, show);
  }

  Future<bool> wasDummyDataShown() async {
    return _prefs?.getBool(_dummyDataShownKey) ?? false;
  }

  Future<void> setDummyDataShown(bool shown) async {
    await _prefs?.setBool(_dummyDataShownKey, shown);
  }

  // Mark dummy data as viewed and disable it for future launches
  Future<void> markDummyDataViewed() async {
    await setDummyDataShown(true);
    await setShouldShowDummyData(false);
    print('📝 Dummy data marked as viewed and disabled for future launches');
  }
}
