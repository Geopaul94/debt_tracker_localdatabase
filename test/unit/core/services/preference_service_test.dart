import 'package:debt_tracker/core/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferenceService Tests', () {
    late PreferenceService preferenceService;

    setUp(() async {
      // Set up fake shared preferences for testing
      SharedPreferences.setMockInitialValues({});
      preferenceService = PreferenceService.instance;
      await preferenceService.initialize();
    });

    group('Install Date Management', () {
      test('should set and get install date correctly', () async {
        final testDate = DateTime(2024, 1, 1);
        await preferenceService.setInstallDate(testDate);

        final retrievedDate = await preferenceService.getInstallDate();
        expect(retrievedDate, equals(testDate));
      });

      test('should return true for shouldShowAds after install date', () async {
        final pastDate = DateTime.now().subtract(Duration(days: 8));
        await preferenceService.setInstallDate(pastDate);

        final shouldShow = await preferenceService.shouldShowAds();
        expect(shouldShow, isTrue);
      });
    });

    group('Dummy Data Management', () {
      test('should track dummy data state correctly', () async {
        // Initially should have no dummy data
        expect(await preferenceService.hasDummyData(), isFalse);

        // Set dummy data flag
        await preferenceService.setHasDummyData(true);
        expect(await preferenceService.hasDummyData(), isTrue);

        // Reset dummy data flags
        await preferenceService.resetDummyDataFlags();
        expect(await preferenceService.hasDummyData(), isFalse);
      });

      test('should track real transaction state correctly', () async {
        // Initially should have no real transactions
        expect(await preferenceService.hasRealTransaction(), isFalse);

        // Set real transaction flag
        await preferenceService.setHasRealTransaction(true);
        expect(await preferenceService.hasRealTransaction(), isTrue);
      });

      test(
        'should cleanup dummy data when user adds real transaction',
        () async {
          await preferenceService.setHasDummyData(true);
          await preferenceService.setHasRealTransaction(true);

          final shouldCleanup =
              await preferenceService.shouldCleanupDummyData();
          expect(shouldCleanup, isTrue);
        },
      );

      test('should cleanup dummy data after 2 app sessions', () async {
        await preferenceService.setHasDummyData(true);

        // First session - should not cleanup
        await preferenceService.incrementAppSession();
        expect(await preferenceService.shouldCleanupDummyData(), isFalse);

        // Second session - should cleanup
        await preferenceService.incrementAppSession();
        expect(await preferenceService.shouldCleanupDummyData(), isTrue);
      });
    });

    group('App Session Tracking', () {
      test('should increment app session count correctly', () async {
        expect(await preferenceService.getAppSessionCount(), equals(0));

        await preferenceService.incrementAppSession();
        expect(await preferenceService.getAppSessionCount(), equals(1));

        await preferenceService.incrementAppSession();
        expect(await preferenceService.getAppSessionCount(), equals(2));
      });
    });

    group('First Launch Management', () {
      test('should track first launch correctly', () async {
        expect(await preferenceService.isFirstLaunch(), isTrue);

        await preferenceService.setFirstLaunchCompleted();
        expect(await preferenceService.isFirstLaunch(), isFalse);
      });
    });

    group('Ads Management', () {
      test('should manage ads enabled state correctly', () async {
        expect(await preferenceService.areAdsEnabled(), isFalse);

        await preferenceService.setAdsEnabled(true);
        expect(await preferenceService.areAdsEnabled(), isTrue);

        await preferenceService.setAdsEnabled(false);
        expect(await preferenceService.areAdsEnabled(), isFalse);
      });
    });
  });
}
