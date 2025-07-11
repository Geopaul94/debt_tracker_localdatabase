import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'preference_service.dart';

enum AdWeek {
  week1, // No ads
  week2, // Interstitial and rewarded only
  week3, // Add open app ads
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

  // Background loading timers
  Timer? _backgroundLoadTimer;
  bool _isLoadingInBackground = false;

  // Ad Unit IDs
  static final String _bannerAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/9814827520'
          : 'ca-app-pub-3940256099942544/2934735716';

  static final String _interstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/3282058826'
          : 'ca-app-pub-3940256099942544/4411468910';

  static final String _openAppAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561~1877477818'
          : 'ca-app-pub-5835078496383561/3262990911';

  static final String _rewardedAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/6447278212'
          : 'ca-app-pub-3940256099942544/1712485313';

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

  // Determine current ad week based on install date
  Future<AdWeek> _getCurrentAdWeek() async {
    final installDate = await PreferenceService.instance.getInstallDate();
    if (installDate == null) return AdWeek.week4Plus;

    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    final weeksSinceInstall = (daysSinceInstall / 7).floor();

    if (weeksSinceInstall == 0) return AdWeek.week4Plus;
    if (weeksSinceInstall == 1) return AdWeek.week4Plus;
    if (weeksSinceInstall == 2) return AdWeek.week4Plus;
    return AdWeek.week4Plus;
  }

  // Check if specific ad type should be shown
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

  // Background ad loading to reduce main thread load
  void _startBackgroundLoading() {
    _backgroundLoadTimer = Timer.periodic(Duration(minutes: 2), (timer) {
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

    if (!await _shouldShowAdType('banner')) {
      print('Banner ads not allowed in current week');
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
  Future<bool> showInterstitialAd() async {
    if (!await _shouldShowAdType('interstitial')) {
      print('Interstitial ads not allowed in current week');
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
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
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
  }) async {
    if (!await _shouldShowAdType('rewarded')) {
      print('Rewarded ads not allowed in current week');
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
          // Preload next ad in background
          _loadRewardedAdInBackground();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
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
      print('App open ads not allowed in current week');
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

  // Get current ad strategy info for debugging
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
