import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/currency_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/transacton_bloc/transaction_state.dart';
import '../widgets/ad_banner_widget.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionEntity? transactionToEdit;
  final String? prefilledName;

  const AddTransactionPage({
    Key? key,
    this.transactionToEdit,
    this.prefilledName,
  }) : super(key: key);

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.iOwe;
  DateTime? _selectedDate;
  final _uuid = Uuid();

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    if (_isEditing) {
      // Populate fields for editing
      final transaction = widget.transactionToEdit!;
      _nameController.text = transaction.name;
      _descriptionController.text = transaction.description;
      _amountController.text = transaction.amount.toString();
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
    } else if (widget.prefilledName != null) {
      // Prefill name for new transaction with same person
      _nameController.text = widget.prefilledName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Transaction' : 'Add New Transaction'),
          actions:
              _isEditing
                  ? [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: _showDeleteConfirmation,
                      tooltip: 'Delete Transaction',
                    ),
                  ]
                  : null,
        ),
        body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: CurrencyService.instance.getAmountPlaceholder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount.';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Please enter an amount greater than zero.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                DropdownButtonFormField<TransactionType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items:
                      TransactionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                type == TransactionType.iOwe
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color:
                                    type == TransactionType.iOwe
                                        ? Colors.red
                                        : Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                type == TransactionType.iOwe
                                    ? 'I Owe (Debit)'
                                    : 'Owes Me (Credit)',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
                SizedBox(height: 20.h),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Transaction Date'),
                    subtitle: Text(
                      _selectedDate == null
                          ? 'No Date Chosen!'
                          : DateFormat.yMMMd().add_jm().format(_selectedDate!),
                    ),
                    trailing: TextButton(
                      onPressed: _presentDatePicker,
                      child: Text(
                        'Choose Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Ad Banner in unused space
                AdBannerWidget(margin: EdgeInsets.symmetric(vertical: 16.h)),

                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: _submitData,
                  icon: Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(
                    _isEditing ? 'Update Transaction' : 'Add Transaction',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.cancel),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                  ),
                ],

                // Additional ad space at bottom
                SizedBox(height: 20.h),
                AdBannerWidget(margin: EdgeInsets.only(bottom: 20.h)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal[700]),
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _capitalizeWords(_nameController.text.trim());
    final description = _descriptionController.text.trim();
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredAmount == null || enteredAmount <= 0 || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount and select a date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final transaction = TransactionEntity(
      id: _isEditing ? widget.transactionToEdit!.id : _uuid.v4(),
      name: name,
      description: description,
      amount: enteredAmount,
      type: _selectedType,
      date: _selectedDate!,
    );

    if (_isEditing) {
      context.read<TransactionBloc>().add(
        UpdateTransactionEvent(transaction: transaction),
      );
    } else {
      context.read<TransactionBloc>().add(
        AddTransactionEvent(transaction: transaction),
      );
    }
  }

  /// Capitalizes the first letter of each word in the string
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Delete Transaction'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.read<TransactionBloc>().add(
                    DeleteTransactionEvent(
                      transactionId: widget.transactionToEdit!.id,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}
