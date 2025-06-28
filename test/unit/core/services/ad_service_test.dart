import 'package:debt_tracker/core/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdService Tests', () {
    late AdService adService;

    setUp(() {
      adService = AdService.instance;
    });

    group('Enum Tests', () {
      test('should have correct AdWeek enum values', () {
        expect(AdWeek.values.length, equals(4));
        expect(AdWeek.values.contains(AdWeek.week1), isTrue);
        expect(AdWeek.values.contains(AdWeek.week2), isTrue);
        expect(AdWeek.values.contains(AdWeek.week3), isTrue);
        expect(AdWeek.values.contains(AdWeek.week4Plus), isTrue);
      });
    });

    group('Initialization', () {
      test('should create singleton instance', () {
        final instance1 = AdService.instance;
        final instance2 = AdService.instance;
        expect(identical(instance1, instance2), isTrue);
      });

      test('should initialize without throwing errors', () {
        expect(() => adService.initialize(), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle multiple initialization calls gracefully', () async {
        expect(() async {
          await adService.initialize();
          await adService.initialize();
          await adService.initialize();
        }, returnsNormally);
      });

      test('should handle disposal gracefully', () {
        expect(() => adService.dispose(), returnsNormally);
      });
    });
  });
}
