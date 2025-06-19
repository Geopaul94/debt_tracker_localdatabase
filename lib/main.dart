import 'dart:async';

import 'package:debit_tracker/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'injection/injection_container.dart';
import 'presentation/bloc/transaction_bloc.dart';
import 'presentation/pages/home_page.dart';

// 2. Main function to run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob early
  try {
    await MobileAds.instance.initialize();
    print('AdMob initialized successfully in main');
  } catch (e) {
    print('AdMob initialization failed in main: $e');
  }
  try {
    print('Start ing app initialization...');
    await initializeDependencies();
    print('App initialization completed successfully');
    runApp(OweTrackerApp());
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

// 3. Root Application Widget
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debt Tracker - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'App Failed to Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OweTrackerApp extends StatelessWidget {
  const OweTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size based on iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocProvider(
          create: (context) => serviceLocator<TransactionBloc>(),
          child: MaterialApp(
            title: 'Debt Tracker',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal, // Primary color for the app
                brightness: Brightness.light,
              ),
              primarySwatch: Colors.teal,
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(fontSize: 16.sp),
                bodyMedium: TextStyle(fontSize: 14.sp),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.teal, // AppBar background
                foregroundColor: Colors.white, // AppBar text and icon color
                elevation: 4.0,
                titleTextStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700], // Button background
                  foregroundColor: Colors.white, // Button text color
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              cardTheme: CardTheme(
                elevation: 3.0,
                margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 5.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.teal, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.teal[800]),
              ),
              useMaterial3: true,
            ),
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
