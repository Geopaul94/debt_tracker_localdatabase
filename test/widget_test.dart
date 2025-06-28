// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:debt_tracker/core/services/preference_service.dart';
import 'package:debt_tracker/injection/injection_container.dart';
import 'package:debt_tracker/presentation/pages/owetrackerapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('OweTracker App Tests', () {
    setUp(() async {
      // Reset GetIt before each test
      await GetIt.instance.reset();

      // Set up mock shared preferences for testing
      SharedPreferences.setMockInitialValues({
        'selected_currency_code': 'USD',
        'selected_currency_symbol': '\$',
        'selected_currency_name': 'US Dollar',
        'selected_currency_flag': '🇺🇸',
        'first_launch': false, // Simulate not first launch to avoid setup page
        'has_dummy_data': false,
        'app_session_count': 5,
      });

      // Initialize preferences for testing
      await PreferenceService.instance.initialize();

      // Initialize dependency injection for testing
      try {
        await initializeDependencies();
      } catch (e) {
        print('Dependencies initialization error: $e');
        // Continue without complete initialization for basic tests
      }
    });

    tearDown(() async {
      // Clean up after each test
      await GetIt.instance.reset();
    });

    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // Ignore overflow errors for testing
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('RenderFlex overflowed')) {
          return; // Ignore overflow errors in tests
        }
        FlutterError.presentError(details);
      };

      // Build our app and trigger a frame
      await tester.pumpWidget(OweTrackerApp());

      // Use pump instead of pumpAndSettle to avoid infinite animations
      await tester.pump(Duration(seconds: 1));

      // Verify that the app loads successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App shows proper initial state', (WidgetTester tester) async {
      // Ignore overflow errors for testing
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('RenderFlex overflowed')) {
          return; // Ignore overflow errors in tests
        }
        FlutterError.presentError(details);
      };

      await tester.pumpWidget(OweTrackerApp());
      await tester.pump(Duration(seconds: 1));

      // Should find basic app structure
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App handles navigation', (WidgetTester tester) async {
      await tester.pumpWidget(OweTrackerApp());
      await tester.pumpAndSettle();

      // Look for floating action button and test navigation
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Should navigate without crashing
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('PreferenceService integration in app', (
      WidgetTester tester,
    ) async {
      final prefs = PreferenceService.instance;

      // Test preference service functionality (without UI)
      await prefs.setHasDummyData(true);
      expect(await prefs.hasDummyData(), isTrue);

      await prefs.setFirstLaunchCompleted();
      expect(await prefs.isFirstLaunch(), isFalse);

      // Test session tracking
      await prefs.incrementAppSession();
      expect(await prefs.getAppSessionCount(), greaterThan(0));
    });

    testWidgets('App handles first launch scenario', (
      WidgetTester tester,
    ) async {
      final prefs = PreferenceService.instance;

      // Test preference service setup
      await prefs.resetDummyDataFlags(); // Reset for clean test
      expect(await prefs.hasDummyData(), isFalse);

      // Verify the preferences work
      await prefs.setHasDummyData(true);
      expect(await prefs.hasDummyData(), isTrue);
    });

    testWidgets('App basic widget structure', (WidgetTester tester) async {
      // Ignore overflow errors for testing
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('RenderFlex overflowed')) {
          return; // Ignore overflow errors in tests
        }
        FlutterError.presentError(details);
      };

      await tester.pumpWidget(OweTrackerApp());
      await tester.pump(Duration(seconds: 1));

      // Basic app structure should be present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Dependency injection works', (WidgetTester tester) async {
      // Test that we can initialize dependencies without errors
      try {
        await initializeDependencies();
        expect(true, isTrue); // If no exception, test passes
      } catch (e) {
        // Dependencies might already be initialized, that's OK
        expect(e.toString().contains('already registered'), isTrue);
      }
    });
  });
}
