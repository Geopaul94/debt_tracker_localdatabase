import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:debt_tracker/core/services/preference_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PreferenceService', () {
    late PreferenceService preferenceService;

    setUp(() async {
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
