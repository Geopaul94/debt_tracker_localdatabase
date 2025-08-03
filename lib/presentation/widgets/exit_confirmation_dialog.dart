import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  bool _isLoadingRewardedAd = false;
  bool _hasInternet = false;
  bool _isPremium = false;
  bool _shouldExitAfterAd = false;

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
      try {
        final premiumService = serviceLocator<PremiumService>();
        final isPremium = await premiumService.isPremiumUnlocked();

        if (mounted) {
          setState(() {
            _hasInternet = hasInternet;
            _isPremium = isPremium;
          });
        }
      } catch (e) {
        print('Error checking premium status: $e');
        if (mounted) {
          setState(() {
            _hasInternet = hasInternet;
            _isPremium = false;
          });
        }
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _isPremium = false;
        });
      }
    }
  }

  Future<void> _showInterstitialAd() async {
    if (_isLoadingAd || !_hasInternet) return;

    setState(() => _isLoadingAd = true);

    try {
      await AdService.instance.showInterstitialAd(
        onAdDismissed: () {
          print('Interstitial ad dismissed - exiting app');
          _shouldExitAfterAd = true;
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
        onAdFailedToShow: () {
          print('Interstitial ad failed to show - exiting app');
          _shouldExitAfterAd = true;
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
      );
    } catch (e) {
      print('Error showing interstitial ad: $e');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAd = false);
      }
    }
  }

  Future<void> _showRewardedAd() async {
    if (_isLoadingRewardedAd || !_hasInternet) return;

    setState(() => _isLoadingRewardedAd = true);

    try {
      await AdService.instance.showRewardedAd(
        allowDuringAdFree:
            true, // Allow extending ad-free time even during ad-free periods
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          print('User earned reward: ${reward.amount} ${reward.type}');

          // Actually set the ad-free status for 2 hours
          try {
            await serviceLocator<PremiumService>().setAdFreeFor2Hours();
            print('✅ Ad-free status set for 2 hours');
          } catch (e) {
            print('❌ Error setting ad-free status: $e');
          }
        },
        onAdDismissed: () {
          print('Rewarded ad dismissed - exiting app');
          _shouldExitAfterAd = true;
          if (mounted) {
            // Show thank you message briefly then exit the app
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🚀 Thank you! 2 hours ad-free access granted! Exiting app...',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );

            // Exit the app after a small delay
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
        onAdFailedToShow: () {
          print('Rewarded ad failed to show - exiting app');
          _shouldExitAfterAd = true;
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not available right now. Exiting app...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        // Exit the app even if ad fails
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRewardedAd = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 300.w,
        constraints: BoxConstraints(maxHeight: _hasInternet ? 520.h : 250.h),
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
            Flexible(
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

                    // Show ad banner if internet available (allow ads even during ad-free period for rewarded ads)
                    if (_hasInternet) ...[
                      SizedBox(height: 16.h),
                      Container(
                        height: 100.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const AdBannerWidget(),
                      ),
                      SizedBox(height: 2.h),
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
              child: Column(
                children: [
                  // Cancel and Exit buttons row
                  Row(
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
                                    // Show interstitial ad before exit if internet available
                                    if (_hasInternet) {
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
                                    child: const CircularProgressIndicator(
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

                  // Support button (only show if internet available)
                  if (_hasInternet) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingRewardedAd ? null : _showRewardedAd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon:
                            _isLoadingRewardedAd
                                ? SizedBox(
                                  height: 16.h,
                                  width: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Icon(Icons.play_circle_outline, size: 20.sp),
                        label: Text(
                          _isLoadingRewardedAd
                              ? 'Loading...'
                              : 'Watch ad & exit app',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
