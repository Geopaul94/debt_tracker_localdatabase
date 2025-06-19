import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    showSplashScreen(context);
    // Initialize the animation controller
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset('assets/debit_tracker.svg', width: 200, height: 200),
            const Text('Debt Tracker'),
            const Text('Track your debts and loans'),
            const Text('Track your debts and loans'),
          ],
        ),
      ),
    );
  }
}

Future<void> showSplashScreen(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 2));
  Navigator.of(context).pushReplacementNamed('/home');
}
