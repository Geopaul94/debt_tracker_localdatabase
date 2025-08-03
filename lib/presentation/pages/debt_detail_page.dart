import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/currency_service.dart';
import '../../core/constants/currencies.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/transacton_bloc/transaction_state.dart';
import '../widgets/ad_banner_widget.dart';
import 'add_transaction_page.dart';
import 'transaction_history.dart';

class DebtDetailPage extends StatefulWidget {
  final TransactionType type;

  const DebtDetailPage({super.key, required this.type});

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  List<TransactionEntity> _transactions = [];
  final Map<String, List<TransactionEntity>> _groupedTransactions = {};
  final Map<String, double> _personTotals = {};

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
  }

  void _processTransactions(List<TransactionEntity> allTransactions) {
    // Filter transactions by type
    _transactions =
        allTransactions.where((t) => t.type == widget.type).toList();

    // Sort by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    // Group by person
    _groupedTransactions.clear();
    _personTotals.clear();

    for (final transaction in _transactions) {
      final name = transaction.name;
      if (!_groupedTransactions.containsKey(name)) {
        _groupedTransactions[name] = [];
        _personTotals[name] = 0.0;
      }
      _groupedTransactions[name]!.add(transaction);
      _personTotals[name] = _personTotals[name]! + transaction.amount;
    }
  }

  Map<String, double> _getCurrencyBreakdown() {
    final breakdown = <String, double>{};
    for (final transaction in _transactions) {
      final currencyCode = transaction.currency.code;
      breakdown[currencyCode] =
          (breakdown[currencyCode] ?? 0.0) + transaction.amount;
    }
    return breakdown;
  }

  double _getTotalInDefaultCurrency() {
    // Include all transactions and treat amounts as equivalent in default currency
    // In a real app, you'd use exchange rates here
    return _transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Widget _buildCurrencyBreakdown(
    Map<String, double> breakdown,
    MaterialColor color,
  ) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
                Icons.account_balance_wallet,
                color: color[600],
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Breakdown by Currency',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          FutureBuilder<List<Currency>>(
            future: CurrencyConstants.supportedCurrencies,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Text('Error loading currencies'),
                );
              }

              final currencies = snapshot.data!;
              return Column(
                children:
                    breakdown.entries.map((entry) {
                      final currencyCode = entry.key;
                      final amount = entry.value;
                      final currency = currencies.firstWhere(
                        (c) => c.code == currencyCode,
                        orElse: () => CurrencyConstants.defaultCurrency,
                      );

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Text(
                              currency.flag,
                              style: TextStyle(fontSize: 18.sp),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              currency.code,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                currency.name,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              CurrencyService.instance.formatAmountWithCurrency(
                                amount,
                                currency,
                              ),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: color[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOwe = widget.type == TransactionType.iOwe;
    final title = isIOwe ? 'I Owe' : 'Owes Me';
    final color = isIOwe ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: color[600],
        foregroundColor: Colors.white,
        elevation: 2,
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
          }
        },
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TransactionLoaded) {
            _processTransactions(state.transactions);
            return _buildContent(color);
          } else if (state is TransactionError) {
            return _buildErrorState(state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewTransaction(),
        backgroundColor: color[600],
        tooltip:
            'Add ${widget.type == TransactionType.iOwe ? 'Debt' : 'Credit'}',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(MaterialColor color) {
    if (_transactions.isEmpty) {
      return _buildEmptyState(color);
    }

    final currencyService = CurrencyService.instance;
    final defaultCurrencyTotal = _getTotalInDefaultCurrency();
    final currencyBreakdown = _getCurrencyBreakdown();

    return Column(
      children: [
        // Default Currency Total
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color[50]!, color[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                widget.type == TransactionType.iOwe
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 48.sp,
                color: color[700],
              ),
              SizedBox(height: 12.h),
              Text(
                'Total Equivalent in ${currencyService.currentCurrency.name}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: color[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                currencyService.formatAmount(defaultCurrencyTotal),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: color[800],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_personTotals.length} ${_personTotals.length == 1 ? 'person' : 'people'} • ${_transactions.length} ${_transactions.length == 1 ? 'transaction' : 'transactions'}',
                style: TextStyle(fontSize: 12.sp, color: color[600]),
              ),
            ],
          ),
        ),

        // Currency Breakdown
        if (currencyBreakdown.length > 1)
          _buildCurrencyBreakdown(currencyBreakdown, color),

        // Ad Banner
        AdBannerWidget(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        ),

        // People List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount:
                _personTotals.length +
                (_personTotals.length > 3 ? 1 : 0), // Add space for another ad
            itemBuilder: (context, index) {
              // Insert banner ad after every 4 people
              if (index > 0 && index % 5 == 4 && _personTotals.length > 3) {
                return AdBannerWidget(
                  margin: EdgeInsets.symmetric(vertical: 16.h),
                );
              }

              final adjustedIndex = index > 4 ? index - 1 : index;
              if (adjustedIndex >= _personTotals.keys.length) {
                return const SizedBox.shrink();
              }

              final personName = _personTotals.keys.elementAt(adjustedIndex);
              final personTotal = _personTotals[personName]!;
              final personTransactions = _groupedTransactions[personName]!;

              return _buildPersonCard(
                personName,
                personTotal,
                personTransactions,
                color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(
    String personName,
    double total,
    List<TransactionEntity> transactions,
    MaterialColor color,
  ) {
    final currencyService = CurrencyService.instance;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _viewPersonDetails(personName, transactions),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: color[100],
                    child: Text(
                      personName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: color[700],
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyService.formatAmount(total),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: color[700],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),

              // Recent transactions preview
              if (transactions.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ...transactions
                          .take(2)
                          .map(
                            (transaction) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      transaction.description,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    currencyService.formatAmount(
                                      transaction.amount,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: color[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          ,
                      if (transactions.length > 2)
                        Text(
                          '+${transactions.length - 2} more...',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(MaterialColor color) {
    final isIOwe = widget.type == TransactionType.iOwe;

    return Column(
      children: [
        // Ad Banner at top
        AdBannerWidget(margin: EdgeInsets.all(16.w)),

        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIOwe
                      ? Icons.account_balance_wallet_outlined
                      : Icons.payments_outlined,
                  size: 80.sp,
                  color: color[300],
                ),
                SizedBox(height: 24.h),
                Text(
                  isIOwe ? 'No debts recorded' : 'No credits recorded',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: color[600],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  isIOwe
                      ? 'You don\'t owe anyone money yet.\nTap + to add a debt.'
                      : 'No one owes you money yet.\nTap + to add a credit.',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton.icon(
                  onPressed: _addNewTransaction,
                  icon: const Icon(Icons.add),
                  label: Text('Add ${isIOwe ? 'Debt' : 'Credit'}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(TransactionError state) {
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
              context.read<TransactionBloc>().add(const LoadTransactionsEvent());
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _addNewTransaction() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const AddTransactionPage()))
        .then((_) {
          // Reload transactions after adding
          context.read<TransactionBloc>().add(const LoadTransactionsEvent());
        });
  }

  void _viewPersonDetails(
    String personName,
    List<TransactionEntity> transactions,
  ) {
    // Navigate to transaction history for the most recent transaction of this person
    if (transactions.isNotEmpty) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      TransactionHistoryPage(transaction: transactions.first),
            ),
          )
          .then((_) {
            // Reload transactions after potential changes
            context.read<TransactionBloc>().add(const LoadTransactionsEvent());
          });
    }
  }
}
