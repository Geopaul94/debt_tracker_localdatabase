import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../pages/debt_detail_page.dart';
import '../pages/currency_selection_page.dart';

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
    final currencyService = CurrencyService.instance;

    return Card(
      margin: EdgeInsets.all(10.w),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          children: [
            // Currency selector header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // InkWell(
                //   onTap: () => _navigateToCurrencySelection(context),
                //   borderRadius: BorderRadius.circular(8.r),
                //   child: Container(
                //     padding: EdgeInsets.symmetric(
                //       horizontal: 12.w,
                //       vertical: 6.h,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.blue[50],
                //       borderRadius: BorderRadius.circular(8.r),
                //       border: Border.all(color: Colors.blue[200]!),
                //     ),
                //     child: Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Text(
                //           currencyService.currentCurrency.flag,
                //           style: TextStyle(fontSize: 14.sp),
                //         ),
                //         SizedBox(width: 4.w),
                //         Text(
                //           currencyService.currentCurrency.code,
                //           style: TextStyle(
                //             fontSize: 12.sp,
                //             fontWeight: FontWeight.bold,
                //             color: Colors.blue[700],
                //           ),
                //         ),
                //         Icon(
                //           Icons.keyboard_arrow_down,
                //           size: 16.sp,
                //           color: Colors.blue[700],
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 15.h),

            // Main summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  child: _buildClickableSummaryColumn(
                    context,
                    'I Owe',
                    currencyService.formatAmount(totalIOwe),
                    Colors.red,
                    Icons.arrow_upward,
                    TransactionType.iOwe,
                  ),
                ),
                Container(
                  height: 60.h,
                  width: 1,
                  color: Colors.grey[300],
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                ),
                Expanded(
                  child: _buildClickableSummaryColumn(
                    context,
                    'Owes Me',
                    currencyService.formatAmount(totalOwesMe),
                    Colors.green,
                    Icons.arrow_downward,
                    TransactionType.owesMe,
                  ),
                ),
              ],
            ),

            if (netAmount != 0) ...[
              SizedBox(height: 5.h),
              Divider(color: Colors.grey[300]),
              SizedBox(height: 5.h),
              _buildNetAmountSection(currencyService),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClickableSummaryColumn(
    BuildContext context,
    String description,
    String amount,
    MaterialColor color,
    IconData icon,
    TransactionType type,
  ) {
    return InkWell(
      onTap: () => _navigateToDebtDetail(context, type),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color[700], size: 18.sp),
                SizedBox(width: 4.w),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20.sp,
                color: color[800],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap to view',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: color[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 10.sp, color: color[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetAmountSection(CurrencyService currencyService) {
    final isPositive = netAmount > 0;
    final color = isPositive ? Colors.green[700]! : Colors.red[700]!;
    final prefix = isPositive ? 'Net Credit: ' : 'Net Debt: ';
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isPositive ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Net Balance',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '$prefix${currencyService.formatAmount(netAmount.abs())}',
            style: TextStyle(
              fontSize: 18.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isPositive
                ? 'Overall, people owe you money'
                : 'Overall, you owe money',
            style: TextStyle(
              fontSize: 11.sp,
              color: color.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDebtDetail(BuildContext context, TransactionType type) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => DebtDetailPage(type: type)));
  }

  void _navigateToCurrencySelection(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => CurrencySelectionPage()),
    );

    // If currency was changed, trigger a rebuild by calling setState on parent
    // This is handled automatically since we're using the currency service
  }
}
