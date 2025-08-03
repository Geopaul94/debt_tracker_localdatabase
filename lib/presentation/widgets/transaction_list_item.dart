import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;

  const TransactionListItem({Key? key, required this.transaction, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;
    final dateFormat = DateFormat.yMMMd(); // e.g., Sep 10, 2023

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              transaction.type == TransactionType.iOwe
                  ? Colors.red[100]
                  : Colors.green[100],
          radius: 25.r,
          child: Icon(
            transaction.type == TransactionType.iOwe
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color:
                transaction.type == TransactionType.iOwe
                    ? Colors.red[700]
                    : Colors.green[700],
            size: 28.sp,
          ),
        ),
        title: Text(
          transaction.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[800]),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  dateFormat.format(transaction.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                ),
                if (transaction.attachments.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.attach_file, size: 14.sp, color: Colors.blue[600]),
                  Text(
                    '${transaction.attachments.length}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Text(
          '${transaction.type == TransactionType.iOwe ? '- ' : '+ '}${currencyService.formatAmountWithCurrency(transaction.amount, CurrencyService.transactionCurrencyToCurrency(transaction.currency))}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
            color:
                transaction.type == TransactionType.iOwe
                    ? Colors.red[700]
                    : Colors.green[700],
          ),
        ),
      ),
    );
  }
}
