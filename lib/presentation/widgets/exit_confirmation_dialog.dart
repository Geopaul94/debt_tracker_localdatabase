import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/premium_service.dart';
import '../../injection/injection_container.dart';
import 'ad_banner_widget.dart';

class ExitConfirmationDialog extends StatefulWidget {
  const ExitConfirmationDialog({super.key});

  @override
  State<ExitConfirmationDialog> createState() => _ExitConfirmationDialogState();
}

class _ExitConfirmationDialogState extends State<ExitConfirmationDialog> {
  bool _isLoadingAd = false;
  bool _hasInternet = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      // Check internet connectivity
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();

      // Check premium status
      bool isPremium = false;
      try {
        final premiumService = serviceLocator<PremiumService>();
        isPremium =
            await premiumService.isPremiumUnlocked() ||
            await premiumService.canSkipAuthentication();
      } catch (e) {
        print('Premium service not available: $e');
      }

      setState(() {
        _hasInternet = hasInternet;
        _isPremium = isPremium;
      });
    } catch (e) {
      print('Error checking status in exit dialog: $e');
      setState(() {
        _hasInternet = false;
        _isPremium = false;
      });
    }
  }

  Future<void> _showInterstitialAd() async {
    if (_isLoadingAd || _isPremium || !_hasInternet) return;

    setState(() => _isLoadingAd = true);

    try {
      await AdService.instance.showInterstitialAd();
    } catch (e) {
      print('Error showing interstitial ad: $e');
    } finally {
      setState(() => _isLoadingAd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 300.w,
        constraints: BoxConstraints(
          maxHeight: _hasInternet && !_isPremium ? 400.h : 250.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.white, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text(
                    'Exit App?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content with optional ad
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you sure you want to exit Debt Tracker?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[700],
                      ),
                    ),

                    // Show ad banner if internet available and not premium
                    if (_hasInternet && !_isPremium) ...[
                      SizedBox(height: 16.h),
                      Container(
                        height: 100.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: AdBannerWidget(),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Support us by viewing ads 😊',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (!_hasInternet) ...[
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Colors.grey[400],
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'No internet connection',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoadingAd
                              ? null
                              : () async {
                                // Show interstitial ad before exit if internet available and not premium
                                if (_hasInternet && !_isPremium) {
                                  await _showInterstitialAd();
                                }
                                if (mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child:
                          _isLoadingAd
                              ? SizedBox(
                                height: 16.h,
                                width: 16.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Exit',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
