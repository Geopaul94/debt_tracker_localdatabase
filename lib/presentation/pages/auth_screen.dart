import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../injection/injection_container.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/premium_service.dart';
import '../bloc/authentication/auth_bloc.dart';
import '../bloc/authentication/auth_event.dart';
import '../bloc/authentication/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoadingAd = false;

  // Helper method to safely check if PremiumService is available
  bool _isPremiumServiceAvailable() {
    try {
      serviceLocator<PremiumService>();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<AuthBloc>(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal[400]!, Colors.teal[600]!],
            ),
          ),
          child: SafeArea(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthSuccess) {
                  Navigator.of(context).pushReplacementNamed('/home');
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            AuthenticateEvent(
                              reason:
                                  'Please authenticate to access your debt tracker',
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 40.h), // Top spacing
                    // App Logo/Icon
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 4,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 60.sp,
                        color: Colors.teal[600],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // App Title
                    Text(
                      'Debt Tracker',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Subtitle
                    Text(
                      'Secure Access Required',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 60.h),

                    // Authentication Icon
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        size: 40.sp,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Authentication Message
                    Text(
                      'Please authenticate to access\nyour financial data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 48.h),

                    // Authenticate Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed:
                                state is AuthLoading
                                    ? null
                                    : () {
                                      context.read<AuthBloc>().add(
                                        AuthenticateEvent(
                                          reason:
                                              'Please authenticate to access your debt tracker',
                                        ),
                                      );
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 4,
                            ),
                            child:
                                state is AuthLoading
                                    ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.teal[600]!,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_open, size: 24.sp),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'Authenticate',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Help Text
                    Text(
                      'Use Face ID, Touch ID, or device PIN\nto unlock the app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 60.h),

                    // Alternative Option - Watch Ad for 2 Hours Access
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alternative Access',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Watch a short ad to use the app\nwithout authentication for 2 hours',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.8),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoadingAd ? null : _watchAdFor2Hours,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 2,
                              ),
                              child:
                                  _isLoadingAd
                                      ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.video_library,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Watch Ad for 2 Hours Access',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h), // Bottom spacing
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _watchAdFor2Hours() async {
    setState(() {
      _isLoadingAd = true;
    });

    try {
      final success = await AdService.instance.showRewardedAd(
        onUserEarnedReward: (ad, reward) async {
          if (mounted) {
            if (_isPremiumServiceAvailable()) {
              try {
                // Grant 2 hours of ad-free access
                await serviceLocator<PremiumService>().setAdFreeFor2Hours();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚀 Ad-free access granted for 2 hours!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                print('Error setting ad-free status: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🚀 Ad reward received! You can now access the app.',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🚀 Ad reward received! You can now access the app.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }

            // Navigate to home after successful ad watch
            await Future.delayed(Duration(seconds: 1));
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        },
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad not ready. Please try again in a moment.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error showing rewarded ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ad. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }
    }
  }
}
