import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'premium_service.dart';

class IAPService {
  static const String _premiumYearlyProductId = 'premium_yearly_750';
  static const String _premiumMonthlyProductId = 'premium_monthly_99';

  static IAPService? _instance;
  static IAPService get instance => _instance ??= IAPService._();
  IAPService._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  SharedPreferences? _prefs;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;

  ProductDetails? get yearlyProduct => _products.firstWhere(
    (product) => product.id == _premiumYearlyProductId,
    orElse: () => throw Exception('Yearly product not found'),
  );

  ProductDetails? get monthlyProduct => _products.firstWhere(
    (product) => product.id == _premiumMonthlyProductId,
    orElse: () => throw Exception('Monthly product not found'),
  );

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Check if in-app purchases are available
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      AppLogger.error('In-app purchases not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => AppLogger.error('Purchase stream error', error),
    );

    // Load products
    await _loadProducts();

    // Restore purchases for existing users
    await restorePurchases();

    AppLogger.info('IAP Service initialized successfully');
  }

  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      _premiumYearlyProductId,
      _premiumMonthlyProductId,
    };

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        AppLogger.error('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      AppLogger.info('Loaded ${_products.length} products');

      for (final product in _products) {
        AppLogger.info(
          'Product: ${product.id} - ${product.title} - ${product.price}',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to load products', e);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      _purchasePending = true;
      AppLogger.info('Purchase pending: ${purchaseDetails.productID}');
    } else {
      _purchasePending = false;

      if (purchaseDetails.status == PurchaseStatus.error) {
        AppLogger.error('Purchase error', purchaseDetails.error);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase and grant premium access
        await _verifyAndGrantPurchase(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndGrantPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // In a real app, you would verify the purchase with your server
      // For now, we'll grant access directly

      DateTime expiryDate;
      if (purchaseDetails.productID == _premiumYearlyProductId) {
        expiryDate = DateTime.now().add(Duration(days: 365));
        AppLogger.info('Granting yearly premium access');
      } else if (purchaseDetails.productID == _premiumMonthlyProductId) {
        expiryDate = DateTime.now().add(Duration(days: 30));
        AppLogger.info('Granting monthly premium access');
      } else {
        AppLogger.error('Unknown product ID: ${purchaseDetails.productID}');
        return;
      }

      // Grant premium access
      await PremiumService.instance.setPremiumUnlocked(true);
      await PremiumService.instance.setPremiumExpiryDate(expiryDate);

      // Store purchase info
      await _storePurchaseInfo(purchaseDetails, expiryDate);

      AppLogger.info('Premium access granted until: $expiryDate');
    } catch (e) {
      AppLogger.error('Failed to verify and grant purchase', e);
    }
  }

  Future<void> _storePurchaseInfo(
    PurchaseDetails purchaseDetails,
    DateTime expiryDate,
  ) async {
    await _prefs?.setString(
      'last_purchase_id',
      purchaseDetails.purchaseID ?? '',
    );
    await _prefs?.setString('last_product_id', purchaseDetails.productID);
    await _prefs?.setString(
      'premium_expiry_date',
      expiryDate.toIso8601String(),
    );
    await _prefs?.setString('purchase_date', DateTime.now().toIso8601String());
  }

  // Purchase methods
  Future<bool> purchaseYearlyPremium() async {
    return await _purchaseProduct(_premiumYearlyProductId);
  }

  Future<bool> purchaseMonthlyPremium() async {
    return await _purchaseProduct(_premiumMonthlyProductId);
  }

  Future<bool> _purchaseProduct(String productId) async {
    try {
      if (!_isAvailable) {
        AppLogger.error('In-app purchases not available');
        return false;
      }

      final product = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      AppLogger.info('Initiating purchase for: $productId');
      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      AppLogger.error('Purchase failed for $productId', e);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      if (!_isAvailable) return;

      AppLogger.info('Restoring purchases...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      AppLogger.error('Failed to restore purchases', e);
    }
  }

  // Get purchase info
  PurchaseInfo? getPurchaseInfo() {
    final purchaseId = _prefs?.getString('last_purchase_id');
    final productId = _prefs?.getString('last_product_id');
    final expiryDateString = _prefs?.getString('premium_expiry_date');
    final purchaseDateString = _prefs?.getString('purchase_date');

    if (purchaseId == null || productId == null || expiryDateString == null) {
      return null;
    }

    try {
      return PurchaseInfo(
        purchaseId: purchaseId,
        productId: productId,
        expiryDate: DateTime.parse(expiryDateString),
        purchaseDate:
            purchaseDateString != null
                ? DateTime.parse(purchaseDateString)
                : null,
      );
    } catch (e) {
      AppLogger.error('Failed to parse purchase info', e);
      return null;
    }
  }

  // Check if premium is active
  Future<bool> isPremiumActive() async {
    final purchaseInfo = getPurchaseInfo();
    if (purchaseInfo == null) return false;

    final isActive = DateTime.now().isBefore(purchaseInfo.expiryDate);

    // If premium expired, revoke access
    if (!isActive) {
      await PremiumService.instance.setPremiumUnlocked(false);
      await _clearExpiredPurchase();
    }

    return isActive;
  }

  Future<void> _clearExpiredPurchase() async {
    await _prefs?.remove('last_purchase_id');
    await _prefs?.remove('last_product_id');
    await _prefs?.remove('premium_expiry_date');
    await _prefs?.remove('purchase_date');
  }

  void dispose() {
    _subscription.cancel();
  }

  // Pricing helpers
  String get yearlyPrice {
    try {
      return yearlyProduct?.price ?? '₹750';
    } catch (e) {
      return '₹750';
    }
  }

  String get monthlyPrice {
    try {
      return monthlyProduct?.price ?? '₹99';
    } catch (e) {
      return '₹99';
    }
  }

  String get yearlySavings {
    // Calculate yearly savings compared to monthly
    try {
      final monthly = monthlyProduct;
      final yearly = yearlyProduct;

      if (monthly != null && yearly != null) {
        // This is simplified - in reality you'd parse the actual price values
        final monthlyCost = 99 * 12; // ₹99 x 12 months
        final yearlyCost = 750;
        final savings = monthlyCost - yearlyCost;
        return '₹$savings';
      }
    } catch (e) {
      // Fallback calculation
    }
    return '₹438'; // ₹99 x 12 - ₹750 = ₹438 savings
  }
}

class PurchaseInfo {
  final String purchaseId;
  final String productId;
  final DateTime expiryDate;
  final DateTime? purchaseDate;

  PurchaseInfo({
    required this.purchaseId,
    required this.productId,
    required this.expiryDate,
    this.purchaseDate,
  });

  bool get isActive => DateTime.now().isBefore(expiryDate);

  bool get isYearly => productId == IAPService._premiumYearlyProductId;

  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  String get formattedExpiryDate {
    return '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
  }
}
