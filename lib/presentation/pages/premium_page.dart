import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/auto_backup_service.dart';
import '../../core/services/pricing_service.dart';
import '../../core/services/currency_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({Key? key}) : super(key: key);

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isLoading = false;
  bool _isPremium = false;
  PurchaseInfo? _purchaseInfo;
  List<PlanDetails> _availablePlans = [];
  String? _lastError;
  bool _showDebugInfo = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
    _checkPremiumStatus();
    _loadAvailablePlans();
  }

  Future<void> _initializeIAP() async {
    await IAPService.instance.initialize();
    setState(() {
      _lastError = IAPService.instance.lastError;
    });
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.instance.isPremiumUnlocked();
    final purchaseInfo = IAPService.instance.getPurchaseInfo();

    setState(() {
      _isPremium = isPremium;
      _purchaseInfo = purchaseInfo;
    });
  }

  void _loadAvailablePlans() {
    final userCurrency = CurrencyService.instance.currentCurrency;
    final plans = PricingService.instance.getAllPlans(userCurrency);

    setState(() {
      _availablePlans = plans;
    });
  }

  Future<void> _purchasePlan(PlanType planType) async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    PurchaseResult result;

    switch (planType) {
      case PlanType.monthly:
        result = await IAPService.instance.purchaseMonthlyPremium();
        break;
      case PlanType.yearly:
        result = await IAPService.instance.purchaseYearlyPremium();
        break;
      case PlanType.threeYear:
        result = await IAPService.instance.purchase3YearPremium();
        break;
      case PlanType.lifetime:
        result = await IAPService.instance.purchaseLifetimePremium();
        break;
    }

    if (result.isSuccess) {
      await _checkPremiumStatus();
      // Enable auto backup for premium users
      try {
        await AutoBackupService.instance.enableAutoBackup();
      } catch (e) {
        // Auto backup setup failed, but premium is still active
      }
      _showSuccessSnackBar(
        '🎉 Premium activated! Welcome to the premium experience!',
      );
    } else {
      setState(() {
        _lastError = result.message;
      });
      _showErrorDialog('Purchase Failed', result.message);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    await IAPService.instance.restorePurchases();
    await _checkPremiumStatus();

    if (_isPremium) {
      // Enable auto backup for restored premium users
      try {
        await AutoBackupService.instance.enableAutoBackup();
      } catch (e) {
        // Auto backup setup failed, but premium is still active
      }
      _showSuccessSnackBar('✅ Purchases restored successfully!');
    } else {
      _showErrorSnackBar('❌ No previous purchases found');
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                SizedBox(height: 16),
                Text(
                  'Troubleshooting tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Check your internet connection'),
                Text('• Make sure you\'re signed into Google Play'),
                Text('• Try restarting the app'),
                Text('• Contact support if the problem persists'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDebugDialog();
                },
                child: Text('Debug Info'),
              ),
            ],
          ),
    );
  }

  void _showDebugDialog() {
    final debugInfo = IAPService.instance.getDebugInfo();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Debug Information'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform: ${debugInfo['platform']}'),
                  Text('IAP Available: ${debugInfo['isAvailable']}'),
                  Text('Products Loaded: ${debugInfo['productsLoaded']}'),
                  Text('Purchase Pending: ${debugInfo['purchasePending']}'),
                  if (debugInfo['lastError'] != null)
                    Text('Last Error: ${debugInfo['lastError']}'),
                  SizedBox(height: 16),
                  Text(
                    'Products:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...((debugInfo['products'] as List).map(
                    (product) =>
                        Text('• ${product['id']}: ${product['price']}'),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('⭐ Premium'),
        centerTitle: true,
        actions: [
          if (!_isPremium)
            TextButton(
              onPressed: _isLoading ? null : _restorePurchases,
              child: Text('Restore', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
            icon: Icon(Icons.bug_report, size: 20),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showDebugInfo) _buildDebugSection(),
                    if (_lastError != null) _buildErrorSection(),
                    if (_isPremium)
                      _buildPremiumActiveSection()
                    else
                      _buildPremiumOfferSection(),
                    SizedBox(height: 24.h),
                    _buildFeatureComparison(),
                    SizedBox(height: 24.h),
                    if (!_isPremium) _buildPricingPlans(),
                  ],
                ),
              ),
    );
  }

  Widget _buildDebugSection() {
    final debugInfo = IAPService.instance.getDebugInfo();
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debug Info', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('IAP Available: ${debugInfo['isAvailable']}'),
          Text('Products: ${debugInfo['productsLoaded']}'),
          if (debugInfo['lastError'] != null)
            Text(
              'Error: ${debugInfo['lastError']}',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Issue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(_lastError!, style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showErrorDialog('Purchase Issue', _lastError!),
            child: Text('Help'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActiveSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.star, color: Colors.white, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'Premium Active! 🎉',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          if (_purchaseInfo != null) ...[
            Text(
              '${_purchaseInfo!.planType} Plan',
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            ),
            SizedBox(height: 4.h),
            if (!_purchaseInfo!.isLifetime) ...[
              Text(
                '${_purchaseInfo!.daysRemaining} days remaining',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
              Text(
                'Expires: ${_purchaseInfo!.formattedExpiryDate}',
                style: TextStyle(fontSize: 12.sp, color: Colors.white60),
              ),
            ] else
              Text(
                'Lifetime Access - No Expiry!',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              ),
          ],
          SizedBox(height: 16.h),
          Text(
            'Enjoy ad-free experience and automatic backups!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOfferSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.star_border, color: Colors.white, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Unlock premium features and support development',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s Included',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        _buildFeatureItem('🚫', 'No Ads', 'Enjoy uninterrupted experience'),
        _buildFeatureItem('☁️', 'Auto Backup', 'Daily automatic cloud backups'),
        _buildFeatureItem(
          '🗑️',
          'Advanced Features',
          'Trash bin, restore deleted transactions',
        ),
        _buildFeatureItem('🎨', 'Premium Themes', 'Beautiful custom themes'),
        _buildFeatureItem('📧', 'Priority Support', 'Get help faster'),
        _buildFeatureItem('💾', 'Data Export', 'Export your data anytime'),
      ],
    );
  }

  Widget _buildFeatureItem(String icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 24.sp)),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        ..._availablePlans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(PlanDetails plan) {
    final isPopular = plan.isPopular;
    final hasSpecialBadge = plan.badge.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPopular ? Colors.orange : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasSpecialBadge)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: isPopular ? Colors.orange : Colors.purple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Text(
                plan.badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          plan.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                        Text(
                          '/${plan.period}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (plan.type != PlanType.monthly) ...[
                  Row(
                    children: [
                      Icon(Icons.savings, size: 16.sp, color: Colors.green),
                      SizedBox(width: 4.w),
                      Text(
                        plan.savings,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],
                Row(
                  children: [
                    Icon(Icons.calculate, size: 16.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text(
                      '${plan.monthlyCost}/month equivalent',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _purchasePlan(plan.type),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.orange : Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Choose ${plan.planName}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
