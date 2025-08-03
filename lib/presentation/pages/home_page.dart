import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/preference_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/update_notification_service.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/transaction_sqlite_data_source.dart';
import '../../domain/entities/grouped_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/transacton_bloc/transaction_state.dart';
import '../bloc/currency_bloc/currency_bloc.dart';
import '../bloc/currency_bloc/currency_event.dart';
import '../bloc/currency_bloc/currency_state.dart';
import '../widgets/summary_card.dart';
import '../widgets/grouped_transaction_list_item.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/exit_confirmation_dialog.dart';
import 'add_transaction_page.dart';
import 'settings_page.dart';
import 'grouped_debt_detail_page.dart';
import 'premium_page.dart';
import 'transaction_detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _transactionAddCount = 0;
  late CurrencyBloc _currencyBloc;
  bool _hasShownAppOpenAd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Safely initialize CurrencyBloc with error handling
    try {
      _currencyBloc = serviceLocator<CurrencyBloc>();
      _currencyBloc.add(LoadCurrentCurrencyEvent());
    } catch (e) {
      print('Error initializing CurrencyBloc: $e');
      // Create a fallback or handle gracefully
    }

    // Load transactions when home page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TransactionBloc>().add(LoadTransactionsEvent());
      } catch (e) {
        print('Error loading transactions: $e');
      }
    });

    // Initialize ads in background after data loading
    _initializeAdsInBackground();

    // Show update notification if needed
    _showUpdateNotificationIfNeeded();
  }

  // Track app session
  Future<void> _trackAppSession() async {
    try {
      await PreferenceService.instance.incrementAppSession();
      print('App session tracked');
    } catch (e) {
      print('Error tracking app session: $e');
    }
  }

  // Initialize ads in background to avoid blocking UI
  Future<void> _initializeAdsInBackground() async {
    // Wait for a short delay to let the UI render first
    await Future.delayed(Duration(milliseconds: 500));

    try {
      // Initialize ad service asynchronously
      await AdService.instance.initialize();
      print('Ads initialized in background');
    } catch (e) {
      print('Error initializing ads: $e');
    }
  }

  // Show update notification if needed
  Future<void> _showUpdateNotificationIfNeeded() async {
    // Wait for the UI to render first
    await Future.delayed(Duration(milliseconds: 1000));

    try {
      await UpdateNotificationService.instance.initialize();
      if (mounted) {
        await UpdateNotificationService.instance.showUpdateNotification(
          context,
        );
      }
    } catch (e) {
      print('Error showing update notification: $e');
    }
  }

  // Handle app lifecycle changes for app open ads
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && !_hasShownAppOpenAd) {
      _showAppOpenAdIfNeeded();
    }
  }

  Future<void> _showAppOpenAdIfNeeded() async {
    if (_hasShownAppOpenAd) return;

    try {
      final success = await AdService.instance.showAppOpenAd();
      if (success) {
        _hasShownAppOpenAd = true;
        // Reset flag after some time to allow showing again later
        Timer(Duration(minutes: 30), () {
          _hasShownAppOpenAd = false;
        });
      }
    } catch (e) {
      print('Error showing app open ad: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currencyBloc.close();
    super.dispose();
  }

  // Group transactions by date
  List<GroupedTransactionEntity> _groupTransactionsByDate(
    List<TransactionEntity> transactions,
  ) {
    final Map<String, List<TransactionEntity>> grouped = {};

    for (final transaction in transactions) {
      final dateKey = transaction.date.toIso8601String().split('T')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped.entries.map((entry) {
      final transactions = entry.value;
      final userName = transactions.first.name;

      return GroupedTransactionEntity.fromTransactions(userName, transactions);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: _currencyBloc)],
      child: BlocListener<CurrencyBloc, CurrencyState>(
        listener: (context, currencyState) {
          if (currencyState is CurrencyChangedSuccess) {
            // Currency changed, reload transactions to update formatting
            context.read<TransactionBloc>().add(LoadTransactionsEvent());
          }
        },
        child: WillPopScope(
          onWillPop: _handleExitConfirmation,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Debt Tracker'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'settings':
                        _navigateToSettings();
                        break;
                      case 'premium':
                        _navigateToPremium();
                        break;
                      case 'ad_free':
                        _showRewardedAdForAdFree();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text('Settings'),
                            ],
                          ),
                        ),
                        // PopupMenuItem(
                        //   value: 'premium',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.star, color: Colors.amber),
                        //       SizedBox(width: 8),
                        //       Text('Get Premium'),
                        //     ],
                        //   ),
                        // ),

                        // PopupMenuItem(
                        //   value: 'ad_free',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.block, color: Colors.blue),
                        //       SizedBox(width: 8),
                        //       Text('Remove Ads (2h)'),
                        //     ],
                        //   ),
                        // ),
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
                  // Note: Success snackbar is handled by the Add Transaction page
                  // No need to show duplicate snackbar here

                  // Show interstitial ad after every 3 transactions (only if online)
                  _transactionAddCount++;
                  if (_transactionAddCount % 3 == 0) {
                    _showInterstitialAdIfOnline();
                  }

                  // Force reload to ensure immediate UI update
                  context.read<TransactionBloc>().add(LoadTransactionsEvent());
                }
              },
              builder: (context, state) {
                // Handle initial state by triggering load
                if (state is TransactionInitial) {
                  context.read<TransactionBloc>().add(LoadTransactionsEvent());
                  return Center(child: CircularProgressIndicator());
                } else if (state is TransactionLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is TransactionLoaded) {
                  return _buildLoadedState(context, state);
                } else if (state is TransactionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(state.message),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TransactionBloc>().add(
                              LoadTransactionsEvent(),
                            );
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToAddTransaction(),
              backgroundColor: Colors.teal,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, TransactionLoaded state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SummaryCard(
            totalIOwe: state.totalIOwe,
            totalOwesMe: state.totalOwesMe,
            netAmount: state.netAmount,
          ),

          Row(
            children: [
              SizedBox(width: 20),
              Icon(Icons.receipt_long, size: 24),
              SizedBox(width: 8),
              Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Add banner ad after summary card (only if not ad-free and after 7 days)
          FutureBuilder<bool>(
            future: _shouldShowBannerAd(),
            builder: (context, snapshot) {
              final shouldShowAd = snapshot.data ?? false;
              return shouldShowAd
                  ? const AdBannerWidget()
                  : const SizedBox.shrink();
            },
          ),
          state.transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemCount:
                    state.transactions.length +
                    (state.transactions.length > 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  // Insert another banner ad after every 5 transactions
                  if (index > 0 &&
                      index % 6 == 5 &&
                      state.transactions.length > 5) {
                    return FutureBuilder<bool>(
                      future: _shouldShowBannerAd(),
                      builder: (context, snapshot) {
                        final shouldShowAd = snapshot.data ?? false;
                        return shouldShowAd
                            ? AdBannerWidget(
                              margin: EdgeInsets.symmetric(vertical: 16.h),
                            )
                            : SizedBox.shrink();
                      },
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
                        () =>
                            _navigateToTransactionDetail(context, transaction),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 130.h),
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

  // Helper method to safely check if PremiumService is available
  bool _isPremiumServiceAvailable() {
    try {
      serviceLocator<PremiumService>();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _shouldShowBannerAd() async {
    try {
      // Check if user has premium
      final premiumService = serviceLocator<PremiumService>();
      final isPremium = await premiumService.isPremiumUnlocked();
      if (isPremium) return false;

      // Check if ads are enabled
      final shouldShowAds = await PreferenceService.instance.shouldShowAds();
      if (!shouldShowAds) return false;

      // Check connectivity
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();
      if (!hasInternet) return false;

      return true;
    } catch (e) {
      print('Error checking banner ad conditions: $e');
      return false;
    }
  }

  Future<void> _showInterstitialAd() async {
    try {
      await AdService.instance.showInterstitialAd();
    } catch (e) {
      AppLogger.error('Error showing interstitial ad', e);
    }
  }

  Future<void> _showInterstitialAdIfOnline() async {
    try {
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();
      if (!hasInternet) return;

      final premiumService = serviceLocator<PremiumService>();
      final isPremium = await premiumService.isPremiumUnlocked();
      if (isPremium) return;

      await AdService.instance.showInterstitialAd();
    } catch (e) {
      print('Error showing interstitial ad: $e');
    }
  }

  Future<void> _showRewardedAdForPremium() async {
    try {
      await AdService.instance.showRewardedAd(
        onUserEarnedReward: (ad, reward) async {
          if (mounted) {
            if (_isPremiumServiceAvailable()) {
              try {
                await serviceLocator<PremiumService>().setPremiumUnlocked(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Premium features unlocked!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                AppLogger.error('Error setting premium status', e);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Ad reward received!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Ad reward received!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            // Refresh the page to update UI
            setState(() {});
          }
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad not ready. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showRewardedAdForAdFree() async {
    try {
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();
      if (!hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await AdService.instance.showRewardedAd(
        onUserEarnedReward: (ad, reward) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ads removed for 2 hours!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load ad'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddTransaction() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AddTransactionPage()));
  }

  void _navigateToTransactionDetail(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailPage(transaction: transaction),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SettingsPage())).then((_) {
      // Refresh currency bloc when returning from settings
      _currencyBloc.add(LoadCurrentCurrencyEvent());
      // Reload transactions in case settings changed
      context.read<TransactionBloc>().add(LoadTransactionsEvent());
    });
  }

  void _navigateToPremium() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PremiumPage()));
  }

  Future<bool> _handleExitConfirmation() async {
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExitConfirmationDialog(),
      );
      return shouldExit ?? false;
    } catch (e) {
      print('Error showing exit confirmation dialog: $e');
      // Fallback to simple confirmation
      final shouldExit = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Exit App?'),
              content: Text('Are you sure you want to exit Debt Tracker?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Exit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
      );
      return shouldExit ?? false;
    }
  }

  void _navigateToDebtDetail(
    BuildContext context,
    GroupedTransactionEntity groupedTransaction,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                GroupedDebtDetailPage(groupedTransaction: groupedTransaction),
      ),
    );
  }
}
