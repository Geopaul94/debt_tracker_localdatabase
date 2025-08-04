import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ad_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/preference_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/update_notification_service.dart';
import '../../core/utils/logger.dart';
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
import '../widgets/transaction_list_item.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/exit_confirmation_dialog.dart';

import 'add_transaction_page.dart';
import 'settings_page.dart';
import 'grouped_debt_detail_page.dart';
import 'premium_page.dart';
import 'transaction_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late CurrencyBloc _currencyBloc;
  bool _hasShownAppOpenAd = false;

  // Time-based interstitial ad system
  Timer? _interstitialAdTimer;
  static const Duration _interstitialAdInterval = Duration(
    minutes: 1,
    seconds: 30,
  ); // 1.5 minutes

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
        context.read<TransactionBloc>().add(const LoadTransactionsEvent());
      } catch (e) {
        print('Error loading transactions: $e');
      }
    });

    // Initialize ads in background after data loading
    _initializeAdsInBackground();

    // Show update notification if needed
    _showUpdateNotificationIfNeeded();

    // Start time-based interstitial ad timer
    _startInterstitialAdTimer();
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
    await Future.delayed(const Duration(milliseconds: 500));

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
    await Future.delayed(const Duration(milliseconds: 1000));

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

  // Handle app lifecycle changes for app open ads and interstitial timer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (!_hasShownAppOpenAd) {
        _showAppOpenAdIfNeeded();
      }
      // Resume interstitial ad timer when app comes to foreground
      _startInterstitialAdTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Pause interstitial ad timer when app goes to background
      _pauseInterstitialAdTimer();
    }
  }

  Future<void> _showAppOpenAdIfNeeded() async {
    if (_hasShownAppOpenAd) return;

    try {
      final success = await AdService.instance.showAppOpenAd();
      if (success) {
        _hasShownAppOpenAd = true;
        // Reset flag after some time to allow showing again later
        Timer(const Duration(minutes: 30), () {
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
    _interstitialAdTimer?.cancel(); // Clean up timer
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
            context.read<TransactionBloc>().add(const LoadTransactionsEvent());
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            if (didPop) return;
            final shouldExit = await _handleExitConfirmation();
            if (shouldExit && mounted) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Debt Tracker'),
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
                              const SizedBox(width: 8),
                              const Text('Settings'),
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
                        const PopupMenuItem(
                          value: 'ad_free',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Remove Ads (2h)'),
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
                  // Note: Success snackbar is handled by the Add Transaction page
                  // No need to show duplicate snackbar here

                  // Force reload to ensure immediate UI update
                  context.read<TransactionBloc>().add(
                    const LoadTransactionsEvent(),
                  );
                }
              },
              builder: (context, state) {
                // Handle initial state by triggering load
                if (state is TransactionInitial) {
                  context.read<TransactionBloc>().add(
                    const LoadTransactionsEvent(),
                  );
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TransactionLoaded) {
                  return _buildLoadedState(context, state);
                } else if (state is TransactionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TransactionBloc>().add(
                              const LoadTransactionsEvent(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToAddTransaction(),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
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
          // Dummy data banner
          if (state.isDummyData) _buildDummyDataBanner(),

          SummaryCard(
            totalIOwe: state.totalIOwe,
            totalOwesMe: state.totalOwesMe,
            netAmount: state.netAmount,
          ),

          const Row(
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
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemCount: _calculateItemCount(state.transactions.length),
                itemBuilder: (context, index) {
                  return _buildTransactionListItem(
                    context,
                    index,
                    state.transactions,
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildDummyDataBanner() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '📝 This is sample data to show you how the app works. It will automatically disappear when you add your first transaction.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Future<void> _showRewardedAdForAdFree() async {
    try {
      final connectivity = serviceLocator<ConnectivityService>();
      final hasInternet = await connectivity.checkInternetConnection();
      if (!hasInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await AdService.instance.showRewardedAd(
        allowDuringAdFree: true, // Allow extending ad-free time
        onUserEarnedReward: (ad, reward) async {
          if (mounted) {
            try {
              // Actually set the ad-free status
              await serviceLocator<PremiumService>().setAdFreeFor2Hours();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚀 Ads removed for 2 hours!'),
                  backgroundColor: Colors.green,
                ),
              );

              // Reload the page to reflect ad-free status
              setState(() {});
            } catch (e) {
              print('Error setting ad-free status: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Ad reward received!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load ad'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Time-based interstitial ad management
  void _startInterstitialAdTimer() {
    // Cancel existing timer if any
    _interstitialAdTimer?.cancel();

    // Start new timer for 1.5 minutes interval
    _interstitialAdTimer = Timer.periodic(_interstitialAdInterval, (timer) {
      _showInterstitialAdIfOnline();
    });

    print(
      '🕒 Interstitial ad timer started - showing ads every ${_interstitialAdInterval.inMinutes}:${(_interstitialAdInterval.inSeconds % 60).toString().padLeft(2, '0')}',
    );
  }

  void _pauseInterstitialAdTimer() {
    _interstitialAdTimer?.cancel();
    _interstitialAdTimer = null;
    print('⏸️ Interstitial ad timer paused');
  }

  // Calculate total item count including ads
  int _calculateItemCount(int transactionCount) {
    if (transactionCount <= 3)
      return transactionCount; // No ads for small lists

    int adCount = 0;
    // Native ad every 4 transactions (starting from position 4)
    adCount += (transactionCount / 4).floor();
    // Banner ad every 8 transactions (starting from position 8)
    if (transactionCount > 7) {
      adCount += ((transactionCount - 4) / 8).floor();
    }

    return transactionCount + adCount;
  }

  // Build transaction list item with integrated ads
  Widget _buildTransactionListItem(
    BuildContext context,
    int index,
    List<TransactionEntity> transactions,
  ) {
    final totalTransactions = transactions.length;

    // No ads for small lists
    if (totalTransactions <= 3) {
      if (index >= totalTransactions) return const SizedBox.shrink();
      return TransactionListItem(
        transaction: transactions[index],
        onTap: () => _navigateToTransactionDetail(context, transactions[index]),
      );
    }

    // Calculate ad positions
    final nativeAdPositions = <int>[];
    final bannerAdPositions = <int>[];

    // Native ads every 8 transactions (positions: 8, 16, 24...) - reduced frequency to prevent overload
    for (
      int i = 8;
      i <= totalTransactions + (totalTransactions / 8).floor();
      i += 8
    ) {
      nativeAdPositions.add(i);
    }

    // Banner ads every 12 transactions, offset to avoid native ads (positions: 12, 24, 36...)
    for (
      int i = 12;
      i <= totalTransactions + (totalTransactions / 12).floor();
      i += 12
    ) {
      if (!nativeAdPositions.contains(i)) {
        bannerAdPositions.add(i);
      }
    }

    // Check if this position should show a native ad
    if (nativeAdPositions.contains(index + 1)) {
      return FutureBuilder<bool>(
        future: _shouldShowBannerAd(), // Reuse same permission logic
        builder: (context, snapshot) {
          final shouldShowAd = snapshot.data ?? false;
          return shouldShowAd
              ? NativeAdWidget(
                key: ValueKey('native_ad_$index'), // Unique key for each ad
                template: TemplateType.medium,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                backgroundColor: Colors.white,
                height: 120,
              )
              : const SizedBox.shrink();
        },
      );
    }

    // Check if this position should show a banner ad
    if (bannerAdPositions.contains(index + 1)) {
      return FutureBuilder<bool>(
        future: _shouldShowBannerAd(),
        builder: (context, snapshot) {
          final shouldShowAd = snapshot.data ?? false;
          return shouldShowAd
              ? const AdBannerWidget()
              : const SizedBox.shrink();
        },
      );
    }

    // Calculate actual transaction index (accounting for ads)
    int transactionIndex = index;
    for (int adPos in nativeAdPositions) {
      if (index >= adPos) transactionIndex--;
    }
    for (int adPos in bannerAdPositions) {
      if (index >= adPos) transactionIndex--;
    }

    // Show transaction if within bounds
    if (transactionIndex >= 0 && transactionIndex < totalTransactions) {
      return TransactionListItem(
        transaction: transactions[transactionIndex],
        onTap:
            () => _navigateToTransactionDetail(
              context,
              transactions[transactionIndex],
            ),
      );
    }

    return const SizedBox.shrink();
  }

  void _navigateToAddTransaction() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddTransactionPage()));
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsPage()))
        .then((_) {
          // Refresh currency bloc when returning from settings
          _currencyBloc.add(LoadCurrentCurrencyEvent());
          // Reload transactions in case settings changed
          context.read<TransactionBloc>().add(const LoadTransactionsEvent());
        });
  }

  void _navigateToPremium() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PremiumPage()));
  }

  Future<bool> _handleExitConfirmation() async {
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ExitConfirmationDialog(),
      );
      return shouldExit ?? false;
    } catch (e) {
      debugPrint('Error showing exit confirmation dialog: $e');
      // Fallback to simple confirmation
      final shouldExit = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Exit App?'),
              content: const Text(
                'Are you sure you want to exit Debt Tracker?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.white),
                  ),
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
