import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../injection/injection_container.dart';

class AdBannerWidget extends StatefulWidget {
  final EdgeInsets? margin;

  const AdBannerWidget({super.key, this.margin});

  @override
  _AdBannerWidgetState createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  // Use ValueNotifier to reduce setState calls
  final ValueNotifier<BannerAd?> _bannerAdNotifier = ValueNotifier<BannerAd?>(
    null,
  );
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadAdAsynchronously();
  }

  // Load ad asynchronously to avoid blocking main thread
  Future<void> _loadAdAsynchronously() async {
    if (_disposed) return;

    try {
      // Check internet connection first
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();

      if (!hasInternet) {
        // No internet - don't show loading, just return
        if (kDebugMode) {
          print('No internet connection - skipping banner ad loading');
        }
        return;
      }

      _isLoadingNotifier.value = true;

      // Load ad in background with timeout
      final ad = await Future.any([
        AdService.instance.createBannerAd(),
        Future.delayed(
          const Duration(seconds: 5),
          () => null,
        ), // 5 second timeout
      ]);

      if (!_disposed && ad != null) {
        _bannerAdNotifier.value = ad;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading banner ad: $e');
      }
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
        // If no ad is available (loading, failed to load, or no internet),
        // don't show anything - let the user use the app normally
        if (bannerAd == null) {
          return const SizedBox.shrink();
        }

        // Ad is loaded, display it
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
