import 'package:debt_tracker/presentation/widgets/ad_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../core/services/currency_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/attachment_entity.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import 'add_transaction_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyService = CurrencyService.instance;
    final isIOwe = transaction.type == TransactionType.iOwe;
    final color = isIOwe ? Colors.red : Colors.green;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
        backgroundColor: color[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
            tooltip: 'Edit Transaction',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type & Amount Card
            
            Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 10.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: [color[50]!, color[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isIOwe ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 48.sp,
                      color: color[700],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      isIOwe ? 'I Owe' : 'Owes Me',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: color[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      currencyService.formatAmountWithCurrency(
                        transaction.amount,
                        CurrencyService.transactionCurrencyToCurrency(
                          transaction.currency,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: color[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
   const AdBannerWidget(
        
            ),
            SizedBox(height: 5.h,),

            // Person Details
            _buildDetailCard('Person', transaction.name, Icons.person, color),

            // Description
            if (transaction.description.isNotEmpty)
              _buildDetailCard(
                'Description',
                transaction.description,
                Icons.description,
                color,
              ),

            // Date & Time
            _buildDetailCard(
              'Date & Time',
              '${dateFormat.format(transaction.date)}\n${timeFormat.format(transaction.date)}',
              Icons.access_time,
              color,
            ),

            // Currency Details
            _buildCurrencyCard(color),

            // Attachments
            if (transaction.attachments.isNotEmpty)
              _buildAttachmentsSection(context, color),

            SizedBox(height: 5.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEdit(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ), 
            SizedBox(height: 10.h,),  const AdBannerWidget(
        
            ),
               const AdBannerWidget(
        
            ),SizedBox(height: 10.h,),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color, {
    bool isMonospace = false,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color[600], size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontFamily: isMonospace ? 'monospace' : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(MaterialColor color) {
    final currency = CurrencyService.transactionCurrencyToCurrency(
      transaction.currency,
    );

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(Icons.monetization_on, color: color[600], size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(currency.flag, style: TextStyle(fontSize: 24.sp)),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currency.symbol} ${currency.code}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            currency.name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
             ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(BuildContext context, MaterialColor color) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: color[600], size: 24.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Attachments (${transaction.attachments.length})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...transaction.attachments.map(
              (attachment) => _buildAttachmentItem(context, attachment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(
    BuildContext context,
    AttachmentEntity attachment,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _openAttachment(context, attachment),
        borderRadius: BorderRadius.circular(8.r),
        child: Row(
          children: [
            // File type icon
            _buildFileIcon(attachment),
            SizedBox(width: 12.w),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        attachment.formattedFileSize,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        DateFormat('MMM d, yyyy').format(attachment.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open icon
            Icon(Icons.open_in_new, color: Colors.blue[600], size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(AttachmentEntity attachment) {
    IconData iconData;
    Color iconColor;

    if (attachment.isImage) {
      iconData = Icons.image;
      iconColor = Colors.green[600]!;
    } else if (attachment.isPdf) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red[600]!;
    } else {
      iconData = Icons.attach_file;
      iconColor = Colors.blue[600]!;
    }

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(iconData, color: iconColor, size: 24.sp),
    );
  }

  void _openAttachment(BuildContext context, AttachmentEntity attachment) {
    final file = File(attachment.filePath);

    if (file.existsSync()) {
      if (attachment.isImage) {
        // Show image in a dialog
        showDialog(
          context: context,
          builder:
              (dialogContext) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text(
                        attachment.fileName,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    Flexible(
                      child: InteractiveViewer(
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 48.sp,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 8.h),
                                  const Text('Failed to load image'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        );
      } else {
        // Show info that file needs external app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved at: ${attachment.filePath}'),
            action: SnackBarAction(
              label: 'Copy Path',
              onPressed: () {
                // Could add clipboard functionality here
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found. It may have been deleted.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AddTransactionPage(transactionToEdit: transaction),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Delete Transaction'),
              ],
            ),
            content: const Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                  context.read<TransactionBloc>().add(
                    DeleteTransactionEvent(transactionId: transaction.id),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
