import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;
  AdService._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Production Ad Unit IDs
  static final String _bannerAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/9814827520' // Your Banner Ad ID
          : 'ca-app-pub-5835078496383561/9814827520'; // Your Banner Ad ID

  static final String _interstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/3282058826' // Your Interstitial Ad ID
          : 'ca-app-pub-5835078496383561/3282058826'; // Your Interstitial Ad ID

  static final String _rewardedAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-5835078496383561/644727821' // Your Rewarded Interstitial Ad ID
          : 'ca-app-pub-5835078496383561/644727821'; // Your Rewarded Interstitial Ad ID

  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [
          'ABCDEF012345678901234567890ABCDEF', // Standard Android emulator test device ID
          '33BE2250B43518CCDA7DE426D04EE231', // Alternative emulator test device ID
        ],
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      ),
    );

    _isInitialized = true;
    print('AdMob initialized successfully');
  }

  // Banner Ad Methods
  Future<BannerAd> createBannerAd() async {
    if (!_isInitialized) await initialize();

    _bannerAd = BannerAd(
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

    await _bannerAd!.load();
    return _bannerAd!;
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
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
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
