import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/transacton_bloc/transaction_state.dart';
import 'add_transaction_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  final TransactionEntity transaction;

  const TransactionHistoryPage({super.key, required this.transaction});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late TransactionEntity currentTransaction;
  List<TransactionEntity> relatedTransactions = [];

  @override
  void initState() {
    super.initState();
    currentTransaction = widget.transaction;
    _loadRelatedTransactions();
  }

  void _loadRelatedTransactions() {
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTransaction,
            tooltip: 'Edit Transaction',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'add_related':
                  _addRelatedTransaction();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'add_related',
                    child: Row(
                      children: [
                        const Icon(Icons.person_add, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Add for ${currentTransaction.name}'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Transaction'),
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

            // Reload transactions
            _loadRelatedTransactions();
          } else if (state is TransactionLoaded) {
            // Filter transactions for the same person
            relatedTransactions =
                state.transactions
                    .where(
                      (t) =>
                          t.name.toLowerCase() ==
                          currentTransaction.name.toLowerCase(),
                    )
                    .toList();
            relatedTransactions.sort((a, b) => b.date.compareTo(a.date));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainTransactionCard(),
                SizedBox(height: 24.h),
                _buildRelatedTransactionsSection(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRelatedTransaction,
        tooltip: 'Add Transaction for ${currentTransaction.name}',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainTransactionCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25.r,
                  backgroundColor:
                      currentTransaction.type == TransactionType.iOwe
                          ? Colors.red[100]
                          : Colors.green[100],
                  child: Icon(
                    currentTransaction.type == TransactionType.iOwe
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color:
                        currentTransaction.type == TransactionType.iOwe
                            ? Colors.red
                            : Colors.green,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTransaction.name,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentTransaction.type == TransactionType.iOwe
                            ? 'I owe this person'
                            : 'This person owes me',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildDetailRow(
              'Amount',
              CurrencyService.instance.formatAmount(currentTransaction.amount),
            ),
            _buildDetailRow('Description', currentTransaction.description),
            _buildDetailRow(
              'Date',
              DateFormat.yMMMd().add_jm().format(currentTransaction.date),
            ),
            _buildDetailRow('Transaction ID', currentTransaction.id),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Transactions with ${currentTransaction.name}',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        if (relatedTransactions.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: Text(
                  'No other transactions found',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          _buildTransactionSummary(),
        SizedBox(height: 16.h),
        ...relatedTransactions
            .map((transaction) => _buildTransactionItem(transaction))
            ,
      ],
    );
  }

  Widget _buildTransactionSummary() {
    final double totalIOweThem = relatedTransactions
        .where((t) => t.type == TransactionType.iOwe)
        .fold(0.0, (sum, t) => sum + t.amount);

    final double totalTheyOweMe = relatedTransactions
        .where((t) => t.type == TransactionType.owesMe)
        .fold(0.0, (sum, t) => sum + t.amount);

    final double netAmount = totalTheyOweMe - totalIOweThem;

    return Card(
      color: netAmount >= 0 ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'Summary',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('I owe them:'),
                Text(
                  CurrencyService.instance.formatAmount(totalIOweThem),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('They owe me:'),
                Text(
                  CurrencyService.instance.formatAmount(totalTheyOweMe),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${netAmount >= 0 ? '+' : ''}${CurrencyService.instance.formatAmount(netAmount.abs())}',
                  style: TextStyle(
                    color: netAmount >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              netAmount >= 0
                  ? '${currentTransaction.name} owes you money'
                  : 'You owe ${currentTransaction.name} money',
              style: TextStyle(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionEntity transaction) {
    final bool isCurrentTransaction = transaction.id == currentTransaction.id;

    return Card(
      elevation: isCurrentTransaction ? 4 : 1,
      color: isCurrentTransaction ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor:
              transaction.type == TransactionType.iOwe
                  ? Colors.red[100]
                  : Colors.green[100],
          child: Icon(
            transaction.type == TransactionType.iOwe
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color:
                transaction.type == TransactionType.iOwe
                    ? Colors.red
                    : Colors.green,
            size: 16.sp,
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(
            fontWeight:
                isCurrentTransaction ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(transaction.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyService.instance.formatAmount(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    transaction.type == TransactionType.iOwe
                        ? Colors.red
                        : Colors.green,
                fontSize: 16.sp,
              ),
            ),
            if (isCurrentTransaction)
              Text(
                'Current',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () {
          if (!isCurrentTransaction) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) =>
                        TransactionHistoryPage(transaction: transaction),
              ),
            );
          }
        },
      ),
    );
  }

  void _editTransaction() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) =>
                    AddTransactionPage(transactionToEdit: currentTransaction),
          ),
        )
        .then((_) {
          // Reload after potential edit
          _loadRelatedTransactions();
        });
  }

  void _addRelatedTransaction() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) =>
                    AddTransactionPage(prefilledName: currentTransaction.name),
          ),
        )
        .then((_) {
          // Reload after adding new transaction
          _loadRelatedTransactions();
        });
  }

  void _showDeleteConfirmation() {
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
                  Navigator.of(context).pop();
                  context.read<TransactionBloc>().add(
                    DeleteTransactionEvent(
                      transactionId: currentTransaction.id,
                    ),
                  );
                  Navigator.of(context).pop(); // Go back to home
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
