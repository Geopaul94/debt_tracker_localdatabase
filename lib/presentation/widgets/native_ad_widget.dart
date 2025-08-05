import 'package:flutter/foundation.dart';
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
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _disposed = false;
  bool _hasError = false;
  bool _isUsingBannerFallback = false;

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
      _isUsingBannerFallback = false;
    });

    try {
      // Add small delay to prevent rapid concurrent requests
      await Future.delayed(const Duration(milliseconds: 100));

      if (_disposed) return;

      print('🎯 Attempting to load native ad...');

      // Add timeout for ad loading (15 seconds max to account for retries)
      final ad = await Future.any([
        AdService.instance.createNativeAd(
          factoryId: widget.factoryId, // Use null for default template
          template: widget.template,
          maxRetries: 2, // Allow 2 retries for native ads
        ),
        Future.delayed(const Duration(seconds: 15), () => null),
      ]);

      if (!_disposed && mounted) {
        if (ad != null) {
          _nativeAd = ad;

          // Wait for ad to be fully initialized before marking as loaded
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_disposed && _nativeAd == ad && _nativeAd != null) {
              setState(() {
                _isLoaded = true;
                _isLoading = false;
              });
              print(
                '✅ Native ad loaded and ready to display (ID: ${ad.hashCode})',
              );
            } else {
              print(
                '⚠️ Native ad state changed during loading, not marking as loaded',
              );
              // Dispose the ad if state changed
              try {
                ad.dispose();
              } catch (e) {
                print('Error disposing orphaned ad: $e');
              }
            }
          });
        } else {
          // Native ad failed, try banner ad as fallback
          print('🔄 Native ad failed, attempting banner ad fallback...');
          await _loadBannerAdFallback();
        }
      } else {
        // Widget was disposed while loading, dispose the ad
        ad?.dispose();
        print('Widget disposed during loading, cleaned up ad');
      }
    } catch (e) {
      print('Error loading native ad: $e');
      if (!_disposed && mounted) {
        // Try banner ad fallback on error
        print('🔄 Native ad error, attempting banner ad fallback...');
        await _loadBannerAdFallback();
      }
    }
  }

  Future<void> _loadBannerAdFallback() async {
    if (_disposed) return;

    try {
      print('📱 Loading banner ad as fallback for native ad...');

      final bannerAd = await AdService.instance.createBannerAd();

      if (!_disposed && mounted) {
        if (bannerAd != null) {
          _bannerAd = bannerAd;
          setState(() {
            _isLoaded = true;
            _isLoading = false;
            _isUsingBannerFallback = true;
          });
          print('✅ Banner ad fallback loaded successfully');
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          print('❌ Banner ad fallback also failed to load');
        }
      } else {
        // Widget was disposed while loading banner fallback
        bannerAd?.dispose();
        print('Widget disposed during banner fallback loading, cleaned up ad');
      }
    } catch (e) {
      print('Error loading banner ad fallback: $e');
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
    // Show debug info in debug mode
    if (kDebugMode) {
      print(
        'Native Ad Widget State: loading=$_isLoading, error=$_hasError, loaded=$_isLoaded, disposed=$_disposed, native=${_nativeAd != null}, banner=${_bannerAd != null}, fallback=$_isUsingBannerFallback',
      );
    }

    // Handle different states with better debugging
    if (_isLoading) {
      // Show loading indicator only in debug mode
      return kDebugMode
          ? Container(
            height: 80,
            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'Loading native ad...',
                style: TextStyle(fontSize: 12),
              ),
            ),
          )
          : const SizedBox.shrink();
    }

    if (_hasError || !_isLoaded || (_nativeAd == null && _bannerAd == null)) {
      // Show error info only in debug mode, hide in production
      return kDebugMode
          ? Container(
            height: 80,
            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Center(
              child: Text(
                _hasError ? 'All ads failed to load' : 'No ads loaded',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          )
          : const SizedBox.shrink();
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
                  _isUsingBannerFallback ? 'Ad' : 'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Native ad content with error handling
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: _buildAdContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdContent() {
    // Check if we're using banner fallback
    if (_isUsingBannerFallback) {
      return _buildBannerAdContent();
    } else {
      return _buildNativeAdContent();
    }
  }

  Widget _buildNativeAdContent() {
    // Triple check ad state and validity
    if (_nativeAd == null || _disposed || !_isLoaded) {
      return const SizedBox.shrink();
    }

    // Create a persistent reference to prevent disposal during build
    final currentAd = _nativeAd;
    if (currentAd == null) {
      return const SizedBox.shrink();
    }

    try {
      // Use a more robust approach without FutureBuilder to avoid timing issues
      return Container(
        width: double.infinity,
        height: _getAdHeight(),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Final validation before creating AdWidget
            if (_disposed || currentAd != _nativeAd || _nativeAd == null) {
              return const SizedBox.shrink();
            }

            // Wrap in a safety container to catch any rendering issues
            return Container(
              key: ValueKey('native_ad_${currentAd.hashCode}'),
              child: AdWidget(ad: currentAd),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Error rendering native ad widget: $e');
      print(
        '   Widget state: loaded=$_isLoaded, disposed=$_disposed, ad=${_nativeAd != null}',
      );
      print('   Error type: ${e.runtimeType}');

      // Mark as error to prevent further attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) {
          setState(() {
            _hasError = true;
            _isLoaded = false;
          });
        }
      });

      // In production, just hide the ad instead of showing error
      if (!kDebugMode) {
        return const SizedBox.shrink();
      }

      // Show error info only in debug mode
      return Container(
        width: double.infinity,
        height: _getAdHeight(),
        color: Colors.red[100],
        child: Center(
          child: Text(
            'Debug: Native Ad Error\n$e\nAd ID issue - probably disposed',
            style: TextStyle(fontSize: 8.sp, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildBannerAdContent() {
    // Check banner ad state and validity
    if (_bannerAd == null || _disposed || !_isLoaded) {
      return const SizedBox.shrink();
    }

    // Create a persistent reference to prevent disposal during build
    final currentBannerAd = _bannerAd;
    if (currentBannerAd == null) {
      return const SizedBox.shrink();
    }

    try {
      // Banner ads have a fixed height, so we'll use that instead of _getAdHeight()
      return Container(
        width: double.infinity,
        height: 50.h, // Standard banner height
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Final validation before creating AdWidget
            if (_disposed ||
                currentBannerAd != _bannerAd ||
                _bannerAd == null) {
              return const SizedBox.shrink();
            }

            // Wrap in a safety container to catch any rendering issues
            return Container(
              key: ValueKey('banner_ad_${currentBannerAd.hashCode}'),
              child: AdWidget(ad: currentBannerAd),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Error rendering banner ad widget: $e');
      print(
        '   Widget state: loaded=$_isLoaded, disposed=$_disposed, bannerAd=${_bannerAd != null}',
      );
      print('   Error type: ${e.runtimeType}');

      // Mark as error to prevent further attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) {
          setState(() {
            _hasError = true;
            _isLoaded = false;
          });
        }
      });

      // In production, just hide the ad instead of showing error
      if (!kDebugMode) {
        return const SizedBox.shrink();
      }

      // Show error info only in debug mode
      return Container(
        width: double.infinity,
        height: 50.h,
        color: Colors.red[100],
        child: Center(
          child: Text(
            'Debug: Banner Ad Error\n$e\nAd ID issue - probably disposed',
            style: TextStyle(fontSize: 8.sp, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;

    // Clean up native ad reference safely
    final nativeAdToDispose = _nativeAd;
    _nativeAd = null;

    if (nativeAdToDispose != null) {
      try {
        print('🗑️ Disposing native ad (ID: ${nativeAdToDispose.hashCode})');
        nativeAdToDispose.dispose();
        // Notify AdService that this native ad is disposed
        AdService.instance.onNativeAdDisposed();
      } catch (e) {
        print('Error disposing native ad: $e');
      }
    }

    // Clean up banner ad reference safely
    final bannerAdToDispose = _bannerAd;
    _bannerAd = null;

    if (bannerAdToDispose != null) {
      try {
        print(
          '🗑️ Disposing banner ad fallback (ID: ${bannerAdToDispose.hashCode})',
        );
        bannerAdToDispose.dispose();
      } catch (e) {
        print('Error disposing banner ad: $e');
      }
    }

    super.dispose();
  }
}
