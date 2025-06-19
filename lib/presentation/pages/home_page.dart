import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/services/ad_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/ad_banner_widget.dart';
import 'add_transaction_page.dart';
import 'transaction_history.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _transactionAddCount = 0; // Track for interstitial ads
  bool _isPremiumUnlocked = false;
  DateTime? _adFreeUntil;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debt Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'premium':
                  _showRewardedAdForPremium();
                  break;
                case 'ad_free':
                  _showRewardedAdForAdFree();
                  break;
                case 'analytics':
                  if (_isPremiumUnlocked) {
                    _showAdvancedAnalytics();
                  } else {
                    _showPremiumRequired();
                  }
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  if (!_isPremiumUnlocked)
                    PopupMenuItem(
                      value: 'premium',
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Unlock Premium'),
                        ],
                      ),
                    ),
                  if (!_isAdFree)
                    PopupMenuItem(
                      value: 'ad_free',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Remove Ads (2h)'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'analytics',
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color:
                              _isPremiumUnlocked ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('Advanced Analytics'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TransactionOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            // Show interstitial ad after every 3 transactions
            _transactionAddCount++;
            if (_transactionAddCount % 3 == 0) {
              _showInterstitialAd();
            }

            // Reload transactions after successful operation
            context.read<TransactionBloc>().add(LoadTransactionsEvent());
          }
        },
        builder: (context, state) {
          if (state is TransactionInitial) {
            // Start loading transactions on initial load
            context.read<TransactionBloc>().add(LoadTransactionsEvent());
            return Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoaded) {
            return _buildLoadedState(context, state);
          } else if (state is TransactionError) {
            return _buildErrorState(context, state);
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTransaction(context),
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, TransactionLoaded state) {
    return Column(
      children: [
        SummaryCard(
          totalIOwe: state.totalIOwe,
          totalOwesMe: state.totalOwesMe,
          netAmount: state.netAmount,
        ),
        // Add banner ad after summary card (only if not ad-free)
        if (!_isAdFree) AdBannerWidget(),
        Expanded(
          child:
              state.transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount:
                        state.transactions.length +
                        (state.transactions.length > 5 ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Insert another banner ad after every 5 transactions
                      if (index > 0 &&
                          index % 6 == 5 &&
                          state.transactions.length > 5 &&
                          !_isAdFree) {
                        return AdBannerWidget(
                          margin: EdgeInsets.symmetric(vertical: 16.h),
                        );
                      }

                      final transactionIndex = index > 5 ? index - 1 : index;
                      if (transactionIndex >= state.transactions.length) {
                        return SizedBox.shrink();
                      }

                      final transaction = state.transactions[transactionIndex];
                      return TransactionListItem(
                        transaction: transaction,
                        onTap:
                            () => _navigateToTransactionHistory(
                              context,
                              transaction,
                            ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to add your first transaction',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, TransactionError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<TransactionBloc>().add(LoadTransactionsEvent());
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTransaction(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (newContext) => AddTransactionPage()));
  }

  Future<void> _showInterstitialAd() async {
    try {
      await AdService.instance.showInterstitialAd();
    } catch (e) {
      print('Error showing interstitial ad: $e');
    }
  }

  Future<void> _showRewardedAdForPremium() async {
    try {
      await AdService.instance.showRewardedAd(
        onUserEarnedReward: (ad, reward) {
          setState(() {
            _isPremiumUnlocked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Premium features unlocked!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad not ready. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _showRewardedAdForAdFree() async {
    try {
      await AdService.instance.showRewardedAd(
        onUserEarnedReward: (ad, reward) {
          setState(() {
            _adFreeUntil = DateTime.now().add(Duration(hours: 2));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚀 Ads removed for 2 hours!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
    }
  }

  bool get _isAdFree {
    return _adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!);
  }

  void _showAdvancedAnalytics() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.analytics, color: Colors.green),
                SizedBox(width: 8),
                Text('Advanced Analytics'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Monthly Trends'),
                Text('📈 Spending Patterns'),
                Text('🎯 Debt Reduction Goals'),
                Text('📱 Export to PDF'),
                Text('☁️ Cloud Backup'),
              ],
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

  void _showPremiumRequired() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text('Premium Required'),
              ],
            ),
            content: Text(
              'Watch a short ad to unlock premium features including advanced analytics, export options, and more!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRewardedAdForPremium();
                },
                child: Text('Watch Ad'),
              ),
            ],
          ),
    );
  }

  void _navigateToTransactionHistory(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionHistoryPage(transaction: transaction),
      ),
    );
  }
}
