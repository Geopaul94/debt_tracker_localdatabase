
import 'package:debit_tracker/presentation/pages/owetrackerapp.dart';

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
    print('AdMob initialized successfully in main');
  } catch (e) {
    print('AdMob initialization failed in main: $e');
  }
  try {
    print('Starting app initialization...');
    await initializeDependencies();

    // Initialize preference service
    await PreferenceService.instance.initialize();
    print('Preference service initialized');

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
