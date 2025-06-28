
import 'package:debt_tracker/presentation/pages/owetrackerapp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'injection/injection_container.dart';
import 'core/services/preference_service.dart';

// 2. Main function to run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob early
  try {
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      print('AdMob initialized successfully in main');
    }
  } catch (e) {
    if (kDebugMode) {
      print('AdMob initialization failed in main: $e');
    }
  }
  try {
    if (kDebugMode) {
      print('Starting app initialization...');
    }
    await initializeDependencies();

    // Initialize preference service
    await PreferenceService.instance.initialize();
    if (kDebugMode) {
      print('Preference service initialized');
    }

    if (kDebugMode) {
      print('App initialization completed successfully');
    }
    runApp(OweTrackerApp());
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize app: $e');
    }
    runApp(ErrorApp(error: e.toString()));
  }
}

// 3. Root Application Widget
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

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
