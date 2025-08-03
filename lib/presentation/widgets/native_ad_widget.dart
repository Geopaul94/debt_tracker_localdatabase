import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/ad_service.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType template;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final String? factoryId;
  final double? height;
  final bool showLabel;

  const NativeAdWidget({
    super.key,
    this.template = TemplateType.medium,
    this.margin,
    this.backgroundColor,
    this.factoryId,
    this.height,
    this.showLabel = true,
  });

  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    if (_disposed) return;

    try {
      final ad = await AdService.instance.createNativeAd(
        factoryId: widget.factoryId ?? 'listTile',
        template: widget.template,
      );

      if (!_disposed && ad != null) {
        _nativeAd = ad;
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      print('Error loading native ad: $e');
    }
  }

  double _getAdHeight() {
    if (widget.height != null) return widget.height!;
    
    switch (widget.template) {
      case TemplateType.small:
        return 90.h;
      case TemplateType.medium:
        return 130.h;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional "Ad" label for transparency
          if (widget.showLabel)
            Padding(
              padding: EdgeInsets.only(left: 8.w, top: 4.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Native ad content
          Container(
            height: _getAdHeight(),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: AdWidget(ad: _nativeAd!),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _nativeAd?.dispose();
    super.dispose();
  }
}