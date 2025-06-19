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

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = await AdService.instance.createBannerAd();
      setState(() {
        _isAdLoaded = true;
      });
    } catch (e) {
      print('Error loading banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
