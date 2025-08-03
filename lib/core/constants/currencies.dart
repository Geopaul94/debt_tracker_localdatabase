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
  static const List<Currency> supportedCurrencies = [
    // North America
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flag: '🇨🇦'),
    Currency(code: 'MXN', symbol: '\$', name: 'Mexican Peso', flag: '🇲🇽'),

    // Europe
    Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc', flag: '🇨🇭'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', flag: '🇳🇴'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', flag: '🇸🇪'),
    Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone', flag: '🇩🇰'),

    // Asia
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won', flag: '🇰🇷'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    Currency(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar',
      flag: '🇸🇬',
    ),
    Currency(
      code: 'HKD',
      symbol: 'HK\$',
      name: 'Hong Kong Dollar',
      flag: '🇭🇰',
    ),
    Currency(
      code: 'MYR',
      symbol: 'RM',
      name: 'Malaysian Ringgit',
      flag: '🇲🇾',
    ),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht', flag: '🇹🇭'),
    Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong', flag: '🇻🇳'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso', flag: '🇵🇭'),
    Currency(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Indonesian Rupiah',
      flag: '🇮🇩',
    ),

    // Middle East & Africa
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', flag: '🇦🇪'),
    Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', flag: '🇸🇦'),
    Currency(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      flag: '🇿🇦',
    ),
    Currency(code: 'EGP', symbol: '£', name: 'Egyptian Pound', flag: '🇪🇬'),

    // Oceania
    Currency(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      flag: '🇦🇺',
    ),
    Currency(
      code: 'NZD',
      symbol: 'NZ\$',
      name: 'New Zealand Dollar',
      flag: '🇳🇿',
    ),

    // South America
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', flag: '🇧🇷'),
    Currency(code: 'ARS', symbol: '\$', name: 'Argentine Peso', flag: '🇦🇷'),
    Currency(code: 'CLP', symbol: '\$', name: 'Chilean Peso', flag: '🇨🇱'),
    Currency(code: 'COP', symbol: '\$', name: 'Colombian Peso', flag: '🇨🇴'),
  ];

  static Currency get defaultCurrency => supportedCurrencies.first; // USD

  static Currency? findByCode(String code) {
    try {
      return supportedCurrencies.firstWhere(
        (currency) => currency.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  static List<Currency> getCurrenciesByRegion(String region) {
    switch (region.toLowerCase()) {
      case 'north america':
        return supportedCurrencies
            .where((c) => ['USD', 'CAD', 'MXN'].contains(c.code))
            .toList();
      case 'europe':
        return supportedCurrencies
            .where(
              (c) =>
                  ['EUR', 'GBP', 'CHF', 'NOK', 'SEK', 'DKK'].contains(c.code),
            )
            .toList();
      case 'asia':
        return supportedCurrencies
            .where(
              (c) => [
                'JPY',
                'CNY',
                'KRW',
                'INR',
                'SGD',
                'HKD',
                'MYR',
                'THB',
                'VND',
                'PHP',
                'IDR',
              ].contains(c.code),
            )
            .toList();
      case 'middle east & africa':
        return supportedCurrencies
            .where((c) => ['AED', 'SAR', 'ZAR', 'EGP'].contains(c.code))
            .toList();
      case 'oceania':
        return supportedCurrencies
            .where((c) => ['AUD', 'NZD'].contains(c.code))
            .toList();
      case 'south america':
        return supportedCurrencies
            .where((c) => ['BRL', 'ARS', 'CLP', 'COP'].contains(c.code))
            .toList();
      default:
        return supportedCurrencies;
    }
  }
}
