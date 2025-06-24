import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/grouped_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/transaction_list_item.dart';
import 'add_transaction_page.dart';

class GroupedDebtDetailPage extends StatelessWidget {
  final GroupedTransactionEntity groupedTransaction;

  const GroupedDebtDetailPage({Key? key, required this.groupedTransaction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;

    // Determine colors based on net amount
    Color primaryColor;
    Color backgroundColor;
    String title;
    IconData icon;

    if (groupedTransaction.isSettled) {
      primaryColor = Colors.grey[700]!;
      backgroundColor = Colors.grey[100]!;
      title = '${groupedTransaction.userName} (Settled)';
      icon = Icons.check_circle_outline;
    } else if (groupedTransaction.isInMyFavor) {
      primaryColor = Colors.green[700]!;
      backgroundColor = Colors.green[100]!;
      title = '${groupedTransaction.userName} Owes You';
      icon = Icons.   arrow_downward_rounded;
    } else {
      primaryColor = Colors.red[700]!;
      backgroundColor = Colors.red[100]!;
      title = 'You Owe ${groupedTransaction.userName}';
      icon = Icons.arrow_upward_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(groupedTransaction.userName),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 48.sp, color: primaryColor),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                if (!groupedTransaction.isSettled)
                  Text(
                    currencyService.formatAmount(
                      groupedTransaction.absoluteNetAmount,
                    ),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  )
                else
                  Text(
                    'All Settled!',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                SizedBox(height: 8.h),
                Text(
                  '${groupedTransaction.transactions.length} transaction${groupedTransaction.transactions.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 14.sp, color: primaryColor),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      'You Owe',
                      groupedTransaction.totalIOwe,
                      Colors.red[700]!,
                    ),
                    Container(
                      height: 40.h,
                      width: 1,
                      color: primaryColor.withOpacity(0.3),
                    ),
                    _buildSummaryItem(
                      'Owes You',
                      groupedTransaction.totalOwesMe,
                      Colors.green[700]!,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ad Banner
          AdBannerWidget(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),

          // Transaction History
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[600]),
                      SizedBox(width: 8.w),
                      Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: groupedTransaction.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          groupedTransaction.transactions[index];
                      return TransactionListItem(
                        transaction: transaction,
                        onTap:
                            () => _navigateToEditTransaction(
                              context,
                              transaction,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewTransactionForUser(context),
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Transaction for ${groupedTransaction.userName}',
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    final currencyService = CurrencyService.instance;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          currencyService.formatAmount(amount),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _navigateToEditTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AddTransactionPage(transactionToEdit: transaction),
      ),
    );
  }

  void _addNewTransactionForUser(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                AddTransactionPage(prefilledName: groupedTransaction.userName),
      ),
    );
  }
}
