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

    _isLoadingNotifier.value = true;

    try {
      // Load ad in background with timeout
      final ad = await Future.any([
        AdService.instance.createBannerAd(),
        Future.delayed(Duration(seconds: 5), () => null), // 5 second timeout
      ]);

      if (!_disposed && ad != null) {
        _bannerAdNotifier.value = ad;
      }
    } catch (e) {
      print('Error loading banner ad: $e');
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
                // Show minimal loading indicator or empty space
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
              // Return empty space if no ad and not loading
              return SizedBox.shrink();
            },
          );
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
