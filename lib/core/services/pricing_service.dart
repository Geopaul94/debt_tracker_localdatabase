import '../constants/currencies.dart';

class PremiumPricing {
  final double yearlyPrice;
  final double monthlyPrice;
  final Currency currency;

  const PremiumPricing({
    required this.yearlyPrice,
    required this.monthlyPrice,
    required this.currency,
  });

  String get formattedYearlyPrice =>
      '${currency.symbol}${_formatPrice(yearlyPrice)}';
  String get formattedMonthlyPrice =>
      '${currency.symbol}${_formatPrice(monthlyPrice)}';

  String get formattedMonthlyCostOfYearly {
    final monthlyCost = yearlyPrice / 12;
    return '${currency.symbol}${_formatPrice(monthlyCost)}';
  }

  String get formattedSavings {
    final totalMonthly = monthlyPrice * 12;
    final savings = totalMonthly - yearlyPrice;
    return '${currency.symbol}${_formatPrice(savings)}';
  }

  String _formatPrice(double price) {
    // For currencies like JPY, KRW, VND that don't use decimals
    if (['JPY', 'KRW', 'VND', 'IDR'].contains(currency.code)) {
      return price.toInt().toString();
    }
    // For other currencies, show 2 decimal places
    return price.toStringAsFixed(2);
  }
}

class PricingService {
  static PricingService? _instance;
  static PricingService get instance => _instance ??= PricingService._();
  PricingService._();

  // Base pricing in different currencies (approximate conversions from ₹750/year, ₹99/month)
  static const Map<String, PremiumPricing> _currencyPricing = {
    // North America
    'USD': PremiumPricing(
      yearlyPrice: 9.99,
      monthlyPrice: 1.49,
      currency: Currency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        flag: '🇺🇸',
      ),
    ),
    'CAD': PremiumPricing(
      yearlyPrice: 13.99,
      monthlyPrice: 1.99,
      currency: Currency(
        code: 'CAD',
        symbol: 'C\$',
        name: 'Canadian Dollar',
        flag: '🇨🇦',
      ),
    ),
    'MXN': PremiumPricing(
      yearlyPrice: 199.99,
      monthlyPrice: 29.99,
      currency: Currency(
        code: 'MXN',
        symbol: '\$',
        name: 'Mexican Peso',
        flag: '🇲🇽',
      ),
    ),

    // Europe
    'EUR': PremiumPricing(
      yearlyPrice: 8.99,
      monthlyPrice: 1.29,
      currency: Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    ),
    'GBP': PremiumPricing(
      yearlyPrice: 7.99,
      monthlyPrice: 1.19,
      currency: Currency(
        code: 'GBP',
        symbol: '£',
        name: 'British Pound',
        flag: '🇬🇧',
      ),
    ),
    'CHF': PremiumPricing(
      yearlyPrice: 9.99,
      monthlyPrice: 1.49,
      currency: Currency(
        code: 'CHF',
        symbol: 'Fr',
        name: 'Swiss Franc',
        flag: '🇨🇭',
      ),
    ),
    'NOK': PremiumPricing(
      yearlyPrice: 99.99,
      monthlyPrice: 14.99,
      currency: Currency(
        code: 'NOK',
        symbol: 'kr',
        name: 'Norwegian Krone',
        flag: '🇳🇴',
      ),
    ),
    'SEK': PremiumPricing(
      yearlyPrice: 99.99,
      monthlyPrice: 14.99,
      currency: Currency(
        code: 'SEK',
        symbol: 'kr',
        name: 'Swedish Krona',
        flag: '🇸🇪',
      ),
    ),
    'DKK': PremiumPricing(
      yearlyPrice: 69.99,
      monthlyPrice: 9.99,
      currency: Currency(
        code: 'DKK',
        symbol: 'kr',
        name: 'Danish Krone',
        flag: '🇩🇰',
      ),
    ),

    // Asia
    'JPY': PremiumPricing(
      yearlyPrice: 1299,
      monthlyPrice: 179,
      currency: Currency(
        code: 'JPY',
        symbol: '¥',
        name: 'Japanese Yen',
        flag: '🇯🇵',
      ),
    ),
    'CNY': PremiumPricing(
      yearlyPrice: 69.99,
      monthlyPrice: 9.99,
      currency: Currency(
        code: 'CNY',
        symbol: '¥',
        name: 'Chinese Yuan',
        flag: '🇨🇳',
      ),
    ),
    'KRW': PremiumPricing(
      yearlyPrice: 12999,
      monthlyPrice: 1799,
      currency: Currency(
        code: 'KRW',
        symbol: '₩',
        name: 'South Korean Won',
        flag: '🇰🇷',
      ),
    ),
    'INR': PremiumPricing(
      yearlyPrice: 750.00,
      monthlyPrice: 99.00,
      currency: Currency(
        code: 'INR',
        symbol: '₹',
        name: 'Indian Rupee',
        flag: '🇮🇳',
      ),
    ),
    'SGD': PremiumPricing(
      yearlyPrice: 13.99,
      monthlyPrice: 1.99,
      currency: Currency(
        code: 'SGD',
        symbol: 'S\$',
        name: 'Singapore Dollar',
        flag: '🇸🇬',
      ),
    ),
    'HKD': PremiumPricing(
      yearlyPrice: 79.99,
      monthlyPrice: 11.99,
      currency: Currency(
        code: 'HKD',
        symbol: 'HK\$',
        name: 'Hong Kong Dollar',
        flag: '🇭🇰',
      ),
    ),
    'MYR': PremiumPricing(
      yearlyPrice: 44.99,
      monthlyPrice: 6.99,
      currency: Currency(
        code: 'MYR',
        symbol: 'RM',
        name: 'Malaysian Ringgit',
        flag: '🇲🇾',
      ),
    ),
    'THB': PremiumPricing(
      yearlyPrice: 349.99,
      monthlyPrice: 49.99,
      currency: Currency(
        code: 'THB',
        symbol: '฿',
        name: 'Thai Baht',
        flag: '🇹🇭',
      ),
    ),
    'VND': PremiumPricing(
      yearlyPrice: 249000,
      monthlyPrice: 34900,
      currency: Currency(
        code: 'VND',
        symbol: '₫',
        name: 'Vietnamese Dong',
        flag: '🇻🇳',
      ),
    ),
    'PHP': PremiumPricing(
      yearlyPrice: 549.99,
      monthlyPrice: 79.99,
      currency: Currency(
        code: 'PHP',
        symbol: '₱',
        name: 'Philippine Peso',
        flag: '🇵🇭',
      ),
    ),
    'IDR': PremiumPricing(
      yearlyPrice: 149000,
      monthlyPrice: 19900,
      currency: Currency(
        code: 'IDR',
        symbol: 'Rp',
        name: 'Indonesian Rupiah',
        flag: '🇮🇩',
      ),
    ),

    // Middle East & Africa
    'AED': PremiumPricing(
      yearlyPrice: 36.99,
      monthlyPrice: 5.49,
      currency: Currency(
        code: 'AED',
        symbol: 'د.إ',
        name: 'UAE Dirham',
        flag: '🇦🇪',
      ),
    ),
    'SAR': PremiumPricing(
      yearlyPrice: 37.99,
      monthlyPrice: 5.49,
      currency: Currency(
        code: 'SAR',
        symbol: '﷼',
        name: 'Saudi Riyal',
        flag: '🇸🇦',
      ),
    ),
    'ZAR': PremiumPricing(
      yearlyPrice: 179.99,
      monthlyPrice: 24.99,
      currency: Currency(
        code: 'ZAR',
        symbol: 'R',
        name: 'South African Rand',
        flag: '🇿🇦',
      ),
    ),
    'EGP': PremiumPricing(
      yearlyPrice: 489.99,
      monthlyPrice: 69.99,
      currency: Currency(
        code: 'EGP',
        symbol: '£',
        name: 'Egyptian Pound',
        flag: '🇪🇬',
      ),
    ),

    // Oceania
    'AUD': PremiumPricing(
      yearlyPrice: 14.99,
      monthlyPrice: 2.19,
      currency: Currency(
        code: 'AUD',
        symbol: 'A\$',
        name: 'Australian Dollar',
        flag: '🇦🇺',
      ),
    ),
    'NZD': PremiumPricing(
      yearlyPrice: 15.99,
      monthlyPrice: 2.29,
      currency: Currency(
        code: 'NZD',
        symbol: 'NZ\$',
        name: 'New Zealand Dollar',
        flag: '🇳🇿',
      ),
    ),

    // South America
    'BRL': PremiumPricing(
      yearlyPrice: 54.99,
      monthlyPrice: 7.99,
      currency: Currency(
        code: 'BRL',
        symbol: 'R\$',
        name: 'Brazilian Real',
        flag: '🇧🇷',
      ),
    ),
    'ARS': PremiumPricing(
      yearlyPrice: 9999.99,
      monthlyPrice: 1399.99,
      currency: Currency(
        code: 'ARS',
        symbol: '\$',
        name: 'Argentine Peso',
        flag: '🇦🇷',
      ),
    ),
    'CLP': PremiumPricing(
      yearlyPrice: 8999.99,
      monthlyPrice: 1299.99,
      currency: Currency(
        code: 'CLP',
        symbol: '\$',
        name: 'Chilean Peso',
        flag: '🇨🇱',
      ),
    ),
    'COP': PremiumPricing(
      yearlyPrice: 39999.99,
      monthlyPrice: 5799.99,
      currency: Currency(
        code: 'COP',
        symbol: '\$',
        name: 'Colombian Peso',
        flag: '🇨🇴',
      ),
    ),
  };

  PremiumPricing getPricingForCurrency(Currency currency) {
    return _currencyPricing[currency.code] ?? _currencyPricing['USD']!;
  }

  PremiumPricing getPricingForCurrencyCode(String currencyCode) {
    return _currencyPricing[currencyCode] ?? _currencyPricing['USD']!;
  }

  // Get pricing with fallback to USD if currency not supported
  PremiumPricing getCurrentPricing(Currency userCurrency) {
    return getPricingForCurrency(userCurrency);
  }

  // Calculate percentage savings for yearly plan
  double calculateYearlySavingsPercentage(PremiumPricing pricing) {
    final totalMonthly = pricing.monthlyPrice * 12;
    final savings = totalMonthly - pricing.yearlyPrice;
    return (savings / totalMonthly) * 100;
  }

  // Get localized price description
  String getPriceDescription(PremiumPricing pricing, {required bool isYearly}) {
    if (isYearly) {
      final savingsPercent = calculateYearlySavingsPercentage(pricing);
      return '${pricing.formattedYearlyPrice}/year (Save ${savingsPercent.toInt()}%)';
    } else {
      return '${pricing.formattedMonthlyPrice}/month';
    }
  }

  // Check if currency has special formatting rules
  bool usesCurrencyDecimals(String currencyCode) {
    return !['JPY', 'KRW', 'VND', 'IDR'].contains(currencyCode);
  }
}
