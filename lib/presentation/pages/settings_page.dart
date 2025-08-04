import 'package:debt_tracker/presentation/widgets/ad_banner_widget.dart';
import 'package:debt_tracker/presentation/widgets/native_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/trash_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/pricing_service.dart';

import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/currency_bloc/currency_bloc.dart';
import '../bloc/currency_bloc/currency_event.dart';
import '../bloc/currency_bloc/currency_state.dart';
import '../bloc/authentication/auth_bloc.dart';
import '../bloc/authentication/auth_event.dart';
import '../bloc/authentication/auth_state.dart';
import 'currency_selection_page.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';

import 'trash_page.dart';
import 'premium_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
                  serviceLocator<CurrencyBloc>()
                    ..add(LoadCurrentCurrencyEvent()),
        ),
        BlocProvider(
          create:
              (context) =>
                  serviceLocator<AuthBloc>()..add(LoadAuthSettingsEvent()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: ListView(
          padding: EdgeInsets.all(15.w),
          children: [
            _buildSectionHeader('Currency'),
            _buildCurrencyTile(context),

            SizedBox(height: 5.h),

            _buildSectionHeader('Premium Features'),

            _buildPremiumUnderDevelopment(),
            const AdBannerWidget(),

            // _buildSectionHeader('Hybrid Backup'),

            //    _buildPremiumTile(context),
            SizedBox(height: 15.h),

            SizedBox(height: 15.h),

            _buildSectionHeader('Data Management'),

            //  _buildCloudBackupTile(context),
            _buildCloudBackupUnderDevelopment(),

            _buildTrashTile(context),

            SizedBox(height: 15.h),

            NativeAdWidget(
              key: const ValueKey(
                'settings_native_ad',
              ), // Unique key for settings page
              template: TemplateType.medium,
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              backgroundColor: Colors.white,
              height: 100,
            ),

            _buildSectionHeader('Biometric Authentication'),
            _buildBiometricAuthentication(),

            SizedBox(height: 15.h),

            _buildSectionHeader('Privacy & Legal'),
            _buildPrivacyPolicyTile(context),
            _buildTermsConditionsTile(context),

            SizedBox(height: 15.h),
            const AdBannerWidget(),
            _buildSectionHeader('About'),
            _buildAppInfoTile(),
            _buildwithlove(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: Colors.teal[800],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        if (state is CurrencyLoaded) {
          final currentCurrency = state.currentCurrency;
          return Card(
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.monetization_on, color: Colors.teal[600]),
              ),
              title: const Text('Currency'),
              subtitle: Text(
                '${currentCurrency.flag} ${currentCurrency.name} (${currentCurrency.symbol})',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const CurrencySelectionPage(),
                      ),
                    )
                    .then((currencyChanged) {
                      if (currencyChanged == true) {
                        // Reload transactions to update currency formatting
                        context.read<TransactionBloc>().add(
                          const LoadTransactionsEvent(),
                        );
                        // Refresh currency bloc
                        context.read<CurrencyBloc>().add(
                          LoadCurrentCurrencyEvent(),
                        );
                      }
                    });
              },
            ),
          );
        } else {
          // Fallback when loading or error
          final currentCurrency = CurrencyService.instance.currentCurrency;
          return Card(
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.monetization_on, color: Colors.teal[600]),
              ),
              title: const Text('Currency'),
              subtitle: Text(
                '${currentCurrency.flag} ${currentCurrency.name} (${currentCurrency.symbol})',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const CurrencySelectionPage(),
                      ),
                    )
                    .then((currencyChanged) {
                      if (currencyChanged == true) {
                        // Reload transactions to update currency formatting
                        context.read<TransactionBloc>().add(
                          const LoadTransactionsEvent(),
                        );
                        // Refresh currency bloc
                        context.read<CurrencyBloc>().add(
                          LoadCurrentCurrencyEvent(),
                        );
                      }
                    });
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildAppInfoTile() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.info, color: Colors.purple[600]),
        ),
        title: const Text('App Information'),
        subtitle: const Text('Version 1.0.0'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAppInfoDialog(),
      ),
    );
  }

  void _showAppInfoDialog() {
    // You can implement this to show app information
  }

  Widget _buildBiometricAuthentication() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSettingsLoaded) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.teal[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.fingerprint, color: Colors.teal[600]),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biometric Lock',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Secure your data with Face ID, Touch ID, or PIN',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.isEnabled,
                        onChanged:
                            state.isBiometricAvailable
                                ? (value) {
                                  if (value) {
                                    context.read<AuthBloc>().add(
                                      EnableAuthEvent(),
                                    );
                                  } else {
                                    context.read<AuthBloc>().add(
                                      DisableAuthEvent(),
                                    );
                                  }
                                }
                                : null,
                        activeColor: Colors.teal[600],
                      ),
                    ],
                  ),
                  if (!state.isBiometricAvailable)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[600],
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Biometric authentication is not available on this device',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        } else if (state is AuthLoading) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.fingerprint, color: Colors.teal[600]),
                  ),
                  SizedBox(width: 16.w),
                  const Text('Loading...'),
                  const Spacer(),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        } else {
          return Card(
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.fingerprint, color: Colors.teal[600]),
              ),
              title: const Text('Biometric Authentication'),
              subtitle: const Text('Tap to configure'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.read<AuthBloc>().add(LoadAuthSettingsEvent());
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildPrivacyPolicyTile(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.privacy_tip, color: Colors.blue[600]),
        ),
        title: const Text('Privacy Policy'),
        subtitle: const Text('View our privacy policy and data usage'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
          );
        },
      ),
    );
  }

  Widget _buildTermsConditionsTile(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.description, color: Colors.green[600]),
        ),
        title: const Text('Terms & Conditions'),
        subtitle: const Text('View our terms of service and usage agreement'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TermsConditionsPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumTile(BuildContext context) {
    return FutureBuilder<bool>(
      future: PremiumService.instance.isPremiumUnlocked(),
      builder: (context, snapshot) {
        final isPremium = snapshot.data ?? false;
        final userCurrency = CurrencyService.instance.currentCurrency;
        final pricing = PricingService.instance.getCurrentPricing(userCurrency);

        return Card(
          child: ListTile(
            leading: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isPremium ? Colors.purple[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                isPremium ? Icons.star : Icons.star_border,
                color: isPremium ? Colors.purple[600] : Colors.orange[600],
              ),
            ),
            title: Text(isPremium ? 'Premium Active' : 'Upgrade to Premium'),
            subtitle: Text(
              isPremium
                  ? 'Ad-free experience & automatic backups'
                  : 'Starting from ${pricing.formattedYearlyPrice}/year',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PremiumPage()),
              );
            },
          ),
        );
      },
    );
  }

  // Widget _buildCloudBackupTile(BuildContext context) {
  //   return Card(
  //     child: ListTile(
  //       leading: Container(
  //         width: 40.w,
  //         height: 40.w,
  //         decoration: BoxDecoration(
  //           color: Colors.blue[100],
  //           borderRadius: BorderRadius.circular(8.r),
  //         ),
  //         child: Icon(Icons.cloud_upload, color: Colors.blue[600]),
  //       ),
  //       title: Text('Cloud Backup'),
  //       subtitle: Text('Backup your data locally'),
  //       trailing: Icon(Icons.chevron_right),
  //       onTap: () {
  //         Navigator.of(
  //           context,
  //         ).push(MaterialPageRoute(builder: (context) => CloudBackupPage()));
  //         //HybridBackupPage()));
  //       },
  //     ),
  //   );
  // }

  Widget _buildTrashTile(BuildContext context) {
    return FutureBuilder<int>(
      future: TrashService.instance.getTrashCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Card(
          child: ListTile(
            leading: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.delete, color: Colors.red[600]),
            ),
            title: const Text('Trash'),
            subtitle: Text(
              count > 0
                  ? '$count deleted items (kept for 30 days)'
                  : 'Deleted items will appear here',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TrashPage()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildwithlove() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Build with ❤️ by GP',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          Text(
            'Version 1.4.0',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            'Copyright 2025',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            'All rights reserved',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUnderDevelopment() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.info, color: Colors.purple[600]),
        ),
        title: const Text('Premium Features'),
        subtitle: const Text('Coming Soon'),
        //   trailing: Icon(Icons.chevron_right),
        onTap: () => _showAppInfoDialog(),
      ),
    );
  }

  Widget _buildCloudBackupUnderDevelopment() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.info, color: Colors.purple[600]),
        ),
        title: const Text('Cloud Backup'),
        subtitle: const Text('Coming Soon'),
        // trailing: Icon(Icons.chevron_right),
        onTap: () => _showAppInfoDialog(),
      ),
    );
  }
}
