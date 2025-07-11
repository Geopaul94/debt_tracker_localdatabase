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
  PremiumPricing? _currentPricing;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
    _checkPremiumStatus();
    _loadCurrentPricing();
  }

  Future<void> _initializeIAP() async {
    await IAPService.instance.initialize();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.instance.isPremiumUnlocked();
    final purchaseInfo = IAPService.instance.getPurchaseInfo();

    setState(() {
      _isPremium = isPremium;
      _purchaseInfo = purchaseInfo;
    });
  }

  void _loadCurrentPricing() {
    final userCurrency = CurrencyService.instance.currentCurrency;
    final pricing = PricingService.instance.getCurrentPricing(userCurrency);

    setState(() {
      _currentPricing = pricing;
    });
  }

  Future<void> _purchaseYearly() async {
    setState(() => _isLoading = true);

    final success = await IAPService.instance.purchaseYearlyPremium();

    if (success) {
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
      _showErrorSnackBar('❌ Purchase failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _purchaseMonthly() async {
    setState(() => _isLoading = true);

    final success = await IAPService.instance.purchaseMonthlyPremium();

    if (success) {
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
      _showErrorSnackBar('❌ Purchase failed. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

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
        duration: Duration(seconds: 3),
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
              onPressed: _restorePurchases,
              child: Text('Restore', style: TextStyle(color: Colors.white)),
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

  Widget _buildPremiumActiveSection() {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[600]!, Colors.purple[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Icon(Icons.star, size: 48.sp, color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              'Premium Active',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Thank you for supporting our app!',
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (_purchaseInfo != null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Plan:', style: TextStyle(color: Colors.white70)),
                        Text(
                          _purchaseInfo!.isYearly ? 'Yearly' : 'Monthly',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expires:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _purchaseInfo!.formattedExpiryDate,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Days remaining:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${_purchaseInfo!.daysRemaining} days',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumOfferSection() {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[600]!, Colors.purple[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Icon(Icons.star, size: 48.sp, color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),

            // Free Features Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎬 Free Option',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Watch one ad for 2 hours of ad-free usage',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Premium Support Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[800]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💝 Support Developer',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Help us continue building amazing features for you',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Reassurance Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sentiment_satisfied_alt,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '😊 No Pressure!',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Can\'t afford premium? No worries! Use all features with manual backup and occasional ads.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
            Text(
              'Unlock all features and enjoy an ad-free experience',
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Best Value',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow[300],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _currentPricing?.formattedYearlyPrice ?? '₹750',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'per year',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Save ${_currentPricing?.formattedSavings ?? '₹438'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        Text(
                          _currentPricing?.formattedMonthlyPrice ?? '₹99',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'per month',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features Comparison',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildFeatureRow(
              icon: Icons.delete_outline,
              title: 'Trash & Recovery',
              free: true,
              premium: true,
            ),
            _buildFeatureRow(
              icon: Icons.cloud_upload,
              title: 'Manual Cloud Backup',
              free: true,
              premium: true,
              freeNote: 'With ads',
            ),
            _buildFeatureRow(
              icon: Icons.backup,
              title: 'Automatic Daily Backup',
              free: false,
              premium: true,
            ),
            _buildFeatureRow(
              icon: Icons.ads_click,
              title: 'Ad-Free Experience',
              free: false,
              premium: true,
            ),
            _buildFeatureRow(
              icon: Icons.restore,
              title: 'Data Restore',
              free: true,
              premium: true,
              freeNote: 'With ads',
            ),
            _buildFeatureRow(
              icon: Icons.schedule,
              title: '15-Day Backup History',
              free: false,
              premium: true,
            ),
            _buildFeatureRow(
              icon: Icons.security,
              title: 'Priority Support',
              free: false,
              premium: true,
            ),
            _buildFeatureRow(
              icon: Icons.update,
              title: 'Early Access to Features',
              free: false,
              premium: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required bool free,
    required bool premium,
    String? freeNote,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[600], size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14.sp))),
          Container(
            width: 60.w,
            child: Column(
              children: [
                Icon(
                  free ? Icons.check : Icons.close,
                  color: free ? Colors.green : Colors.red,
                  size: 20.sp,
                ),
                if (freeNote != null && free)
                  Text(
                    freeNote,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Container(
            width: 60.w,
            child: Icon(
              premium ? Icons.check : Icons.close,
              color: premium ? Colors.green : Colors.red,
              size: 20.sp,
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
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),

        // Yearly Plan (Recommended)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Save ${_currentPricing?.formattedSavings ?? '₹438'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currentPricing?.formattedYearlyPrice ?? '₹750',
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        ' /year',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_currentPricing?.formattedMonthlyCostOfYearly ?? '₹62.5'}/month',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _purchaseYearly,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Get Yearly Premium',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Monthly Plan
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currentPricing?.formattedMonthlyPrice ?? '₹99',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      ' /month',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _purchaseMonthly,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: BorderSide(color: Colors.teal),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Get Monthly Premium',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Terms and conditions
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '• Payment will be charged to your Google Play account\n'
                '• Subscription automatically renews unless auto-renew is turned off\n'
                '• You can manage your subscription in Google Play Store\n'
                '• No refunds for unused time periods\n'
                '• Premium features are tied to your Google account',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
