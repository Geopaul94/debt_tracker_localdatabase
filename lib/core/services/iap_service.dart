import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'premium_service.dart';

class IAPService {
  // Updated product IDs with new plans
  static const String _premiumMonthlyProductId = 'premium_monthly_90';
  static const String _premiumYearlyProductId = 'premium_yearly_750';
  static const String _premium3YearProductId = 'premium_3year_1250';
  static const String _premiumLifetimeProductId = 'premium_lifetime_2000';

  static IAPService? _instance;
  static IAPService get instance => _instance ??= IAPService._();
  IAPService._();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  SharedPreferences? _prefs;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _lastError;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get lastError => _lastError;

  ProductDetails? get monthlyProduct =>
      _products
          .where((product) => product.id == _premiumMonthlyProductId)
          .firstOrNull;

  ProductDetails? get yearlyProduct =>
      _products
          .where((product) => product.id == _premiumYearlyProductId)
          .firstOrNull;

  ProductDetails? get threeYearProduct =>
      _products
          .where((product) => product.id == _premium3YearProductId)
          .firstOrNull;

  ProductDetails? get lifetimeProduct =>
      _products
          .where((product) => product.id == _premiumLifetimeProductId)
          .firstOrNull;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _lastError = null;

    try {
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        _lastError = 'In-app purchases not available on this device';
        AppLogger.error(_lastError!);
        return;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          _lastError = 'Purchase stream error: $error';
          AppLogger.error(_lastError!, error);
        },
      );

      // Load products
      await _loadProducts();

      // Check for any pending purchases
      await _checkPendingPurchases();

      // Restore purchases for existing users
      await restorePurchases();

      AppLogger.info(
        'IAP Service initialized successfully with ${_products.length} products',
      );
    } catch (e) {
      _lastError = 'IAP initialization failed: $e';
      AppLogger.error(_lastError!, e);
    }
  }

  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      _premiumMonthlyProductId,
      _premiumYearlyProductId,
      _premium3YearProductId,
      _premiumLifetimeProductId,
    };

    try {
      AppLogger.info('Loading products: $productIds');
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        _lastError =
            'Products not found in Play Console: ${response.notFoundIDs}';
        AppLogger.error(_lastError!);
      }

      _products = response.productDetails;
      AppLogger.info('Loaded ${_products.length} products successfully');

      for (final product in _products) {
        AppLogger.info(
          'Product loaded: ${product.id} - ${product.title} - ${product.price}',
        );
      }

      if (_products.isEmpty) {
        _lastError =
            'No products found. Please check Play Console configuration.';
        AppLogger.error(_lastError!);
      }
    } catch (e) {
      _lastError = 'Failed to load products: $e';
      AppLogger.error(_lastError!, e);
    }
  }

  Future<void> _checkPendingPurchases() async {
    try {
      // Check for any pending purchases that weren't completed
      AppLogger.info('Checking for pending purchases...');
    } catch (e) {
      AppLogger.error('Error checking pending purchases', e);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    AppLogger.info(
      'Purchase update received: ${purchaseDetailsList.length} items',
    );
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    AppLogger.info(
      'Handling purchase: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}',
    );

    if (purchaseDetails.status == PurchaseStatus.pending) {
      _purchasePending = true;
      AppLogger.info('Purchase pending: ${purchaseDetails.productID}');
    } else {
      _purchasePending = false;

      if (purchaseDetails.status == PurchaseStatus.error) {
        _lastError =
            'Purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}';
        AppLogger.error(_lastError!, purchaseDetails.error);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase and grant premium access
        await _verifyAndGrantPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _lastError = 'Purchase was canceled by user';
        AppLogger.info(_lastError!);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchaseDetails);
          AppLogger.info('Purchase completed: ${purchaseDetails.productID}');
        } catch (e) {
          AppLogger.error('Failed to complete purchase', e);
        }
      }
    }
  }

  Future<void> _verifyAndGrantPurchase(PurchaseDetails purchaseDetails) async {
    try {
      AppLogger.info(
        'Verifying and granting purchase: ${purchaseDetails.productID}',
      );

      // In a real app, you would verify the purchase with your server
      // For now, we'll grant access directly

      DateTime expiryDate;
      if (purchaseDetails.productID == _premiumMonthlyProductId) {
        expiryDate = DateTime.now().add(const Duration(days: 30));
        AppLogger.info('Granting monthly premium access (30 days)');
      } else if (purchaseDetails.productID == _premiumYearlyProductId) {
        expiryDate = DateTime.now().add(const Duration(days: 365));
        AppLogger.info('Granting yearly premium access (365 days)');
      } else if (purchaseDetails.productID == _premium3YearProductId) {
        expiryDate = DateTime.now().add(const Duration(days: 365 * 3));
        AppLogger.info('Granting 3-year premium access (1095 days)');
      } else if (purchaseDetails.productID == _premiumLifetimeProductId) {
        expiryDate = DateTime.now().add(
          const Duration(days: 365 * 100),
        ); // 100 years = lifetime
        AppLogger.info('Granting lifetime premium access');
      } else {
        _lastError = 'Unknown product ID: ${purchaseDetails.productID}';
        AppLogger.error(_lastError!);
        return;
      }

      // Grant premium access
      await PremiumService.instance.setPremiumUnlocked(true);
      await PremiumService.instance.setPremiumExpiryDate(expiryDate);

      // Store purchase info
      await _storePurchaseInfo(purchaseDetails, expiryDate);

      AppLogger.info('Premium access granted until: $expiryDate');
      _lastError = null; // Clear any previous errors
    } catch (e) {
      _lastError = 'Failed to verify and grant purchase: $e';
      AppLogger.error(_lastError!, e);
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

  // Purchase methods with enhanced error handling
  Future<PurchaseResult> purchaseMonthlyPremium() async {
    return await _purchaseProductWithRetry(_premiumMonthlyProductId);
  }

  Future<PurchaseResult> purchaseYearlyPremium() async {
    return await _purchaseProductWithRetry(_premiumYearlyProductId);
  }

  Future<PurchaseResult> purchase3YearPremium() async {
    return await _purchaseProductWithRetry(_premium3YearProductId);
  }

  Future<PurchaseResult> purchaseLifetimePremium() async {
    return await _purchaseProductWithRetry(_premiumLifetimeProductId);
  }

  Future<PurchaseResult> _purchaseProductWithRetry(
    String productId, {
    int retryCount = 0,
  }) async {
    try {
      AppLogger.info(
        'Attempting purchase for: $productId (attempt ${retryCount + 1})',
      );

      if (!_isAvailable) {
        return PurchaseResult.failure(
          'In-app purchases not available on this device. Please check your Play Store settings.',
        );
      }

      if (_products.isEmpty) {
        await _loadProducts(); // Try to reload products
        if (_products.isEmpty) {
          return PurchaseResult.failure(
            'No products available. Please check your internet connection and try again.',
          );
        }
      }

      final product =
          _products.where((product) => product.id == productId).firstOrNull;
      if (product == null) {
        return PurchaseResult.failure(
          'Product not found: $productId. Please contact support.',
        );
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      AppLogger.info(
        'Initiating purchase for: ${product.title} - ${product.price}',
      );
      final bool purchaseStarted = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (purchaseStarted) {
        return PurchaseResult.success('Purchase initiated successfully');
      } else {
        return PurchaseResult.failure(
          'Failed to start purchase process. Please try again.',
        );
      }
    } catch (e) {
      _lastError = 'Purchase failed for $productId: $e';
      AppLogger.error(_lastError!, e);

      // Retry logic for network errors
      if (retryCount < 2 &&
          (e.toString().contains('network') ||
              e.toString().contains('timeout'))) {
        AppLogger.info('Retrying purchase due to network error...');
        await Future.delayed(const Duration(seconds: 2));
        return await _purchaseProductWithRetry(
          productId,
          retryCount: retryCount + 1,
        );
      }

      return PurchaseResult.failure(_getHumanReadableError(e.toString()));
    }
  }

  String _getHumanReadableError(String error) {
    if (error.contains('network') || error.contains('timeout')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (error.contains('user_cancelled') || error.contains('canceled')) {
      return 'Purchase was canceled.';
    } else if (error.contains('billing_unavailable')) {
      return 'Billing service is unavailable. Please update Google Play Store.';
    } else if (error.contains('item_unavailable')) {
      return 'This product is currently unavailable. Please try again later.';
    } else if (error.contains('developer_error')) {
      return 'App configuration error. Please contact support.';
    } else if (error.contains('item_already_owned')) {
      return 'You already own this product. Try restoring purchases.';
    } else {
      return 'Purchase failed. Please try again or contact support.';
    }
  }

  Future<void> restorePurchases() async {
    try {
      if (!_isAvailable) return;

      AppLogger.info('Restoring purchases...');
      await _inAppPurchase.restorePurchases();
      AppLogger.info('Restore purchases completed');
    } catch (e) {
      _lastError = 'Failed to restore purchases: $e';
      AppLogger.error(_lastError!, e);
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

  // Pricing helpers for backward compatibility
  String get yearlyPrice {
    try {
      return yearlyProduct?.price ?? '₹750';
    } catch (e) {
      return '₹750';
    }
  }

  String get monthlyPrice {
    try {
      return monthlyProduct?.price ?? '₹90';
    } catch (e) {
      return '₹90';
    }
  }

  String get threeYearPrice {
    try {
      return threeYearProduct?.price ?? '₹1250';
    } catch (e) {
      return '₹1250';
    }
  }

  String get lifetimePrice {
    try {
      return lifetimeProduct?.price ?? '₹2000';
    } catch (e) {
      return '₹2000';
    }
  }

  // Get system info for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAvailable': _isAvailable,
      'productsLoaded': _products.length,
      'lastError': _lastError,
      'purchasePending': _purchasePending,
      'platform':
          Platform.isAndroid
              ? 'Android'
              : Platform.isIOS
              ? 'iOS'
              : 'Unknown',
      'products':
          _products
              .map((p) => {'id': p.id, 'title': p.title, 'price': p.price})
              .toList(),
    };
  }
}

class PurchaseResult {
  final bool isSuccess;
  final String message;

  PurchaseResult._(this.isSuccess, this.message);

  factory PurchaseResult.success(String message) =>
      PurchaseResult._(true, message);
  factory PurchaseResult.failure(String message) =>
      PurchaseResult._(false, message);
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
  bool get isMonthly => productId == IAPService._premiumMonthlyProductId;
  bool get is3Year => productId == IAPService._premium3YearProductId;
  bool get isLifetime => productId == IAPService._premiumLifetimeProductId;

  String get planType {
    if (isLifetime) return 'Lifetime';
    if (is3Year) return '3 Year';
    if (isYearly) return 'Yearly';
    if (isMonthly) return 'Monthly';
    return 'Unknown';
  }

  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  String get formattedExpiryDate {
    return '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
  }
}
