import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/authentication_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/preference_service.dart';
import '../../injection/injection_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Helper method to safely check if PremiumService is available
  bool _isPremiumServiceAvailable() {
    try {
      serviceLocator<PremiumService>();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to safely check if AuthenticationService is available
  bool _isAuthServiceAvailable() {
    try {
      serviceLocator<AuthenticationService>();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAppState();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAppState() async {
    try {
      // Minimal delay - just enough for animation to be visible
      await Future.delayed(const Duration(milliseconds: 300));

      print('🔍 Checking app state...');

      // Check if app needs first-time setup
      final isFirstLaunch = await PreferenceService.instance.isFirstLaunch();
      print('📱 First launch: $isFirstLaunch');

      if (isFirstLaunch) {
        print('🎯 Navigating to first-time setup');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/first-time-setup');
        }
        return;
      }

      // Check authentication requirements with fallback
      bool isAuthEnabled = false;
      if (_isAuthServiceAvailable()) {
        try {
          isAuthEnabled =
              await serviceLocator<AuthenticationService>()
                  .isAuthenticationEnabled();
          print('🔐 Authentication enabled: $isAuthEnabled');
        } catch (e) {
          print('⚠️ Auth service error, proceeding without authentication: $e');
          isAuthEnabled = false;
        }
      } else {
        print(
          '⚠️ Authentication service not yet available, skipping auth check',
        );
        isAuthEnabled = false;
      }

      if (isAuthEnabled) {
        // Check if user has premium or ad-free access to skip authentication
        bool canSkipAuth = false;

        if (_isPremiumServiceAvailable()) {
          try {
            canSkipAuth =
                await serviceLocator<PremiumService>().canSkipAuthentication();
            print('🎟️ Can skip authentication: $canSkipAuth');

            if (canSkipAuth) {
              final remainingMinutes =
                  await serviceLocator<PremiumService>()
                      .getRemainingAdFreeMinutes();
              print('⏰ Ad-free minutes remaining: $remainingMinutes');
            }
          } catch (e) {
            print('⚠️ Premium service error: $e');
            canSkipAuth = false;
          }
        } else {
          print('⚠️ Premium service not yet available');
          canSkipAuth = false;
        }

        if (canSkipAuth) {
          print('🎯 Skipping authentication, navigating to home');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          print('🔒 Authentication required, navigating to auth screen');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      } else {
        print('🏠 No authentication needed, navigating to home');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('❌ Error during app state check: $e');

      // Fallback navigation - always navigate to home if there's any error
      print('🏠 Fallback: navigating to home');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[400]!, Colors.teal[600]!],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
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

                      SizedBox(height: 32.h),

                      // App Name
                      Text(
                        'Debt Tracker',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Tagline
                      Text(
                        'Manage Your Finances',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: 48.h),

                      // Loading indicator
                      SizedBox(
                        width: 32.w,
                        height: 32.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
