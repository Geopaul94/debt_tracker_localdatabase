import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/trash_service.dart';
import '../../core/services/currency_service.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../../domain/entities/transaction_entity.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({Key? key}) : super(key: key);

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  bool _isLoading = false;
  List<TrashItem> _trashItems = [];

  @override
  void initState() {
    super.initState();
    _loadTrashItems();
  }

  Future<void> _loadTrashItems() async {
    setState(() => _isLoading = true);

    final items = await TrashService.instance.getTrashItems();

    setState(() {
      _trashItems = items;
      _isLoading = false;
    });
  }

  Future<void> _restoreItem(TrashItem item) async {
    final confirmed = await _showRestoreConfirmationDialog(item);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await TrashService.instance.restoreFromTrash(item.id);

    if (success) {
      await _loadTrashItems();
      // Refresh transactions in the main app
      context.read<TransactionBloc>().add(LoadTransactionsEvent());
      _showSuccessSnackBar('✅ Transaction restored successfully!');
    } else {
      _showErrorSnackBar('❌ Failed to restore transaction');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _permanentlyDeleteItem(TrashItem item) async {
    final confirmed = await _showPermanentDeleteConfirmationDialog(item);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await TrashService.instance.permanentlyDelete(item.id);

    if (success) {
      await _loadTrashItems();
      _showSuccessSnackBar('✅ Transaction permanently deleted');
    } else {
      _showErrorSnackBar('❌ Failed to delete transaction');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _emptyTrash() async {
    if (_trashItems.isEmpty) {
      _showErrorSnackBar('🗑️ Trash is already empty');
      return;
    }

    final confirmed = await _showEmptyTrashConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success = await TrashService.instance.emptyTrash();

    if (success) {
      await _loadTrashItems();
      _showSuccessSnackBar('✅ Trash emptied successfully');
    } else {
      _showErrorSnackBar('❌ Failed to empty trash');
    }

    setState(() => _isLoading = false);
  }

  Future<bool> _showRestoreConfirmationDialog(TrashItem item) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('🔄 Restore Transaction'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Do you want to restore this transaction?'),
                    SizedBox(height: 16.h),
                    _buildTransactionPreview(item),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'Restore',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<bool> _showPermanentDeleteConfirmationDialog(TrashItem item) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('🗑️ Permanent Delete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This action cannot be undone. Are you sure?'),
                    SizedBox(height: 16.h),
                    _buildTransactionPreview(item),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[600],
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'This transaction will be permanently deleted and cannot be recovered!',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Delete Forever',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<bool> _showEmptyTrashConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('🗑️ Empty Trash'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will permanently delete all ${_trashItems.length} items in trash.',
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[600],
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Empty Trash',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget _buildTransactionPreview(TrashItem item) {
    final currency = CurrencyService.instance.currentCurrency;
    final isIOwe = item.type == 'iOwe';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIOwe ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIOwe ? Colors.red : Colors.green,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '${currency.symbol}${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isIOwe ? Colors.red : Colors.green,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              item.description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🗑️ Trash'),
        centerTitle: true,
        actions: [
          if (_trashItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: _emptyTrash,
              tooltip: 'Empty Trash',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTrashItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildTrashContent(),
    );
  }

  Widget _buildTrashContent() {
    if (_trashItems.isEmpty) {
      return _buildEmptyTrash();
    }

    return Column(
      children: [_buildTrashInfo(), Expanded(child: _buildTrashList())],
    );
  }

  Widget _buildEmptyTrash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Trash is empty',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Deleted transactions will appear here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                SizedBox(height: 8.h),
                Text(
                  'Deleted transactions are kept for 30 days before being permanently removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashInfo() {
    final expiringSoon =
        _trashItems.where((item) => item.isExpiringSoon).length;

    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600]),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '${_trashItems.length} items in trash',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          if (expiringSoon > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[600],
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '$expiringSoon items will be permanently deleted within 7 days',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            'Items are automatically deleted after 30 days',
            style: TextStyle(fontSize: 12.sp, color: Colors.orange[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _trashItems.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final item = _trashItems[index];
        return _buildTrashItemCard(item);
      },
    );
  }

  Widget _buildTrashItemCard(TrashItem item) {
    final currency = CurrencyService.instance.currentCurrency;
    final isIOwe = item.type == 'iOwe';

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isIOwe ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    isIOwe ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isIOwe ? Colors.red[600] : Colors.green[600],
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currency.symbol}${item.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isIOwe ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isExpiringSoon)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Expires soon',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                item.description,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.schedule, size: 14.sp, color: Colors.grey[500]),
                SizedBox(width: 4.w),
                Text(
                  'Deleted: ${item.formattedDeletedAt}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.timer, size: 14.sp, color: Colors.grey[500]),
                SizedBox(width: 4.w),
                Text(
                  '${item.daysUntilDeletion} days left',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        item.isExpiringSoon
                            ? Colors.red[600]
                            : Colors.grey[500],
                    fontWeight:
                        item.isExpiringSoon
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _restoreItem(item),
                    icon: Icon(Icons.restore, size: 16.sp),
                    label: Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _permanentlyDeleteItem(item),
                    icon: Icon(Icons.delete_forever, size: 16.sp),
                    label: Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
