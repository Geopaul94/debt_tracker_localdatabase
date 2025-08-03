import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:debt_tracker/core/services/currency_service.dart';
import 'package:debt_tracker/core/constants/currencies.dart';
import 'package:debt_tracker/domain/entities/transaction_entity.dart';

void main() {
  group('CurrencyService', () {
    setUp(() async {
      // Clear any existing SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    group('Currency Management', () {
      test(
        'should return default currency when no preference is set',
        () async {
          // Arrange - Initialize service with empty preferences
          await CurrencyService.instance.initialize();

          // Act
          final currency = CurrencyService.instance.currentCurrency;

          // Assert
          expect(currency.code, 'USD');
          expect(currency.symbol, '\$');
          expect(currency.name, 'US Dollar');
          expect(currency.flag, '🇺🇸');
        },
      );

      test('should return saved currency when preference is set', () async {
        // Arrange - Set up mock preferences with EUR
        SharedPreferences.setMockInitialValues({
          'selected_currency_code': 'EUR',
          'selected_currency_symbol': '€',
          'selected_currency_name': 'Euro',
          'selected_currency_flag': '🇪🇺',
        });

        await CurrencyService.instance.initialize();

        // Act
        final currency = CurrencyService.instance.currentCurrency;

        // Assert
        expect(currency.code, 'EUR');
        expect(currency.symbol, '€');
        expect(currency.name, 'Euro');
        expect(currency.flag, '🇪🇺');
      });

      test(
        'should save currency to preferences when setCurrency is called',
        () async {
          // Arrange
          await CurrencyService.instance.initialize();

          final euroCurrency = Currency(
            code: 'EUR',
            symbol: '€',
            name: 'Euro',
            flag: '🇪🇺',
          );

          // Act
          await CurrencyService.instance.setCurrency(euroCurrency);

          // Assert - Check that preferences were updated
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('selected_currency_code'), 'EUR');
          expect(prefs.getString('selected_currency_symbol'), '€');
          expect(prefs.getString('selected_currency_name'), 'Euro');
          expect(prefs.getString('selected_currency_flag'), '🇪🇺');

          // Also check that current currency is updated
          expect(CurrencyService.instance.currentCurrency.code, 'EUR');
        },
      );
    });

    group('Amount Formatting', () {
      test('should format amount with default currency symbol', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'selected_currency_code': 'USD',
          'selected_currency_symbol': '\$',
          'selected_currency_name': 'US Dollar',
          'selected_currency_flag': '🇺🇸',
        });

        await CurrencyService.instance.initialize();

        // Act
        final formatted = CurrencyService.instance.formatAmount(1234.56);

        // Assert
        expect(formatted, '\$1234.56');
      });

      test('should format amount with specific currency', () {
        // Arrange
        final euroCurrency = Currency(
          code: 'EUR',
          symbol: '€',
          name: 'Euro',
          flag: '🇪🇺',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          1234.56,
          euroCurrency,
        );

        // Assert
        expect(formatted, '€1234.56');
      });

      test('should format zero amount correctly', () {
        // Arrange
        final usdCurrency = Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          flag: '🇺🇸',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          0.0,
          usdCurrency,
        );

        // Assert
        expect(formatted, '\$0.00');
      });

      test('should format negative amount correctly', () {
        // Arrange
        final usdCurrency = Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          flag: '🇺🇸',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          -1234.56,
          usdCurrency,
        );

        // Assert
        expect(formatted, '\$-1234.56');
      });

      test('should format large amount with thousands separators', () {
        // Arrange
        final usdCurrency = Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          flag: '🇺🇸',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          1234567.89,
          usdCurrency,
        );

        // Assert
        expect(formatted, '\$1234567.89');
      });
    });

    group('Amount Placeholder', () {
      test('should return placeholder with default currency symbol', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'selected_currency_symbol': '\$',
        });

        await CurrencyService.instance.initialize();

        // Act
        final placeholder = CurrencyService.instance.getAmountPlaceholder();

        // Assert
        expect(placeholder, 'Amount (\$)');
      });

      test('should return placeholder with specific currency', () {
        // Arrange
        final euroCurrency = Currency(
          code: 'EUR',
          symbol: '€',
          name: 'Euro',
          flag: '🇪🇺',
        );

        // Act
        final placeholder = CurrencyService.instance
            .getAmountPlaceholderForCurrency(euroCurrency);

        // Assert
        expect(placeholder, 'Amount (€)');
      });
    });

    group('Currency Conversion', () {
      test('should convert Currency to TransactionCurrency', () {
        // Arrange
        final currency = Currency(
          code: 'GBP',
          symbol: '£',
          name: 'British Pound',
          flag: '🇬🇧',
        );

        // Act
        final transactionCurrency =
            CurrencyService.currencyToTransactionCurrency(currency);

        // Assert
        expect(transactionCurrency.code, 'GBP');
        expect(transactionCurrency.symbol, '£');
        expect(transactionCurrency.name, 'British Pound');
        expect(transactionCurrency.flag, '🇬🇧');
      });

      test('should convert TransactionCurrency to Currency', () {
        // Arrange
        final transactionCurrency = TransactionCurrency(
          code: 'JPY',
          symbol: '¥',
          name: 'Japanese Yen',
          flag: '🇯🇵',
        );

        // Act
        final currency = CurrencyService.transactionCurrencyToCurrency(
          transactionCurrency,
        );

        // Assert
        expect(currency.code, 'JPY');
        expect(currency.symbol, '¥');
        expect(currency.name, 'Japanese Yen');
        expect(currency.flag, '🇯🇵');
      });
    });

    group('Edge Cases', () {
      test('should handle very small decimal amounts', () {
        // Arrange
        final usdCurrency = Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          flag: '🇺🇸',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          0.01,
          usdCurrency,
        );

        // Assert
        expect(formatted, '\$0.01');
      });

      test('should handle currency with empty symbol', () {
        // Arrange
        final currencyWithoutSymbol = Currency(
          code: 'XXX',
          symbol: '',
          name: 'Unknown Currency',
          flag: '',
        );

        // Act
        final formatted = CurrencyService.instance.formatAmountWithCurrency(
          100.0,
          currencyWithoutSymbol,
        );

        // Assert
        expect(formatted, '100.00');
      });

      test(
        'should handle currency service initialization multiple times',
        () async {
          // Act - Initialize multiple times
          await CurrencyService.instance.initialize();
          await CurrencyService.instance.initialize();

          // Assert - Should not crash and should work normally
          expect(CurrencyService.instance.currentCurrency.code, 'USD');
        },
      );
    });

    group('Integration Tests', () {
      test('should persist currency across service restarts', () async {
        // Arrange - Set a currency
        await CurrencyService.instance.initialize();

        final gbpCurrency = Currency(
          code: 'GBP',
          symbol: '£',
          name: 'British Pound',
          flag: '🇬🇧',
        );

        await CurrencyService.instance.setCurrency(gbpCurrency);

        // Act - Simulate restart by initializing again
        await CurrencyService.instance.initialize();

        // Assert - Currency should be persisted
        expect(CurrencyService.instance.currentCurrency.code, 'GBP');
        expect(CurrencyService.instance.currentCurrency.symbol, '£');
      });
    });
  });
}
