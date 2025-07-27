import 'package:debt_tracker/presentation/pages/owetrackerapp.dart';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'injection/injection_container.dart';
import 'core/services/preference_service.dart';
import 'core/utils/logger.dart';

// 2. Main function to run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.info('Starting app initialization...');

    // Initialize only critical services that are needed for UI
    await PreferenceService.instance.initialize();
    AppLogger.info('Preference service initialized');

    // Initialize dependencies synchronously to ensure BLoCs are available
    await initializeDependencies();
    AppLogger.info('Dependencies initialized successfully');

    AppLogger.info('App initialization completed successfully - showing UI');
    runApp(const OweTrackerApp());
  } catch (e) {
    AppLogger.error('Failed to initialize app', e);
    runApp(ErrorApp(error: e.toString()));
  }
}

// Initialize dependencies in background after UI is shown
void _initializeDependenciesInBackground() async {
  try {
    // Initialize AdMob early but don't block app launch
    MobileAds.instance
        .initialize()
        .then((_) {
          AppLogger.info('AdMob initialized successfully in background');
        })
        .catchError((e) {
          AppLogger.error('AdMob initialization failed in background', e);
        });

    AppLogger.info('Background dependencies initialization completed');
  } catch (e) {
    AppLogger.error('Background dependency initialization failed', e);
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

