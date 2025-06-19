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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      final bannerAd = await AdService.instance.createBannerAd();
      if (mounted) {
        setState(() {
          _bannerAd = bannerAd;
          _isAdLoaded = true;
          _isLoading = false;
        });
      } else {
        // Widget was disposed while loading, dispose the ad
        bannerAd.dispose();
      }
    } catch (e) {
      print('Error loading banner ad: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: widget.margin ?? EdgeInsets.symmetric(vertical: 8.0),
        height: 50, // Standard banner height
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox.shrink(); // Return empty widget if ad not loaded
    }

    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
    );
  }
}
