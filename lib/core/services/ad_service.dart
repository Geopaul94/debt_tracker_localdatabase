import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'preference_service.dart';
import 'connectivity_service.dart';
import 'premium_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  // Background loading timers
  Timer? _backgroundLoadTimer;
  bool _isLoadingInBackground = false;

  // Native ad management
  int _activeNativeAds = 0;
  static const int _maxConcurrentNativeAds = 3; // Limit concurrent native ads

  // Ad Unit IDs - Use test ads for development, production ads for release
  static final String _bannerAdUnitId =
      Platform.isAndroid
          ? (kDebugMode
              ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner
              : 'ca-app-pub-5835078496383561/4425152477') // Production banner ad
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS test ad

  static final String _interstitialAdUnitId =
      Platform.isAndroid
          ? (kDebugMode
              ? 'ca-app-pub-3940256099942544/1033173712' // Android test interstitial
              : 'ca-app-pub-5835078496383561/3282058826') // Production interstitial ad
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test ad

  static final String _openAppAdUnitId =
      Platform.isAndroid
          ? (kDebugMode
              ? 'ca-app-pub-3940256099942544/3419835294' // Android test app open
              : 'ca-app-pub-5835078496383561/5891428769') // Production app open ad
          : 'ca-app-pub-5835078496383561/3262990911'; // iOS test ad

  static final String _rewardedAdUnitId =
      Platform.isAndroid
          ? (kDebugMode
              ? 'ca-app-pub-3940256099942544/5224354917' // Android test rewarded
              : 'ca-app-pub-5835078496383561/2160067314') // Production rewarded ad
          : 'ca-app-pub-3940256099942544/1712485313'; // iOS test ad

  static final String _nativeAdUnitId =
      Platform.isAndroid
          ? (kDebugMode
              ? 'ca-app-pub-3940256099942544/2247696110' // Android test native
              : 'ca-app-pub-5835078496383561/2074524567') // NEW native ad unit
          : 'ca-app-pub-3940256099942544/3986624511'; // iOS test ad

  // Initialize ads asynchronously
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [],
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        ),
      );

      _isInitialized = true;
      print('AdMob initialized successfully');

      // Start background ad loading after initialization
      _startBackgroundLoading();
    } catch (e) {
      print('AdMob initialization failed: $e');
    }
  }

  // Check if specific ad type should be shown
  Future<bool> _shouldShowAdType(String adType) async {
    print('🔍 Checking if should show ad type: $adType');

    // First check if user has ad-free access from rewarded ads or premium
    try {
      final isPremium = await PremiumService.instance.isPremiumUnlocked();
      final isAdFree = await PremiumService.instance.isAdFree();

      print('💰 Premium status: $isPremium');
      print('🚫 Ad-free status: $isAdFree');

      // Premium users or users with ad-free access should not see ads
      if (isPremium || isAdFree) {
        print('❌ User has premium or ad-free access - not showing ads');
        return false;
      }
    } catch (e) {
      print('Error checking premium/ad-free status: $e');
      // Continue with normal ad logic if premium service fails
    }

    // Check if ads are enabled in preferences
    final shouldShowAds = await PreferenceService.instance.shouldShowAds();
    if (!shouldShowAds) {
      print('❌ Ads disabled in preferences');
      return false;
    }

    // Check internet connection
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      print('❌ No internet connection - not showing ads');
      return false;
    }

    // All conditions met - show ads normally
    print('✅ All conditions met - showing ads normally');
    return true;
  }

  // Check if internet connection is available for ads
  Future<bool> _hasInternetConnection() async {
    try {
      return await ConnectivityService.instance.checkInternetConnection();
    } catch (e) {
      print('Error checking connectivity for ads: $e');
      return false; // Default to no ads if connectivity check fails
    }
  }

  // Background ad loading to reduce main thread load
  void _startBackgroundLoading() {
    _backgroundLoadTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isLoadingInBackground) {
        _loadAdsInBackground();
      }
    });
  }

  Future<void> _loadAdsInBackground() async {
    if (_isLoadingInBackground || !_isInitialized) return;
    _isLoadingInBackground = true;

    try {
      // Load ads concurrently in background
      final futures = <Future>[];

      if (_interstitialAd == null && await _shouldShowAdType('interstitial')) {
        futures.add(_loadInterstitialAdInBackground());
      }

      if (_rewardedAd == null && await _shouldShowAdType('rewarded')) {
        futures.add(_loadRewardedAdInBackground());
      }

      if (_appOpenAd == null && await _shouldShowAdType('openapp')) {
        futures.add(_loadAppOpenAdInBackground());
      }

      // Wait for all ads to load concurrently
      await Future.wait(futures);
    } finally {
      _isLoadingInBackground = false;
    }
  }

  Future<void> _loadInterstitialAdInBackground() async {
    try {
      final completer = Completer<void>();

      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            print('Interstitial ad loaded in background');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('Background interstitial ad failed to load: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('Error loading interstitial ad in background: $e');
    }
  }

  Future<void> _loadRewardedAdInBackground() async {
    try {
      final completer = Completer<void>();

      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            print('Rewarded ad loaded in background');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('Background rewarded ad failed to load: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('Error loading rewarded ad in background: $e');
    }
  }

  Future<void> _loadAppOpenAdInBackground() async {
    try {
      final completer = Completer<void>();

      await AppOpenAd.load(
        adUnitId: _openAppAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            print('App open ad loaded in background');
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            print('Background app open ad failed to load: $error');
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      print('Error loading app open ad in background: $e');
    }
  }

  // Optimized banner ad creation
  Future<BannerAd?> createBannerAd() async {
    if (!_isInitialized) await initialize();

    // Check if ads should be shown
    if (!await _shouldShowAdType('banner')) {
      print('Banner ads not allowed');
      return null;
    }

    try {
      final bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => print('Banner ad loaded'),
          onAdFailedToLoad: (ad, error) {
            print('Banner ad failed to load: $error');
            ad.dispose();
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      print('Error creating banner ad: $e');
      return null;
    }
  }

  // Show interstitial ad with background preloading
  Future<bool> showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!await _shouldShowAdType('interstitial')) {
      print('Interstitial ads not allowed');
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
          // Preload next ad in background
          _loadInterstitialAdInBackground();
          // Call the callback if provided
          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          // Call the callback if provided
          if (onAdFailedToShow != null) {
            onAdFailedToShow();
          }
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  // Show rewarded ad with background preloading
  Future<bool> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
    bool allowDuringAdFree =
        false, // Allow rewarded ads even during ad-free periods
  }) async {
    // For rewarded ads that extend ad-free time, bypass premium/ad-free checks
    if (!allowDuringAdFree && !await _shouldShowAdType('rewarded')) {
      print('Rewarded ads not allowed');
      return false;
    } else if (allowDuringAdFree) {
      // Still check internet connection for rewarded ads during ad-free periods
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        print('❌ No internet connection - not showing rewarded ads');
        return false;
      }
      print('✅ Showing rewarded ad during ad-free period to extend time');
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
          // Preload next ad in background
          _loadRewardedAdInBackground();
          // Call the callback if provided
          if (onAdDismissed != null) {
            onAdDismissed();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          // Call the callback if provided
          if (onAdFailedToShow != null) {
            onAdFailedToShow();
          }
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  // Show app open ad
  Future<bool> showAppOpenAd() async {
    if (!await _shouldShowAdType('openapp')) {
      print('App open ads not allowed');
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
          // Preload next ad in background
          _loadAppOpenAdInBackground();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('App open ad failed to show: $error');
          ad.dispose();
          _appOpenAd = null;
        },
      );

      await _appOpenAd!.show();
      return true;
    } catch (e) {
      print('Error showing app open ad: $e');
      return false;
    }
  }

  // Get current ad status info for debugging
  Future<Map<String, dynamic>> getAdStatus() async {
    return {
      'interstitialLoaded': _interstitialAd != null,
      'rewardedLoaded': _rewardedAd != null,
      'appOpenLoaded': _appOpenAd != null,
      'backgroundLoading': _isLoadingInBackground,
      'hasInternet': await _hasInternetConnection(),
    };
  }

  // Create native ad with retry logic
  Future<NativeAd?> createNativeAd({
    String? factoryId, // Make nullable to use built-in templates
    TemplateType template = TemplateType.medium,
    int maxRetries = 2,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Limit concurrent native ads to prevent memory issues
      if (_activeNativeAds >= _maxConcurrentNativeAds) {
        print(
          '⚠️ Max concurrent native ads reached ($_activeNativeAds/$_maxConcurrentNativeAds)',
        );
        return null;
      }

      // Check if ads should be shown
      if (!await _shouldShowAdType('native')) {
        print('Native ads not allowed');
        return null;
      }

      // Add delay to prevent rapid requests and reduce load
      await Future.delayed(const Duration(milliseconds: 200));

      // Double-check internet connection
      if (!await _hasInternetConnection()) {
        print('No internet connection for native ad');
        return null;
      }

      // Increment active counter
      _activeNativeAds++;
      print(
        '📈 Creating native ad (Active: $_activeNativeAds/$_maxConcurrentNativeAds)',
      );
      return await _createNativeAdWithRetry(
        factoryId: factoryId,
        template: template,
        maxRetries: maxRetries,
        currentAttempt: 0,
      );
    } catch (e) {
      // Decrement counter if we incremented it earlier
      if (_activeNativeAds > 0) {
        _activeNativeAds--;
        print(
          '📉 Native ad creation failed, decremented counter (Active: $_activeNativeAds)',
        );
      }

      print('❌ Error creating native ad: $e');
      if (e.toString().contains('JavascriptEngine')) {
        print('💡 Tip: Update Android System WebView in Play Store');
      } else if (e.toString().contains('INTERNAL_ERROR')) {
        print('💡 AdMob internal error - try again later');
      } else if (e.toString().contains('NETWORK_ERROR')) {
        print('💡 Network error - check internet connection');
      }
      return null;
    }
  }

  // Helper method for native ad creation with retry logic
  Future<NativeAd?> _createNativeAdWithRetry({
    String? factoryId,
    TemplateType template = TemplateType.medium,
    required int maxRetries,
    required int currentAttempt,
  }) async {
    final completer = Completer<NativeAd?>();

    final nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: factoryId, // Will be null for built-in templates
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('✅ Native ad loaded successfully (Active: $_activeNativeAds)');
          if (!completer.isCompleted) {
            completer.complete(ad as NativeAd);
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Native ad failed to load: $error');

          // Decrement counter for failed ad
          if (_activeNativeAds > 0) {
            _activeNativeAds--;
            print(
              '📉 Native ad failed, decremented counter (Active: $_activeNativeAds)',
            );
          }

          // Always dispose failed ads to prevent memory leaks
          try {
            ad.dispose();
          } catch (e) {
            print('Error disposing failed native ad: $e');
          }

          // Handle specific error types and retry logic
          bool shouldRetry = false;

          if (error.message.contains('JavascriptEngine')) {
            print(
              '⚠️ WebView JavascriptEngine issue - device compatibility problem',
            );
          } else if (error.message.contains('disposed')) {
            print('⚠️ Ad was disposed before loading completed');
          } else if (error.code == 0) {
            print('⚠️ Internal error - AdMob issue');
            shouldRetry = true; // Retry internal errors
          } else if (error.code == 1) {
            print('⚠️ Invalid request - check ad unit ID');
          } else if (error.code == 2) {
            print('⚠️ Network error - check internet connection');
            shouldRetry = true; // Retry network errors
          } else if (error.code == 3) {
            print('⚠️ No fill - no native ads available for this request');
            print('💡 This usually means:');
            print('   - New ad unit needs up to 1 hour to activate');
            print('   - Ad unit needs approval in AdMob console');
            print('   - No advertisers targeting your region yet');
            print('   - Ad unit ID: $_nativeAdUnitId');
          } else {
            print('⚠️ Unknown error code: ${error.code}');
          }

          // Retry logic for retryable errors
          if (shouldRetry && currentAttempt < maxRetries) {
            print(
              '🔄 Retrying native ad creation (attempt ${currentAttempt + 1}/$maxRetries)',
            );

            // Increment counter again for retry
            _activeNativeAds++;

            // Wait before retry with exponential backoff
            final delayMs = 1000 * (currentAttempt + 1);
            Future.delayed(Duration(milliseconds: delayMs), () async {
              try {
                final retryAd = await _createNativeAdWithRetry(
                  factoryId: factoryId,
                  template: template,
                  maxRetries: maxRetries,
                  currentAttempt: currentAttempt + 1,
                );
                if (!completer.isCompleted) {
                  completer.complete(retryAd);
                }
              } catch (e) {
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              }
            });
          } else {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
        onAdClicked: (ad) => print('👆 Native ad clicked'),
        onAdImpression: (ad) => print('👁️ Native ad impression'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: template,
        mainBackgroundColor: Colors.white,
        cornerRadius: 8.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF2196F3),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF212121),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF757575),
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF757575),
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );

    try {
      // Load the ad with timeout
      await nativeAd.load();
      print('🎯 Native ad load initiated successfully');

      // Return the completer future, which will resolve when ad loads or fails
      return await completer.future;
    } catch (e) {
      // Decrement counter for loading error
      if (_activeNativeAds > 0) {
        _activeNativeAds--;
      }

      // Dispose the ad on load error
      try {
        nativeAd.dispose();
      } catch (disposeError) {
        print('Error disposing native ad after load error: $disposeError');
      }

      print('❌ Error loading native ad: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    }
  }

  // Method to call when native ad is disposed
  void onNativeAdDisposed() {
    if (_activeNativeAds > 0) {
      _activeNativeAds--;
      print('📉 Native ad disposed (Active: $_activeNativeAds)');
    }
  }

  // Get native ad unit ID
  String get nativeAdUnitId => _nativeAdUnitId;

  // Utility methods
  bool get hasInterstitialAd => _interstitialAd != null;
  bool get hasRewardedAd => _rewardedAd != null;
  bool get hasAppOpenAd => _appOpenAd != null;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _backgroundLoadTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}
