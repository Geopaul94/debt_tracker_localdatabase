import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/grouped_transaction_entity.dart';

class GroupedTransactionListItem extends StatelessWidget {
  final GroupedTransactionEntity groupedTransaction;
  final VoidCallback? onTap;

  const GroupedTransactionListItem({
    Key? key,
    required this.groupedTransaction,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;
    final dateFormat = DateFormat.yMMMd();

    // Determine colors and icons based on net amount
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String amountPrefix;
    String statusText;

    if (groupedTransaction.isSettled) {
      backgroundColor = Colors.grey[100]!;
      iconColor = Colors.grey[700]!;
      icon = Icons.check_circle_outline;
      amountPrefix = '';
      statusText = 'Settled';
    } else if (groupedTransaction.isInMyFavor) {
      backgroundColor = Colors.green[100]!;
      iconColor = Colors.green[700]!;
      icon = Icons.arrow_downward_rounded;
      amountPrefix = '+';
      statusText = 'Owes you';
    } else {
      backgroundColor = Colors.red[100]!;
      iconColor = Colors.red[700]!;
      icon = Icons.arrow_upward_rounded;
      amountPrefix = '-';
      statusText = 'You owe';
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          radius: 25.r,
          child: Icon(icon, color: iconColor, size: 28.sp),
        ),
        title: Text(
          groupedTransaction.userName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${groupedTransaction.transactions.length} transaction${groupedTransaction.transactions.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[800]),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    ' • ${dateFormat.format(groupedTransaction.lastTransactionDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_hasAttachments())
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(
                      Icons.attach_file,
                      size: 14.sp,
                      color: Colors.blue[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!groupedTransaction.isSettled)
              Text(
                '$amountPrefix${currencyService.formatAmount(groupedTransaction.absoluteNetAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                  color: iconColor,
                ),
              )
            else
              Text(
                'Settled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasAttachments() {
    return groupedTransaction.transactions.any(
      (transaction) => transaction.attachments.isNotEmpty,
    );
  }
}
