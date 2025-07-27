import '../constants/currencies.dart';

class PremiumPricing {
  final double monthlyPrice;
  final double yearlyPrice;
  final double threeYearPrice;
  final double lifetimePrice;
  final Currency currency;

  const PremiumPricing({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.threeYearPrice,
    required this.lifetimePrice,
    required this.currency,
  });

  String get formattedMonthlyPrice =>
      '${currency.symbol}${_formatPrice(monthlyPrice)}';
  String get formattedYearlyPrice =>
      '${currency.symbol}${_formatPrice(yearlyPrice)}';
  String get formattedThreeYearPrice =>
      '${currency.symbol}${_formatPrice(threeYearPrice)}';
  String get formattedLifetimePrice =>
      '${currency.symbol}${_formatPrice(lifetimePrice)}';

  String get formattedMonthlyCostOfYearly {
    final monthlyCost = yearlyPrice / 12;
    return '${currency.symbol}${_formatPrice(monthlyCost)}';
  }

  String get formattedMonthlyCostOfThreeYear {
    final monthlyCost = threeYearPrice / 36;
    return '${currency.symbol}${_formatPrice(monthlyCost)}';
  }

  String get formattedYearlySavings {
    final totalMonthly = monthlyPrice * 12;
    final savings = totalMonthly - yearlyPrice;
    return '${currency.symbol}${_formatPrice(savings)}';
  }

  String get formattedThreeYearSavings {
    final totalMonthly = monthlyPrice * 36;
    final savings = totalMonthly - threeYearPrice;
    return '${currency.symbol}${_formatPrice(savings)}';
  }

  String get formattedLifetimeSavings {
    // Compare lifetime to 10 years of monthly payments
    final totalMonthly = monthlyPrice * 120;
    final savings = totalMonthly - lifetimePrice;
    return '${currency.symbol}${_formatPrice(savings)}';
  }

  int get yearlySavingsPercentage {
    final totalMonthly = monthlyPrice * 12;
    final savings = totalMonthly - yearlyPrice;
    return ((savings / totalMonthly) * 100).round();
  }

  int get threeYearSavingsPercentage {
    final totalMonthly = monthlyPrice * 36;
    final savings = totalMonthly - threeYearPrice;
    return ((savings / totalMonthly) * 100).round();
  }

  int get lifetimeSavingsPercentage {
    final totalMonthly = monthlyPrice * 120; // 10 years
    final savings = totalMonthly - lifetimePrice;
    return ((savings / totalMonthly) * 100).round();
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

  // Base pricing in different currencies (converted from INR: monthly ₹90, yearly ₹750, 3-year ₹1250, lifetime ₹2000)
  static const Map<String, PremiumPricing> _currencyPricing = {
    // North America
    'USD': PremiumPricing(
      monthlyPrice: 1.19,
      yearlyPrice: 9.99,
      threeYearPrice: 15.99,
      lifetimePrice: 25.99,
      currency: Currency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        flag: '🇺🇸',
      ),
    ),
    'CAD': PremiumPricing(
      monthlyPrice: 1.59,
      yearlyPrice: 13.99,
      threeYearPrice: 21.99,
      lifetimePrice: 34.99,
      currency: Currency(
        code: 'CAD',
        symbol: 'C\$',
        name: 'Canadian Dollar',
        flag: '🇨🇦',
      ),
    ),
    'MXN': PremiumPricing(
      monthlyPrice: 24.99,
      yearlyPrice: 199.99,
      threeYearPrice: 319.99,
      lifetimePrice: 499.99,
      currency: Currency(
        code: 'MXN',
        symbol: '\$',
        name: 'Mexican Peso',
        flag: '🇲🇽',
      ),
    ),

    // Europe
    'EUR': PremiumPricing(
      monthlyPrice: 1.09,
      yearlyPrice: 8.99,
      threeYearPrice: 14.99,
      lifetimePrice: 23.99,
      currency: Currency(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    ),
    'GBP': PremiumPricing(
      monthlyPrice: 0.99,
      yearlyPrice: 7.99,
      threeYearPrice: 12.99,
      lifetimePrice: 20.99,
      currency: Currency(
        code: 'GBP',
        symbol: '£',
        name: 'British Pound',
        flag: '🇬🇧',
      ),
    ),
    'CHF': PremiumPricing(
      monthlyPrice: 1.19,
      yearlyPrice: 9.99,
      threeYearPrice: 15.99,
      lifetimePrice: 25.99,
      currency: Currency(
        code: 'CHF',
        symbol: 'Fr',
        name: 'Swiss Franc',
        flag: '🇨🇭',
      ),
    ),
    'NOK': PremiumPricing(
      monthlyPrice: 12.99,
      yearlyPrice: 99.99,
      threeYearPrice: 159.99,
      lifetimePrice: 249.99,
      currency: Currency(
        code: 'NOK',
        symbol: 'kr',
        name: 'Norwegian Krone',
        flag: '🇳🇴',
      ),
    ),
    'SEK': PremiumPricing(
      monthlyPrice: 12.99,
      yearlyPrice: 99.99,
      threeYearPrice: 159.99,
      lifetimePrice: 249.99,
      currency: Currency(
        code: 'SEK',
        symbol: 'kr',
        name: 'Swedish Krona',
        flag: '🇸🇪',
      ),
    ),
    'DKK': PremiumPricing(
      monthlyPrice: 8.99,
      yearlyPrice: 69.99,
      threeYearPrice: 109.99,
      lifetimePrice: 179.99,
      currency: Currency(
        code: 'DKK',
        symbol: 'kr',
        name: 'Danish Krone',
        flag: '🇩🇰',
      ),
    ),

    // Asia
    'JPY': PremiumPricing(
      monthlyPrice: 149,
      yearlyPrice: 1299,
      threeYearPrice: 1999,
      lifetimePrice: 3199,
      currency: Currency(
        code: 'JPY',
        symbol: '¥',
        name: 'Japanese Yen',
        flag: '🇯🇵',
      ),
    ),
    'CNY': PremiumPricing(
      monthlyPrice: 8.99,
      yearlyPrice: 69.99,
      threeYearPrice: 109.99,
      lifetimePrice: 179.99,
      currency: Currency(
        code: 'CNY',
        symbol: '¥',
        name: 'Chinese Yuan',
        flag: '🇨🇳',
      ),
    ),
    'KRW': PremiumPricing(
      monthlyPrice: 1499,
      yearlyPrice: 12999,
      threeYearPrice: 19999,
      lifetimePrice: 31999,
      currency: Currency(
        code: 'KRW',
        symbol: '₩',
        name: 'South Korean Won',
        flag: '🇰🇷',
      ),
    ),
    'INR': PremiumPricing(
      monthlyPrice: 90.00,
      yearlyPrice: 750.00,
      threeYearPrice: 1250.00,
      lifetimePrice: 2000.00,
      currency: Currency(
        code: 'INR',
        symbol: '₹',
        name: 'Indian Rupee',
        flag: '🇮🇳',
      ),
    ),
    'SGD': PremiumPricing(
      monthlyPrice: 1.69,
      yearlyPrice: 13.99,
      threeYearPrice: 21.99,
      lifetimePrice: 34.99,
      currency: Currency(
        code: 'SGD',
        symbol: 'S\$',
        name: 'Singapore Dollar',
        flag: '🇸🇬',
      ),
    ),
    'HKD': PremiumPricing(
      monthlyPrice: 9.99,
      yearlyPrice: 79.99,
      threeYearPrice: 129.99,
      lifetimePrice: 199.99,
      currency: Currency(
        code: 'HKD',
        symbol: 'HK\$',
        name: 'Hong Kong Dollar',
        flag: '🇭🇰',
      ),
    ),
    'MYR': PremiumPricing(
      monthlyPrice: 5.49,
      yearlyPrice: 44.99,
      threeYearPrice: 69.99,
      lifetimePrice: 109.99,
      currency: Currency(
        code: 'MYR',
        symbol: 'RM',
        name: 'Malaysian Ringgit',
        flag: '🇲🇾',
      ),
    ),
    'THB': PremiumPricing(
      monthlyPrice: 39.99,
      yearlyPrice: 349.99,
      threeYearPrice: 549.99,
      lifetimePrice: 899.99,
      currency: Currency(
        code: 'THB',
        symbol: '฿',
        name: 'Thai Baht',
        flag: '🇹🇭',
      ),
    ),
    'VND': PremiumPricing(
      monthlyPrice: 29900,
      yearlyPrice: 249000,
      threeYearPrice: 399000,
      lifetimePrice: 649000,
      currency: Currency(
        code: 'VND',
        symbol: '₫',
        name: 'Vietnamese Dong',
        flag: '🇻🇳',
      ),
    ),
    'PHP': PremiumPricing(
      monthlyPrice: 69.99,
      yearlyPrice: 549.99,
      threeYearPrice: 899.99,
      lifetimePrice: 1399.99,
      currency: Currency(
        code: 'PHP',
        symbol: '₱',
        name: 'Philippine Peso',
        flag: '🇵🇭',
      ),
    ),
    'IDR': PremiumPricing(
      monthlyPrice: 17900,
      yearlyPrice: 149000,
      threeYearPrice: 239000,
      lifetimePrice: 389000,
      currency: Currency(
        code: 'IDR',
        symbol: 'Rp',
        name: 'Indonesian Rupiah',
        flag: '🇮🇩',
      ),
    ),

    // Middle East & Africa
    'AED': PremiumPricing(
      monthlyPrice: 4.49,
      yearlyPrice: 36.99,
      threeYearPrice: 59.99,
      lifetimePrice: 94.99,
      currency: Currency(
        code: 'AED',
        symbol: 'د.إ',
        name: 'UAE Dirham',
        flag: '🇦🇪',
      ),
    ),
    'SAR': PremiumPricing(
      monthlyPrice: 4.49,
      yearlyPrice: 37.99,
      threeYearPrice: 59.99,
      lifetimePrice: 94.99,
      currency: Currency(
        code: 'SAR',
        symbol: '﷼',
        name: 'Saudi Riyal',
        flag: '🇸🇦',
      ),
    ),
    'ZAR': PremiumPricing(
      monthlyPrice: 21.99,
      yearlyPrice: 179.99,
      threeYearPrice: 289.99,
      lifetimePrice: 459.99,
      currency: Currency(
        code: 'ZAR',
        symbol: 'R',
        name: 'South African Rand',
        flag: '🇿🇦',
      ),
    ),
    'EGP': PremiumPricing(
      monthlyPrice: 59.99,
      yearlyPrice: 489.99,
      threeYearPrice: 789.99,
      lifetimePrice: 1249.99,
      currency: Currency(
        code: 'EGP',
        symbol: '£',
        name: 'Egyptian Pound',
        flag: '🇪🇬',
      ),
    ),

    // Oceania
    'AUD': PremiumPricing(
      monthlyPrice: 1.79,
      yearlyPrice: 14.99,
      threeYearPrice: 23.99,
      lifetimePrice: 38.99,
      currency: Currency(
        code: 'AUD',
        symbol: 'A\$',
        name: 'Australian Dollar',
        flag: '🇦🇺',
      ),
    ),
    'NZD': PremiumPricing(
      monthlyPrice: 1.89,
      yearlyPrice: 15.99,
      threeYearPrice: 25.99,
      lifetimePrice: 40.99,
      currency: Currency(
        code: 'NZD',
        symbol: 'NZ\$',
        name: 'New Zealand Dollar',
        flag: '🇳🇿',
      ),
    ),

    // South America
    'BRL': PremiumPricing(
      monthlyPrice: 6.99,
      yearlyPrice: 54.99,
      threeYearPrice: 89.99,
      lifetimePrice: 139.99,
      currency: Currency(
        code: 'BRL',
        symbol: 'R\$',
        name: 'Brazilian Real',
        flag: '🇧🇷',
      ),
    ),
    'ARS': PremiumPricing(
      monthlyPrice: 1199.99,
      yearlyPrice: 9999.99,
      threeYearPrice: 15999.99,
      lifetimePrice: 24999.99,
      currency: Currency(
        code: 'ARS',
        symbol: '\$',
        name: 'Argentine Peso',
        flag: '🇦🇷',
      ),
    ),
    'CLP': PremiumPricing(
      monthlyPrice: 999.99,
      yearlyPrice: 8999.99,
      threeYearPrice: 14999.99,
      lifetimePrice: 23999.99,
      currency: Currency(
        code: 'CLP',
        symbol: '\$',
        name: 'Chilean Peso',
        flag: '🇨🇱',
      ),
    ),
    'COP': PremiumPricing(
      monthlyPrice: 4699.99,
      yearlyPrice: 39999.99,
      threeYearPrice: 64999.99,
      lifetimePrice: 99999.99,
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

  // Get localized price description for specific plan
  String getPriceDescription(PremiumPricing pricing, PlanType planType) {
    switch (planType) {
      case PlanType.monthly:
        return '${pricing.formattedMonthlyPrice}/month';
      case PlanType.yearly:
        final savingsPercent = pricing.yearlySavingsPercentage;
        return '${pricing.formattedYearlyPrice}/year (Save $savingsPercent%)';
      case PlanType.threeYear:
        final savingsPercent = pricing.threeYearSavingsPercentage;
        return '${pricing.formattedThreeYearPrice}/3 years (Save $savingsPercent%)';
      case PlanType.lifetime:
        final savingsPercent = pricing.lifetimeSavingsPercentage;
        return '${pricing.formattedLifetimePrice} lifetime (Save $savingsPercent%)';
    }
  }

  // Get monthly equivalent cost for comparison
  String getMonthlyCostDescription(PremiumPricing pricing, PlanType planType) {
    switch (planType) {
      case PlanType.monthly:
        return pricing.formattedMonthlyPrice;
      case PlanType.yearly:
        return pricing.formattedMonthlyCostOfYearly;
      case PlanType.threeYear:
        return pricing.formattedMonthlyCostOfThreeYear;
      case PlanType.lifetime:
        return 'One-time payment';
    }
  }

  // Get savings compared to monthly plan
  String getSavingsDescription(PremiumPricing pricing, PlanType planType) {
    switch (planType) {
      case PlanType.monthly:
        return '';
      case PlanType.yearly:
        return 'Save ${pricing.formattedYearlySavings} vs monthly';
      case PlanType.threeYear:
        return 'Save ${pricing.formattedThreeYearSavings} vs monthly';
      case PlanType.lifetime:
        return 'Save ${pricing.formattedLifetimeSavings} vs 10 years monthly';
    }
  }

  // Check if currency has special formatting rules
  bool usesCurrencyDecimals(String currencyCode) {
    return !['JPY', 'KRW', 'VND', 'IDR'].contains(currencyCode);
  }

  // Get all available plans with their benefits
  List<PlanDetails> getAllPlans(Currency userCurrency) {
    final pricing = getCurrentPricing(userCurrency);

    return [
      PlanDetails(
        type: PlanType.monthly,
        price: pricing.formattedMonthlyPrice,
        period: 'month',
        savings: '',
        monthlyCost: pricing.formattedMonthlyPrice,
        description: 'Perfect for trying premium features',
        badge: '',
        isPopular: false,
      ),
      PlanDetails(
        type: PlanType.yearly,
        price: pricing.formattedYearlyPrice,
        period: 'year',
        savings: 'Save ${pricing.yearlySavingsPercentage}%',
        monthlyCost: pricing.formattedMonthlyCostOfYearly,
        description: 'Most popular choice for regular users',
        badge: 'Most Popular',
        isPopular: true,
      ),
      PlanDetails(
        type: PlanType.threeYear,
        price: pricing.formattedThreeYearPrice,
        period: '3 years',
        savings: 'Save ${pricing.threeYearSavingsPercentage}%',
        monthlyCost: pricing.formattedMonthlyCostOfThreeYear,
        description: 'Best value for long-term users',
        badge: 'Best Value',
        isPopular: false,
      ),
      PlanDetails(
        type: PlanType.lifetime,
        price: pricing.formattedLifetimePrice,
        period: 'lifetime',
        savings: 'Save ${pricing.lifetimeSavingsPercentage}%',
        monthlyCost: 'One-time',
        description: 'Pay once, use forever',
        badge: 'Lifetime',
        isPopular: false,
      ),
    ];
  }
}

enum PlanType { monthly, yearly, threeYear, lifetime }

class PlanDetails {
  final PlanType type;
  final String price;
  final String period;
  final String savings;
  final String monthlyCost;
  final String description;
  final String badge;
  final bool isPopular;

  const PlanDetails({
    required this.type,
    required this.price,
    required this.period,
    required this.savings,
    required this.monthlyCost,
    required this.description,
    required this.badge,
    required this.isPopular,
  });

  String get planName {
    switch (type) {
      case PlanType.monthly:
        return 'Monthly';
      case PlanType.yearly:
        return 'Yearly';
      case PlanType.threeYear:
        return '3 Year';
      case PlanType.lifetime:
        return 'Lifetime';
    }
  }
}
