# 🚀 Complete Google AdMob Integration Guide for Flutter

## The Ultimate Guide: From Zero to Professional AdMob Implementation

This comprehensive guide documents a production-ready AdMob integration with advanced features like progressive rollout, background loading, and optimal user experience. Perfect for developers of all levels.

---

## 📋 Table of Contents

1. [Understanding AdMob Integration](#understanding-admob-integration)
2. [Project Setup and Configuration](#project-setup-and-configuration)
3. [AdMob Account and Console Setup](#admob-account-and-console-setup)
4. [Advanced Ad Service Implementation](#advanced-ad-service-implementation)
5. [Progressive Ad Rollout Strategy](#progressive-ad-rollout-strategy)
6. [UI Integration and Widget Implementation](#ui-integration-and-widget-implementation)
7. [Testing and Production Deployment](#testing-and-production-deployment)
8. [Troubleshooting and Best Practices](#troubleshooting-and-best-practices)

---

## 🎯 Understanding AdMob Integration

### What You'll Build

A sophisticated ad system featuring:
- **Progressive rollout** (Week 1: No ads → Week 4+: All ads)
- **Background ad preloading** for instant display
- **Multiple ad types** (Banner, Interstitial, Rewarded, App Open)
- **Optimized user experience** with minimal performance impact
- **Production-ready architecture** with proper error handling

### Key Benefits
- 🚀 **Better UX**: Non-intrusive ad experience
- 💰 **Higher Revenue**: Optimized ad placement and timing
- ⚡ **Performance**: Background loading prevents UI blocking
- 🎯 **Strategic**: Progressive rollout reduces user churn
- 🛡️ **Reliable**: Robust error handling and fallbacks

---

## 🔧 Project Setup and Configuration

### 1. Add Dependencies

**File**: `pubspec.yaml`
```yaml
dependencies:
  # Essential for AdMob
  google_mobile_ads: ^5.1.0
  
  # Required for preferences (install date tracking)
  shared_preferences: ^2.3.2
  
  # For dependency injection
  get_it: ^8.0.2
```

### 2. Android Configuration

**File**: `android/app/build.gradle.kts`
```kotlin
android {
    compileSdk = 34
    
    defaultConfig {
        minSdk = 21  // Minimum for AdMob
        targetSdk = 34
    }
}

dependencies {
    // Required for AdMob
    implementation("com.google.android.gms:play-services-ads:23.0.0")
}
```

**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<application>
    <!-- Add your AdMob App ID -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-YOUR_ADMOB_APP_ID~YOUR_APP_ID"/>
        
    <!-- Network security for ads -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
</application>
```

---

## 🏢 AdMob Account and Console Setup

### Step 1: Create AdMob Account

1. Go to [Google AdMob Console](https://apps.admob.google.com/)
2. Sign in with Google account
3. Accept terms and create account
4. Complete tax information and payment setup

### Step 2: Add Your App

1. Click "Add app"
2. Choose "Android" platform
3. Enter app details:
   - **App name**: Your app name
   - **Package name**: `com.yourcompany.yourapp`
   - **Category**: Finance (for debt tracker)

### Step 3: Create Ad Units

Create these ad units in your AdMob dashboard:

#### **Banner Ad Unit**
- **Name**: "Home Screen Banner"
- **Format**: Banner
- **Size**: 320x50 (Standard)

#### **Interstitial Ad Unit**
- **Name**: "Transaction Complete"
- **Format**: Interstitial
- **Type**: Display

#### **Rewarded Ad Unit**
- **Name**: "Premium Features"
- **Format**: Rewarded Video
- **Type**: Video

#### **App Open Ad Unit**
- **Name**: "App Launch"
- **Format**: App Open
- **Type**: Display

### Step 4: Get Your IDs

After creating ad units, copy these IDs:
- **App ID**: `ca-app-pub-1234567890123456~1234567890`
- **Banner Unit ID**: `ca-app-pub-1234567890123456/1234567890`
- **Interstitial Unit ID**: `ca-app-pub-1234567890123456/1234567890`
- **Rewarded Unit ID**: `ca-app-pub-1234567890123456/1234567890`
- **App Open Unit ID**: `ca-app-pub-1234567890123456/1234567890`

---

## 🚀 Advanced Ad Service Implementation

### PreferenceService for Install Date Tracking

**File**: `lib/core/services/preference_service.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static final PreferenceService _instance = PreferenceService._internal();
  static PreferenceService get instance => _instance;
  PreferenceService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Set install date if not already set
    if (getInstallDate() == null) {
      await setInstallDate(DateTime.now());
    }
  }

  DateTime? getInstallDate() {
    final timestamp = _prefs?.getInt('install_date');
    return timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setInstallDate(DateTime date) async {
    await _prefs?.setInt('install_date', date.millisecondsSinceEpoch);
  }
}
```

### Core AdService Class

**File**: `lib/core/services/ad_service.dart`

```dart
import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'preference_service.dart';

enum AdWeek {
  week1,     // No ads - Let users get familiar
  week2,     // Interstitial and rewarded only
  week3,     // Add app open ads
  week4Plus, // All ads including banners
}

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  // Background loading optimization
  Timer? _backgroundLoadTimer;
  bool _isLoadingInBackground = false;

  // 🔥 REPLACE WITH YOUR REAL AD UNIT IDs
  static final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-YOUR_ID/YOUR_BANNER_ID'     // Your Android Banner ID
      : 'ca-app-pub-YOUR_ID/YOUR_BANNER_ID';    // Your iOS Banner ID

  static final String _interstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-YOUR_ID/YOUR_INTERSTITIAL_ID'  // Your Android Interstitial ID
      : 'ca-app-pub-YOUR_ID/YOUR_INTERSTITIAL_ID'; // Your iOS Interstitial ID

  static final String _rewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-YOUR_ID/YOUR_REWARDED_ID'      // Your Android Rewarded ID
      : 'ca-app-pub-YOUR_ID/YOUR_REWARDED_ID';     // Your iOS Rewarded ID

  static final String _openAppAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-YOUR_ID/YOUR_APPOPEN_ID'       // Your Android App Open ID
      : 'ca-app-pub-YOUR_ID/YOUR_APPOPEN_ID';      // Your iOS App Open ID

  /// Initialize AdMob SDK and start background loading
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      
      // Configure ad settings
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [], // Add test device IDs for testing
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        ),
      );

      _isInitialized = true;
      print('✅ AdMob initialized successfully');

      // Start background ad preloading
      _startBackgroundLoading();
    } catch (e) {
      print('❌ AdMob initialization failed: $e');
    }
  }

  /// Determine current ad week based on app install date
  Future<AdWeek> _getCurrentAdWeek() async {
    final installDate = await PreferenceService.instance.getInstallDate();
    if (installDate == null) return AdWeek.week1;

    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    final weeksSinceInstall = (daysSinceInstall / 7).floor();

    if (weeksSinceInstall == 0) return AdWeek.week1;      // Week 1: No ads
    if (weeksSinceInstall == 1) return AdWeek.week2;      // Week 2: Limited ads
    if (weeksSinceInstall == 2) return AdWeek.week3;      // Week 3: More ads
    return AdWeek.week4Plus;                              // Week 4+: All ads
  }

  /// Check if specific ad type should be shown based on current week
  Future<bool> _shouldShowAdType(String adType) async {
    final currentWeek = await _getCurrentAdWeek();

    switch (currentWeek) {
      case AdWeek.week1:
        return false; // No ads in first week
      case AdWeek.week2:
        return adType == 'interstitial' || adType == 'rewarded';
      case AdWeek.week3:
        return adType == 'interstitial' || 
               adType == 'rewarded' || 
               adType == 'openapp';
      case AdWeek.week4Plus:
        return true; // All ad types allowed
    }
  }

  /// Start background ad loading to reduce main thread blocking
  void _startBackgroundLoading() {
    _backgroundLoadTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (!_isLoadingInBackground) {
        _loadAdsInBackground();
      }
    });
  }

  /// Load ads concurrently in background
  Future<void> _loadAdsInBackground() async {
    if (_isLoadingInBackground || !_isInitialized) return;
    _isLoadingInBackground = true;

    try {
      final futures = <Future>[];

      // Load all ad types concurrently
      if (_interstitialAd == null && await _shouldShowAdType('interstitial')) {
        futures.add(_loadInterstitialAdInBackground());
      }

      if (_rewardedAd == null && await _shouldShowAdType('rewarded')) {
        futures.add(_loadRewardedAdInBackground());
      }

      if (_appOpenAd == null && await _shouldShowAdType('openapp')) {
        futures.add(_loadAppOpenAdInBackground());
      }

      // Wait for all ads to load
      await Future.wait(futures);
    } finally {
      _isLoadingInBackground = false;
    }
  }

  /// Load interstitial ad in background
  Future<void> _loadInterstitialAdInBackground() async {
    try {
      final completer = Completer<void>();

      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            print('✅ Interstitial ad loaded');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('❌ Interstitial ad failed: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('❌ Error loading interstitial: $e');
    }
  }

  /// Load rewarded ad in background
  Future<void> _loadRewardedAdInBackground() async {
    try {
      final completer = Completer<void>();

      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            print('✅ Rewarded ad loaded');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('❌ Rewarded ad failed: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('❌ Error loading rewarded: $e');
    }
  }

  /// Load app open ad in background
  Future<void> _loadAppOpenAdInBackground() async {
    try {
      final completer = Completer<void>();

      await AppOpenAd.load(
        adUnitId: _openAppAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            print('✅ App open ad loaded');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('❌ App open ad failed: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('❌ Error loading app open: $e');
    }
  }

  /// Create banner ad with error handling
  Future<BannerAd?> createBannerAd() async {
    if (!_isInitialized) await initialize();

    if (!await _shouldShowAdType('banner')) {
      print('⏸️ Banner ads not allowed in current week');
      return null;
    }

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => print('✅ Banner ad loaded'),
          onAdFailedToLoad: (ad, error) {
            print('❌ Banner ad failed: $error');
            ad.dispose();
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      print('❌ Error creating banner: $e');
      return null;
    }
  }

  /// Show interstitial ad with preloading
  Future<bool> showInterstitialAd() async {
    if (!await _shouldShowAdType('interstitial')) {
      print('⏸️ Interstitial ads not allowed');
      return false;
    }

    if (_interstitialAd == null) {
      await _loadInterstitialAdInBackground();
      if (_interstitialAd == null) return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          // Preload next ad
          _loadInterstitialAdInBackground();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial show failed: $error');
          ad.dispose();
          _interstitialAd = null;
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      print('❌ Error showing interstitial: $e');
      return false;
    }
  }

  /// Show rewarded ad with callback
  Future<bool> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    if (!await _shouldShowAdType('rewarded')) {
      print('⏸️ Rewarded ads not allowed');
      return false;
    }

    if (_rewardedAd == null) {
      await _loadRewardedAdInBackground();
      if (_rewardedAd == null) return false;
    }

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          // Preload next ad
          _loadRewardedAdInBackground();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Rewarded show failed: $error');
          ad.dispose();
          _rewardedAd = null;
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      return true;
    } catch (e) {
      print('❌ Error showing rewarded: $e');
      return false;
    }
  }

  /// Show app open ad
  Future<bool> showAppOpenAd() async {
    if (!await _shouldShowAdType('openapp')) {
      print('⏸️ App open ads not allowed');
      return false;
    }

    if (_appOpenAd == null) {
      await _loadAppOpenAdInBackground();
      if (_appOpenAd == null) return false;
    }

    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _appOpenAd = null;
          // Preload next ad
          _loadAppOpenAdInBackground();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ App open show failed: $error');
          ad.dispose();
          _appOpenAd = null;
        },
      );

      await _appOpenAd!.show();
      return true;
    } catch (e) {
      print('❌ Error showing app open: $e');
      return false;
    }
  }

  /// Get current ad status for debugging
  Future<Map<String, dynamic>> getAdStatus() async {
    final currentWeek = await _getCurrentAdWeek();
    return {
      'currentWeek': currentWeek.toString(),
      'interstitialLoaded': _interstitialAd != null,
      'rewardedLoaded': _rewardedAd != null,
      'appOpenLoaded': _appOpenAd != null,
      'backgroundLoading': _isLoadingInBackground,
    };
  }

  // Utility getters
  bool get hasInterstitialAd => _interstitialAd != null;
  bool get hasRewardedAd => _rewardedAd != null;
  bool get hasAppOpenAd => _appOpenAd != null;
  bool get isInitialized => _isInitialized;

  /// Clean up resources
  void dispose() {
    _backgroundLoadTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}
```

---

## 📅 Progressive Ad Rollout Strategy

### The Strategy Explained

Instead of bombarding new users with ads immediately, we use a progressive approach:

#### **Week 1: No Ads (AdWeek.week1)**
- **Goal**: Let users get familiar with the app
- **Ads Shown**: None
- **Benefit**: Reduces immediate uninstalls, builds user engagement

#### **Week 2: Limited Ads (AdWeek.week2)**
- **Goal**: Introduce ads gradually
- **Ads Shown**: Interstitial + Rewarded only
- **Benefit**: Users are invested, less likely to uninstall

#### **Week 3: More Ads (AdWeek.week3)**
- **Goal**: Increase ad exposure
- **Ads Shown**: Interstitial + Rewarded + App Open
- **Benefit**: Higher retention, established user base

#### **Week 4+: Full Monetization (AdWeek.week4Plus)**
- **Goal**: Maximum revenue generation
- **Ads Shown**: All ad types including banners
- **Benefit**: Committed users, optimal revenue

### Testing Different Weeks

```dart
// For testing purposes, you can manually set install date
await PreferenceService.instance.setInstallDate(
  DateTime.now().subtract(Duration(days: 14)) // Test week 3
);
```

---

## 🎨 UI Integration and Widget Implementation

### Smart Banner Widget

**File**: `lib/presentation/widgets/ad_banner_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  final EdgeInsets? margin;

  const AdBannerWidget({Key? key, this.margin}) : super(key: key);

  @override
  _AdBannerWidgetState createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final ValueNotifier<BannerAd?> _bannerAdNotifier = ValueNotifier<BannerAd?>(null);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadAdAsynchronously();
  }

  /// Load ad asynchronously with timeout to prevent blocking
  Future<void> _loadAdAsynchronously() async {
    if (_disposed) return;

    _isLoadingNotifier.value = true;

    try {
      // Load ad with 5-second timeout
      final ad = await Future.any([
        AdService.instance.createBannerAd(),
        Future.delayed(Duration(seconds: 5), () => null),
      ]);

      if (!_disposed && ad != null) {
        _bannerAdNotifier.value = ad;
      }
    } catch (e) {
      print('❌ Error loading banner: $e');
    } finally {
      if (!_disposed) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BannerAd?>(
      valueListenable: _bannerAdNotifier,
      builder: (context, bannerAd, child) {
        if (bannerAd == null) {
          return ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, child) {
              if (isLoading) {
                // Minimal loading indicator
                return Container(
                  margin: widget.margin,
                  height: 50,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              // No ad, return empty space
              return SizedBox.shrink();
            },
          );
        }

        // Ad loaded successfully
        return Container(
          margin: widget.margin,
          height: bannerAd.size.height.toDouble(),
          width: bannerAd.size.width.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _bannerAdNotifier.value?.dispose();
    _bannerAdNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }
}
```

### Usage in Pages

```dart
// Banner ads in home page
Column(
  children: [
    // Content
    Text('Your app content'),
    
    // Banner ad at bottom
    AdBannerWidget(
      margin: EdgeInsets.symmetric(vertical: 16),
    ),
  ],
)

// Interstitial ads after actions
Future<void> _showInterstitialAd() async {
  final success = await AdService.instance.showInterstitialAd();
  if (success) {
    print('✅ Interstitial ad shown');
  }
}

// Rewarded ads for features
Future<void> _showRewardedAdForPremium() async {
  final success = await AdService.instance.showRewardedAd(
    onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      // User earned reward - unlock premium feature
      print('🎉 User earned ${reward.amount} ${reward.type}');
      _unlockPremiumFeature();
    },
  );
  
  if (!success) {
    // Fallback: Show alternative way to unlock
    _showPremiumPurchaseDialog();
  }
}

// App open ads on launch
@override
void initState() {
  super.initState();
  _showAppOpenAd();
}

Future<void> _showAppOpenAd() async {
  await AdService.instance.initialize();
  final success = await AdService.instance.showAppOpenAd();
  if (success) {
    print('✅ App open ad shown');
  }
}
```

---

## 🧪 Testing and Production Deployment

### 1. Test with Test Ad Units

For development, use Google's test ad units:

```dart
// Test ad unit IDs (use during development)
static final String _testBannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/6300978111'  // Android test banner
    : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner

static final String _testInterstitialAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/1033173712'  // Android test interstitial
    : 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
```

### 2. Debug Ad Status

```dart
// Check ad loading status
final adStatus = await AdService.instance.getAdStatus();
print('Ad Status: $adStatus');

// Output example:
// {
//   'currentWeek': 'AdWeek.week2',
//   'interstitialLoaded': true,
//   'rewardedLoaded': false,
//   'appOpenLoaded': true,
//   'backgroundLoading': false,
// }
```

### 3. Testing Checklist

- [ ] Ads load correctly with test IDs
- [ ] Progressive rollout works (change install date for testing)
- [ ] Background loading doesn't block UI
- [ ] Ad disposal works correctly
- [ ] Error handling prevents crashes
- [ ] Ad placement feels natural

### 4. Production Deployment

**Replace test IDs with real IDs:**
```dart
// 🔥 IMPORTANT: Replace before production release
static final String _bannerAdUnitId = Platform.isAndroid
    ? 'ca-app-pub-YOUR_REAL_PUBLISHER_ID/YOUR_REAL_BANNER_ID'
    : 'ca-app-pub-YOUR_REAL_PUBLISHER_ID/YOUR_REAL_IOS_BANNER_ID';
```

**Update AndroidManifest.xml:**
```xml
<!-- Add your real AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_REAL_PUBLISHER_ID~YOUR_REAL_APP_ID"/>
```

---

## 🔧 Troubleshooting and Best Practices

### Common Issues and Solutions

#### Issue 1: Ads Not Showing
**Causes:**
- Wrong ad unit IDs
- Network issues
- AdMob account not approved

**Solutions:**
```dart
// Debug ad loading
Future<void> debugAdLoading() async {
  try {
    await AdService.instance.initialize();
    print('✅ AdMob initialized');
    
    final bannerAd = await AdService.instance.createBannerAd();
    print('Banner ad: ${bannerAd != null ? "✅ Loaded" : "❌ Failed"}');
    
  } catch (e) {
    print('❌ Debug error: $e');
  }
}
```

#### Issue 2: App Crashes
**Cause:** Disposing ads incorrectly
**Solution:**
```dart
@override
void dispose() {
  _bannerAd?.dispose();
  _interstitialAd?.dispose();
  super.dispose();
}
```

### Best Practices

#### Do's ✅
1. **Strategic Timing**: Show ads after user actions, not during
2. **Progressive Rollout**: Give new users time to engage
3. **Value Exchange**: Offer rewards for watching ads
4. **Non-Intrusive**: Don't interrupt critical user flows
5. **Quick Loading**: Use background preloading

#### Don'ts ❌
1. **Don't spam**: Too many ads hurt retention
2. **Don't interrupt**: No ads during important tasks
3. **Don't force**: Always provide alternatives
4. **Don't ignore UX**: User experience comes first
5. **Don't block UI**: Use asynchronous loading

---

## 💡 Quick Start Implementation

### For New Project

1. **Add Dependencies**
```bash
flutter pub add google_mobile_ads shared_preferences get_it
```

2. **Copy Core Files**
- `ad_service.dart`
- `preference_service.dart`
- `ad_banner_widget.dart`

3. **Update IDs**
- Replace test ad unit IDs with your real IDs
- Update AdMob app ID in manifests

4. **Initialize in main.dart**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PreferenceService.instance.init();
  await AdService.instance.initialize();
  
  runApp(MyApp());
}
```

5. **Use in UI**
```dart
// Banner ads
AdBannerWidget()

// Interstitial ads
AdService.instance.showInterstitialAd()

// Rewarded ads
AdService.instance.showRewardedAd(
  onUserEarnedReward: (ad, reward) {
    // Handle reward
  },
)
```

---

**Congratulations! 🎉** You now have a complete, production-ready AdMob integration with advanced features like progressive rollout, background loading, and optimal user experience. This implementation balances revenue generation with user satisfaction for long-term success.

**Happy monetizing! 💰📱** 