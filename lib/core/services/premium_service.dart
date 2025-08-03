import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const String _premiumUnlockedKey = 'premium_unlocked';
  static const String _adFreeUntilKey = 'ad_free_until';
  static const String _premiumExpiryDateKey = 'premium_expiry_date';

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
    final isUnlocked = _prefs?.getBool(_premiumUnlockedKey) ?? false;
    
    // Check if premium has expired
    if (isUnlocked) {
      final expiryDate = await getPremiumExpiryDate();
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        // Premium has expired, revoke access
        await setPremiumUnlocked(false);
        await clearPremiumExpiryDate();
        return false;
      }
    }
    
    return isUnlocked;
  }

  Future<void> setPremiumUnlocked(bool unlocked) async {
    await _prefs?.setBool(_premiumUnlockedKey, unlocked);
  }

  // Premium expiry date management
  Future<DateTime?> getPremiumExpiryDate() async {
    final expiryDateString = _prefs?.getString(_premiumExpiryDateKey);
    if (expiryDateString == null) return null;

    try {
      return DateTime.parse(expiryDateString);
    } catch (e) {
      return null;
    }
  }

  Future<void> setPremiumExpiryDate(DateTime expiryDate) async {
    await _prefs?.setString(_premiumExpiryDateKey, expiryDate.toIso8601String());
  }

  Future<void> clearPremiumExpiryDate() async {
    await _prefs?.remove(_premiumExpiryDateKey);
  }

  Future<int> getPremiumDaysRemaining() async {
    final expiryDate = await getPremiumExpiryDate();
    if (expiryDate == null) return 0;

    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
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
    final adFreeUntil = DateTime.now().add(const Duration(hours: 2));
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
