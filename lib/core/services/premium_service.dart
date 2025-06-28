import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const String _premiumUnlockedKey = 'premium_unlocked';
  static const String _adFreeUntilKey = 'ad_free_until';

  static PremiumService? _instance;
  SharedPreferences? _prefs;

  PremiumService._internal();

  static Future<PremiumService> create() async {
    if (_instance == null) {
      _instance = PremiumService._internal();
      await _instance!._initialize();
    }
    return _instance!;
  }

  static PremiumService get instance {
    if (_instance == null) {
      throw Exception('PremiumService not initialized. Call create() first.');
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Premium status management
  Future<bool> isPremiumUnlocked() async {
    return _prefs?.getBool(_premiumUnlockedKey) ?? false;
  }

  Future<void> setPremiumUnlocked(bool unlocked) async {
    await _prefs?.setBool(_premiumUnlockedKey, unlocked);
  }

  // Ad-free status management
  Future<bool> isAdFree() async {
    final adFreeUntilString = _prefs?.getString(_adFreeUntilKey);
    if (adFreeUntilString == null) return false;

    try {
      final adFreeUntil = DateTime.parse(adFreeUntilString);
      return DateTime.now().isBefore(adFreeUntil);
    } catch (e) {
      return false;
    }
  }

  Future<void> setAdFreeFor2Hours() async {
    final adFreeUntil = DateTime.now().add(Duration(hours: 2));
    await _prefs?.setString(_adFreeUntilKey, adFreeUntil.toIso8601String());
  }

  Future<DateTime?> getAdFreeUntil() async {
    final adFreeUntilString = _prefs?.getString(_adFreeUntilKey);
    if (adFreeUntilString == null) return null;

    try {
      return DateTime.parse(adFreeUntilString);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAdFree() async {
    await _prefs?.remove(_adFreeUntilKey);
  }

  // Check if user can skip authentication (has ad-free or premium)
  Future<bool> canSkipAuthentication() async {
    final isPremium = await isPremiumUnlocked();
    final hasAdFreeAccess = await isAdFree();
    return isPremium || hasAdFreeAccess;
  }

  // Get remaining ad-free time in minutes
  Future<int> getRemainingAdFreeMinutes() async {
    if (!await isAdFree()) return 0;

    final adFreeUntil = await getAdFreeUntil();
    if (adFreeUntil == null) return 0;

    final remaining = adFreeUntil.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }
}
