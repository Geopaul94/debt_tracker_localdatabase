import 'dart:convert';
import 'package:flutter/services.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['currency_code'] as String,
      symbol: json['currency_symbol'] as String,
      name: json['currency_name'] as String,
      flag: json['flag'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency_code': code,
      'currency_symbol': symbol,
      'currency_name': name,
      'flag': flag,
    };
  }

  @override
  String toString() => '$symbol $code';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency &&
        other.code == code &&
        other.symbol == symbol &&
        other.name == name &&
        other.flag == flag;
  }

  @override
  int get hashCode {
    return code.hashCode ^ symbol.hashCode ^ name.hashCode ^ flag.hashCode;
  }
}

class CurrencyConstants {
  static List<Currency>? _cachedCurrencies;
  static List<Currency>? _popularCurrencies;

  /// Load currencies from JSON asset file
  static Future<List<Currency>> loadCurrencies() async {
    if (_cachedCurrencies != null) {
      return _cachedCurrencies!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/currencies.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedCurrencies =
          jsonList
              .map((json) => Currency.fromJson(json as Map<String, dynamic>))
              .toList();

      // Sort alphabetically by currency name for better UX
      _cachedCurrencies!.sort((a, b) => a.name.compareTo(b.name));

      return _cachedCurrencies!;
    } catch (e) {
      // Fallback to a basic USD currency if loading fails
      _cachedCurrencies = [
        const Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          flag: '🇺🇸',
        ),
      ];
      return _cachedCurrencies!;
    }
  }

  /// Get popular/most used currencies for quick selection
  static Future<List<Currency>> getPopularCurrencies() async {
    if (_popularCurrencies != null) {
      return _popularCurrencies!;
    }

    final allCurrencies = await loadCurrencies();

    // List of popular currency codes
    const popularCodes = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'CNY',
      'SEK',
      'NZD',
      'MXN',
      'SGD',
      'HKD',
      'NOK',
      'TRY',
      'ZAR',
      'BRL',
      'INR',
      'KRW',
      'DKK',
    ];

    _popularCurrencies =
        allCurrencies
            .where((currency) => popularCodes.contains(currency.code))
            .toList();

    // Sort popular currencies by the order in popularCodes
    _popularCurrencies!.sort((a, b) {
      final aIndex = popularCodes.indexOf(a.code);
      final bIndex = popularCodes.indexOf(b.code);
      return aIndex.compareTo(bIndex);
    });

    return _popularCurrencies!;
  }

  static Currency get defaultCurrency => const Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    flag: '🇺🇸',
  );

  static Future<Currency?> findByCode(String code) async {
    final currencies = await loadCurrencies();
    try {
      return currencies.firstWhere(
        (currency) => currency.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search currencies by name, code, or symbol
  static Future<List<Currency>> searchCurrencies(String query) async {
    if (query.isEmpty) {
      return await loadCurrencies();
    }

    final currencies = await loadCurrencies();
    final queryLower = query.toLowerCase();

    return currencies.where((currency) {
      return currency.name.toLowerCase().contains(queryLower) ||
          currency.code.toLowerCase().contains(queryLower) ||
          currency.symbol.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// For backward compatibility with existing code
  static Future<List<Currency>> get supportedCurrencies async =>
      await loadCurrencies();
}
