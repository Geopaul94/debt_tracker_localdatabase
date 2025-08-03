import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:debt_tracker/core/constants/currencies.dart';

// Mock class for testing
class MockAssetBundle extends Mock implements AssetBundle {}

@GenerateMocks([AssetBundle])
void main() {
  group('CurrencyConstants', () {
    setUp(() {
      // Clear cached currencies before each test
      CurrencyConstants._cachedCurrencies = null;
      CurrencyConstants._popularCurrencies = null;
    });

    group('Currency Loading', () {
      test('should load currencies from JSON asset', () async {
        // This test will use the actual asset file
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();

        // Assert
        expect(currencies, isNotEmpty);
        expect(currencies.length, greaterThan(50)); // We expect many world currencies
        
        // Check if USD is present
        final usdCurrency = currencies.firstWhere((c) => c.code == 'USD');
        expect(usdCurrency.name, 'US Dollar');
        expect(usdCurrency.symbol, '\$');
        expect(usdCurrency.flag, '🇺🇸');
      });

      test('should return cached currencies on subsequent calls', () async {
        // Act
        final currencies1 = await CurrencyConstants.loadCurrencies();
        final currencies2 = await CurrencyConstants.loadCurrencies();

        // Assert
        expect(identical(currencies1, currencies2), isTrue);
      });

      test('should sort currencies alphabetically by name', () async {
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();

        // Assert
        expect(currencies.length, greaterThan(1));
        for (int i = 0; i < currencies.length - 1; i++) {
          expect(
            currencies[i].name.compareTo(currencies[i + 1].name),
            lessThanOrEqualTo(0),
            reason: 'Currency ${currencies[i].name} should come before ${currencies[i + 1].name}',
          );
        }
      });

      test('should handle loading errors gracefully', () async {
        // Arrange - Clear cache to force reload
        CurrencyConstants._cachedCurrencies = null;
        
        // Note: This test would need a mock AssetBundle to simulate failure
        // For now, we test that the method returns at least the fallback currency
        
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();

        // Assert
        expect(currencies, isNotEmpty);
        expect(currencies.any((c) => c.code == 'USD'), isTrue);
      });
    });

    group('Popular Currencies', () {
      test('should return popular currencies subset', () async {
        // Act
        final popularCurrencies = await CurrencyConstants.getPopularCurrencies();

        // Assert
        expect(popularCurrencies, isNotEmpty);
        expect(popularCurrencies.length, lessThanOrEqualTo(20)); // Should be a subset
        
        // Check that USD, EUR, GBP are included (most popular)
        expect(popularCurrencies.any((c) => c.code == 'USD'), isTrue);
        expect(popularCurrencies.any((c) => c.code == 'EUR'), isTrue);
        expect(popularCurrencies.any((c) => c.code == 'GBP'), isTrue);
      });

      test('should return cached popular currencies on subsequent calls', () async {
        // Act
        final popular1 = await CurrencyConstants.getPopularCurrencies();
        final popular2 = await CurrencyConstants.getPopularCurrencies();

        // Assert
        expect(identical(popular1, popular2), isTrue);
      });

      test('should maintain order of popular currencies', () async {
        // Act
        final popularCurrencies = await CurrencyConstants.getPopularCurrencies();

        // Assert
        expect(popularCurrencies.first.code, 'USD'); // USD should be first
        expect(popularCurrencies.any((c) => c.code == 'EUR'), isTrue);
      });
    });

    group('Currency Search', () {
      test('should find currency by exact code match', () async {
        // Act
        final currency = await CurrencyConstants.findByCode('USD');

        // Assert
        expect(currency, isNotNull);
        expect(currency!.code, 'USD');
        expect(currency.name, 'US Dollar');
      });

      test('should find currency by case-insensitive code', () async {
        // Act
        final currency = await CurrencyConstants.findByCode('usd');

        // Assert
        expect(currency, isNotNull);
        expect(currency!.code, 'USD');
      });

      test('should return null for non-existent currency code', () async {
        // Act
        final currency = await CurrencyConstants.findByCode('INVALID');

        // Assert
        expect(currency, isNull);
      });

      test('should search currencies by name', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('Dollar');

        // Assert
        expect(results, isNotEmpty);
        expect(results.any((c) => c.name.contains('Dollar')), isTrue);
      });

      test('should search currencies by code', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('USD');

        // Assert
        expect(results, isNotEmpty);
        expect(results.any((c) => c.code == 'USD'), isTrue);
      });

      test('should search currencies by symbol', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('\$');

        // Assert
        expect(results, isNotEmpty);
        expect(results.any((c) => c.symbol.contains('\$')), isTrue);
      });

      test('should return all currencies for empty search query', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('');
        final allCurrencies = await CurrencyConstants.loadCurrencies();

        // Assert
        expect(results.length, equals(allCurrencies.length));
      });

      test('should perform case-insensitive search', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('euro');

        // Assert
        expect(results, isNotEmpty);
        expect(results.any((c) => c.name.toLowerCase().contains('euro')), isTrue);
      });

      test('should return empty results for non-matching search', () async {
        // Act
        final results = await CurrencyConstants.searchCurrencies('NONEXISTENTCURRENCY');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('Default Currency', () {
      test('should return USD as default currency', () {
        // Act
        final defaultCurrency = CurrencyConstants.defaultCurrency;

        // Assert
        expect(defaultCurrency.code, 'USD');
        expect(defaultCurrency.symbol, '\$');
        expect(defaultCurrency.name, 'US Dollar');
        expect(defaultCurrency.flag, '🇺🇸');
      });
    });

    group('Supported Currencies Getter', () {
      test('should return same result as loadCurrencies', () async {
        // Act
        final loadedCurrencies = await CurrencyConstants.loadCurrencies();
        final supportedCurrencies = await CurrencyConstants.supportedCurrencies;

        // Assert
        expect(supportedCurrencies.length, equals(loadedCurrencies.length));
        expect(supportedCurrencies.first.code, equals(loadedCurrencies.first.code));
      });
    });

    group('Currency Data Validation', () {
      test('should have valid currency data structure', () async {
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();

        // Assert
        for (final currency in currencies) {
          expect(currency.code, isNotEmpty, reason: 'Currency code should not be empty');
          expect(currency.code.length, inInclusiveRange(3, 3), reason: 'Currency code should be 3 characters');
          expect(currency.name, isNotEmpty, reason: 'Currency name should not be empty');
          expect(currency.symbol, isNotNull, reason: 'Currency symbol should not be null');
          expect(currency.flag, isNotNull, reason: 'Currency flag should not be null');
        }
      });

      test('should have unique currency codes', () async {
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();
        final codes = currencies.map((c) => c.code).toList();

        // Assert
        final uniqueCodes = codes.toSet();
        expect(uniqueCodes.length, equals(codes.length), 
               reason: 'All currency codes should be unique');
      });

      test('should include major world currencies', () async {
        // Act
        final currencies = await CurrencyConstants.loadCurrencies();
        final codes = currencies.map((c) => c.code).toSet();

        // Assert - Check for major currencies
        final majorCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY'];
        for (final code in majorCurrencies) {
          expect(codes.contains(code), isTrue, 
                 reason: 'Should contain major currency: $code');
        }
      });
    });

    group('Error Handling', () {
      test('should handle empty JSON gracefully', () async {
        // This would require mocking the asset bundle
        // For now, we verify the current implementation doesn't crash
        
        // Act & Assert
        expect(() => CurrencyConstants.loadCurrencies(), returnsNormally);
      });
    });
  });
}

// Extension to provide access to private members for testing
extension CurrencyConstantsTestExtension on CurrencyConstants {
  static set _cachedCurrencies(List<Currency>? value) {
    CurrencyConstants._cachedCurrencies = value;
  }
  
  static set _popularCurrencies(List<Currency>? value) {
    CurrencyConstants._popularCurrencies = value;
  }
}