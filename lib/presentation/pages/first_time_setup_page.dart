import 'package:debit_tracker/presentation/pages/currency_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/currencies.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/preference_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/currency_bloc/currency_bloc.dart';
import '../bloc/currency_bloc/currency_event.dart';
import '../bloc/currency_bloc/currency_state.dart';

class FirstTimeSetupPage extends StatefulWidget {
  FirstTimeSetupPage({Key? key}) : super(key: key);

  @override
  State<FirstTimeSetupPage> createState() => _FirstTimeSetupPageState();
}

class _FirstTimeSetupPageState extends State<FirstTimeSetupPage> {
  bool _isLoading = false;
  late CurrencyBloc _currencyBloc;

  @override
  void initState() {
    super.initState();
    _currencyBloc =
        serviceLocator<CurrencyBloc>()..add(LoadCurrentCurrencyEvent());
  }

  @override
  void dispose() {
    _currencyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocProvider.value(
        value: _currencyBloc,
        child: BlocListener<CurrencyBloc, CurrencyState>(
          listener: (context, state) {
            if (state is CurrencyChangedSuccess) {
              // Currency was changed successfully, UI will auto-update
            }
          },
          child: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),

                    // Welcome Header
                    Icon(
                      Icons.account_balance_wallet,
                      size: 80.sp,
                      color: Colors.teal[600],
                    ),
                    SizedBox(height: 24.h),

                    Text(
                      'Welcome to\nDebt Tracker',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      'Keep track of money you owe and money owed to you',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 20.h),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: Colors.teal[600],
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Choose Your Currency',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[800],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          Text(
                            'Select the currency you\'ll be using in the app:',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),

                          SizedBox(height: 10.h),

                          _buildCurrencyDropdown(),
                        ],
                      ),
                    ),
                    SizedBox(height: 15.h),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates,
                                color: Colors.orange[600],
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Quick Tip',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          Text(
                            '• Add transactions when you lend or borrow money\n'
                            '• Track who owes you and who you owe\n'
                            '• Get clear overview of your debt situation',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15.h),

                    // Data Storage Warning
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.red[200]!, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red[600],
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Important Warning',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          Text(
                            'This app uses local database storage. Your data is saved directly on your phone.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),

                          SizedBox(height: 8.h),

                          Text(
                            '⚠️ Do NOT uninstall the app or clear app data\n'
                            '⚠️ This will lead to permanent data loss\n'
                            '⚠️ All your transactions will be deleted forever',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.red[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Get Started Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 60.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        if (state is CurrencyLoaded) {
          final currentCurrency = state.currentCurrency;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: InkWell(
              onTap: () => _navigateToCurrencySelection(context),
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentCurrency.flag,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '${currentCurrency.name} (${currentCurrency.symbol})',
                        style: TextStyle(fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16.sp,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is CurrencyLoading) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          // Fallback to default
          final defaultCurrency = CurrencyConstants.defaultCurrency;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: InkWell(
              onTap: () => _navigateToCurrencySelection(context),
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      defaultCurrency.flag,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '${defaultCurrency.name} (${defaultCurrency.symbol})',
                        style: TextStyle(fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16.sp,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _navigateToCurrencySelection(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => CurrencySelectionPage()),
    );

    if (result == true) {
      // Currency was changed, refresh the bloc
      _currencyBloc.add(LoadCurrentCurrencyEvent());
    }
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mark first time setup as complete
      await PreferenceService.instance.setFirstLaunchCompleted();

      // Add sample transactions to demonstrate the app

      if (mounted) {
        // Navigate to home page
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Error completing setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up the app. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
