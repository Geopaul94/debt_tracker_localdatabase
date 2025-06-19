import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalIOwe;
  final double totalOwesMe;
  final double netAmount;

  const SummaryCard({
    Key? key,
    required this.totalIOwe,
    required this.totalOwesMe,
    required this.netAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildSummaryColumn(
                  'I Owe',
                  currencyFormat.format(totalIOwe),
                  Colors.red[700]!,
                ),
                Container(height: 60.h, width: 1, color: Colors.grey[300]),
                _buildSummaryColumn(
                  'Owes Me',
                  currencyFormat.format(totalOwesMe),
                  Colors.green[700]!,
                ),
              ],
            ),
            if (netAmount != 0) ...[
              SizedBox(height: 16.h),
              Divider(color: Colors.grey[300]),
              SizedBox(height: 16.h),
              _buildNetAmountSection(currencyFormat),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String description, String amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          description,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          amount,
          style: TextStyle(
            fontSize: 22.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNetAmountSection(NumberFormat currencyFormat) {
    final isPositive = netAmount > 0;
    final color = isPositive ? Colors.green[700]! : Colors.red[700]!;
    final prefix = isPositive ? 'Net Credit: ' : 'Net Debt: ';

    return Column(
      children: [
        Text(
          'Net Balance',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '$prefix${currencyFormat.format(netAmount.abs())}',
          style: TextStyle(
            fontSize: 18.sp,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
