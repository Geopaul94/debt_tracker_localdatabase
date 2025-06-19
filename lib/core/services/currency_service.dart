import 'package:shared_preferences/shared_preferences.dart';
import '../constants/currencies.dart';

class CurrencyService {
  static const String _currencyCodeKey = 'selected_currency_code';
  static const String _currencySymbolKey = 'selected_currency_symbol';
  static const String _currencyNameKey = 'selected_currency_name';
  static const String _currencyFlagKey = 'selected_currency_flag';

  static CurrencyService? _instance;
  static CurrencyService get instance => _instance ??= CurrencyService._();
  CurrencyService._();

  SharedPreferences? _prefs;
  Currency? _currentCurrency;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency() async {
    final code = _prefs?.getString(_currencyCodeKey);
    final symbol = _prefs?.getString(_currencySymbolKey);
    final name = _prefs?.getString(_currencyNameKey);
    final flag = _prefs?.getString(_currencyFlagKey);

    if (code != null && symbol != null && name != null && flag != null) {
      _currentCurrency = Currency(
        code: code,
        symbol: symbol,
        name: name,
        flag: flag,
      );
    } else {
      _currentCurrency = CurrencyConstants.defaultCurrency;
      await _saveCurrency(_currentCurrency!);
    }
  }

  Future<void> _saveCurrency(Currency currency) async {
    await _prefs?.setString(_currencyCodeKey, currency.code);
    await _prefs?.setString(_currencySymbolKey, currency.symbol);
    await _prefs?.setString(_currencyNameKey, currency.name);
    await _prefs?.setString(_currencyFlagKey, currency.flag);
  }

  Currency get currentCurrency =>
      _currentCurrency ?? CurrencyConstants.defaultCurrency;

  Future<void> setCurrency(Currency currency) async {
    _currentCurrency = currency;
    await _saveCurrency(currency);
  }

  String formatAmount(double amount) {
    final currency = currentCurrency;

    // Format based on currency type
    if (currency.code == 'JPY' ||
        currency.code == 'KRW' ||
        currency.code == 'VND') {
      // No decimal places for these currencies
      return '${currency.symbol}${amount.toStringAsFixed(0)}';
    } else if (currency.code == 'INR') {
      // Indian number formatting
      return '${currency.symbol}${_formatIndianNumber(amount)}';
    } else {
      // Standard formatting with 2 decimal places
      return '${currency.symbol}${amount.toStringAsFixed(2)}';
    }
  }

  String _formatIndianNumber(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    if (wholePart.length <= 3) {
      return '$wholePart.$decimalPart';
    }

    // Indian number system (lakhs, crores)
    final reversed = wholePart.split('').reversed.join();
    final chunks = <String>[];

    // First chunk of 3 digits
    if (reversed.length > 3) {
      chunks.add(reversed.substring(0, 3));
      // Remaining chunks of 2 digits
      for (int i = 3; i < reversed.length; i += 2) {
        final end = (i + 2 > reversed.length) ? reversed.length : i + 2;
        chunks.add(reversed.substring(i, end));
      }
    } else {
      chunks.add(reversed);
    }

    final formatted = chunks.join(',').split('').reversed.join();
    return '$formatted.$decimalPart';
  }

  String getAmountPlaceholder() {
    final currency = currentCurrency;
    if (currency.code == 'JPY' ||
        currency.code == 'KRW' ||
        currency.code == 'VND') {
      return 'Amount (${currency.symbol})';
    } else {
      return 'Amount (${currency.symbol})';
    }
  }
}
