import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'preference_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Use Test Ad Unit IDs for debugging - replace with real ones for production
  static final String _bannerAdUnitId =
      Platform.isAndroid
          //   ? 'ca-app-pub-3940256099942544/6300978111' // Test Banner Ad ID
          ? 'ca-app-pub-5835078496383561/9814827520'
          : 'ca-app-pub-3940256099942544/2934735716'; // Test Banner Ad ID (iOS)

  static final String _interstitialAdUnitId =
      Platform.isAndroid
          //   ? 'ca-app-pub-3940256099942544/1033173712' // Test Interstitial Ad ID
          ? 'ca-app-pub-5835078496383561/3282058826'
          : 'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial Ad ID (iOS)

  static final String _rewardedAdUnitId =
      Platform.isAndroid
          //  ? 'ca-app-pub-3940256099942544/5224354917' // Test Rewarded Ad ID
          ? 'ca-app-pub-5835078496383561/6447278212'
          : 'ca-app-pub-3940256099942544/1712485313'; // Test Rewarded Ad ID (iOS)

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds:
              [], // Empty to use test ads on all devices during development
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        ),
      );

      _isInitialized = true;
      print('AdMob initialized successfully');
    } catch (e) {
      print('AdMob initialization failed: $e');
    }
  }

  // Banner Ad Methods - Create unique instances for each widget
  Future<BannerAd?> createBannerAd() async {
    if (!_isInitialized) await initialize();

    // Check if ads should be shown (after 7 days)
    final shouldShowAds = await PreferenceService.instance.shouldShowAds();
    if (!shouldShowAds) {
      print('Ads not shown - within 7 day grace period');
      return null;
    }

    // Create a new BannerAd instance each time - don't reuse _bannerAd
    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );

    await bannerAd.load();
    return bannerAd;
  }

  // Interstitial Ad Methods
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) await initialize();

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showInterstitialAd() async {
    // Check if ads should be shown (after 7 days)
    final shouldShowAds = await PreferenceService.instance.shouldShowAds();
    if (!shouldShowAds) {
      print('Interstitial ad not shown - within 7 day grace period');
      return false;
    }

    if (_interstitialAd == null) {
      await loadInterstitialAd();
      // Wait a bit for the ad to load
      await Future.delayed(Duration(seconds: 1));
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          // Preload the next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
        },
      );

      await _interstitialAd!.show();
      return true;
    }
    return false;
  }

  // Rewarded Ad Methods
  Future<void> loadRewardedAd() async {
    if (!_isInitialized) await initialize();

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      await loadRewardedAd();
      await Future.delayed(Duration(seconds: 1));
    }

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Rewarded ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      return true;
    }
    return false;
  }

  // Utility Methods
  bool get hasInterstitialAd => _interstitialAd != null;
  bool get hasRewardedAd => _rewardedAd != null;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
