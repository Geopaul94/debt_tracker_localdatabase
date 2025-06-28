import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/preference_service.dart';
import '../../injection/injection_container.dart';
import '../bloc/authentication/auth_bloc.dart';
import '../bloc/authentication/auth_event.dart';
import '../bloc/authentication/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();

    // Initialize the auth bloc
    _authBloc = serviceLocator<AuthBloc>();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Set up animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start animations and navigate after delay
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start the animation
    _controller.forward();

    // Wait for animation to complete and some extra time
    await Future.delayed(const Duration(seconds: 3));

    // Check if this is the first launch
    if (mounted) {
      final isFirstLaunch = await PreferenceService.instance.isFirstLaunch();

      if (isFirstLaunch) {
        Navigator.of(context).pushReplacementNamed('/first-time-setup');
      } else {
        // Check if authentication is required
        _authBloc.add(CheckAuthRequiredEvent());
      }
    }
  }

  void _handleAuthState(AuthState state) {
    if (!mounted) return;

    if (state is AuthRequired) {
      Navigator.of(context).pushReplacementNamed('/auth');
    } else if (state is AuthNotRequired) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is AuthError) {
      // On error, assume no auth is required and go to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        backgroundColor: Colors.teal[50],
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) => _handleAuthState(state),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
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
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.teal[600],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Title
                        const Text(
                          'Debt Tracker',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // App Subtitle
                        Text(
                          'Track your debts and loans',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Loading indicator
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal[600]!,
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
      ),
    );
  }
}
