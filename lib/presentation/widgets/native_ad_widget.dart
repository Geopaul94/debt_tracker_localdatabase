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
  bool _isLoading = false;
  bool _disposed = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    if (_disposed || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Add small delay to prevent rapid concurrent requests
      await Future.delayed(const Duration(milliseconds: 100));

      if (_disposed) return;

      // Add timeout for ad loading (10 seconds max)
      final ad = await Future.any([
        AdService.instance.createNativeAd(
          factoryId: widget.factoryId ?? 'listTile',
          template: widget.template,
        ),
        Future.delayed(const Duration(seconds: 10), () => null),
      ]);

      if (!_disposed && mounted) {
        if (ad != null) {
          _nativeAd = ad;
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
          print('✅ Native ad loaded and ready to display');
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          print('❌ Native ad failed to load or timed out');
        }
      } else {
        // Widget was disposed while loading, dispose the ad
        ad?.dispose();
      }
    } catch (e) {
      print('Error loading native ad: $e');
      if (!_disposed && mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
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
    // Don't show anything if loading, error, or not loaded
    if (_isLoading || _hasError || !_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    // Double-check the ad is still valid before rendering
    if (_disposed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          widget.margin ??
          EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
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

          // Native ad content with error handling
          Container(
            height: _getAdHeight(),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: _buildAdContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdContent() {
    try {
      if (_nativeAd != null && !_disposed) {
        return AdWidget(ad: _nativeAd!);
      }
    } catch (e) {
      print('Error rendering native ad widget: $e');
      // Set error state when rendering fails and trigger rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) {
          setState(() {
            _hasError = true;
          });
        }
      });
    }
    // This should never be reached now since we handle errors above
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_nativeAd != null) {
      _nativeAd!.dispose();
      // Notify AdService that this native ad is disposed
      AdService.instance.onNativeAdDisposed();
    }
    super.dispose();
  }
}
