import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/services/currency_service.dart';
import '../../core/constants/currencies.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/attachment_entity.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/transacton_bloc/transaction_state.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/attachment_widget.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionEntity? transactionToEdit;
  final String? prefilledName;

  const AddTransactionPage({
    super.key,
    this.transactionToEdit,
    this.prefilledName,
  });

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
  Currency? _selectedCurrency;
  List<AttachmentEntity> _attachments = [];
  final _uuid = Uuid();

  bool get _isEditing => widget.transactionToEdit != null;

  void _initializeCurrency() async {
    // Set default currency first
    setState(() {
      _selectedCurrency = CurrencyConstants.defaultCurrency;
    });

    if (_isEditing) {
      // Find the currency from loaded currencies for editing
      final transactionCurrency = CurrencyService.transactionCurrencyToCurrency(
        widget.transactionToEdit!.currency,
      );
      final currency = await CurrencyConstants.findByCode(
        transactionCurrency.code,
      );
      if (currency != null) {
        setState(() {
          _selectedCurrency = currency;
        });
      }
    } else {
      // Use current app currency for new transactions
      final currentCurrency = CurrencyService.instance.currentCurrency;
      final currency = await CurrencyConstants.findByCode(currentCurrency.code);
      if (currency != null) {
        setState(() {
          _selectedCurrency = currency;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeCurrency();

    if (_isEditing) {
      // Populate fields for editing
      final transaction = widget.transactionToEdit!;
      _nameController.text = transaction.name;
      _descriptionController.text = transaction.description;
      _amountController.text = transaction.amount.toString();
      _selectedType = transaction.type;
      _selectedDate = transaction.date;

      // Initialize attachments for editing
      _attachments = List.from(transaction.attachments);
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

  Future<void> _pickContact() async {
    try {
      // Request permission
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        _showPermissionDialog();
        return;
      }

      // Get all contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contacts found on your device.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show contact picker dialog
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => ContactPickerDialog(contacts: contacts),
      );

      if (selectedContact != null) {
        setState(() {
          _nameController.text = selectedContact.displayName;
        });
      }
    } catch (e) {
      // Handle permission denied or other errors
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        _showPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.blue),
                SizedBox(width: 8),
                Text('Contacts Permission'),
              ],
            ),
            content: const Text(
              'This app needs access to your contacts to help you select contact names. Please grant the permission in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Note: User will need to manually go to settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please go to Settings > Apps > Debt Tracker > Permissions and enable Contacts',
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
                      icon: const Icon(Icons.delete),
                      onPressed: _showDeleteConfirmation,
                      tooltip: 'Delete Transaction',
                    ),
                  ]
                  : null,
        ),
        body: Padding(
          padding: EdgeInsets.all(15.w),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contact_phone),
                      onPressed: _pickContact,
                      tooltip: 'Select from contacts',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
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
                SizedBox(height: 15.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                    ),
                    SizedBox(width: 12.w),
                    InkWell(
                      onTap: _showCurrencySelector,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8.r),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCurrency?.flag ?? '🇺🇸',
                              style: TextStyle(fontSize: 20.sp),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _selectedCurrency?.code ?? 'USD',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                DropdownButtonFormField<TransactionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
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
                              const SizedBox(width: 8),
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
                SizedBox(height: 10.h),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Transaction Date'),
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
                SizedBox(height: 10.h),

                // File Attachments
                AttachmentWidget(
                  attachments: _attachments,
                  onAddAttachment: _pickFile,
                  onTakePhoto: _takePhoto,
                  onRemoveAttachment: _removeAttachment,
                ),
                 SizedBox(height: 10.h),

                // SizedBox(height: 20.h),
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
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                  ),
                ],

                // Additional ad space at bottom
                SizedBox(height:10.h),
         const       AdBannerWidget(
              //    margin: EdgeInsets.only(bottom: 2.h),
                ), // Ad Banner in unused space
          const      AdBannerWidget(
                //  margin: EdgeInsets.symmetric(vertical: 2.h),
                ), // Ad Banner in unused space
          const      AdBannerWidget(
              //    margin: EdgeInsets.symmetric(),
                ), // Ad Banner in unused space
                const AdBannerWidget(
                //  margin: EdgeInsets.symmetric(vertical: 2.h)
                  ),
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
            colorScheme: const ColorScheme.light(
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
        const SnackBar(
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
      currency: CurrencyService.currencyToTransactionCurrency(
        _selectedCurrency!,
      ),
      attachments: _attachments,
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

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowedExtensions: null,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();
        final fileType = result.files.single.extension ?? '';

        // Copy file to app documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String attachmentsDir = '${appDocDir.path}/attachments';
        await Directory(attachmentsDir).create(recursive: true);

        final String newFileName = '${_uuid.v4()}_$fileName';
        final String newPath = '$attachmentsDir/$newFileName';
        await file.copy(newPath);

        // Create attachment entity
        final attachment = AttachmentEntity(
          id: _uuid.v4(),
          fileName: fileName,
          filePath: newPath,
          fileType: 'application/$fileType',
          fileSize: fileSize,
          createdAt: DateTime.now(),
        );

        setState(() {
          _attachments.add(attachment);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(AttachmentEntity attachment) {
    setState(() {
      _attachments.remove(attachment);
    });

    // Delete the physical file
    try {
      final file = File(attachment.filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // File deletion failed, but we continue
      print('Failed to delete file: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileName = image.name;
        final fileSize = await file.length();

        // Copy file to app documents directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String attachmentsDir = '${appDocDir.path}/attachments';
        await Directory(attachmentsDir).create(recursive: true);

        final String newFileName = '${_uuid.v4()}_$fileName';
        final String newPath = '$attachmentsDir/$newFileName';
        await file.copy(newPath);

        // Create attachment entity
        final attachment = AttachmentEntity(
          id: _uuid.v4(),
          fileName: fileName,
          filePath: newPath,
          fileType: 'image/jpeg',
          fileSize: fileSize,
          createdAt: DateTime.now(),
        );

        setState(() {
          _attachments.add(attachment);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured and attached successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder:
          (context) => _CurrencySelectorDialog(
            selectedCurrency:
                _selectedCurrency ?? CurrencyConstants.defaultCurrency,
            onCurrencySelected: (currency) {
              setState(() {
                _selectedCurrency = currency;
                _amountController.text =
                    ''; // Clear amount when currency changes
              });
            },
          ),
    );
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
                  Navigator.of(context).pop(); // Close dialog
                  context.read<TransactionBloc>().add(
                    DeleteTransactionEvent(
                      transactionId: widget.transactionToEdit!.id,
                    ),
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

class _CurrencySelectorDialog extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencySelected;

  const _CurrencySelectorDialog({
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<_CurrencySelectorDialog> createState() =>
      _CurrencySelectorDialogState();
}

class _CurrencySelectorDialogState extends State<_CurrencySelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Currency>> _currenciesFuture;
  List<Currency> _filteredCurrencies = [];
  List<Currency> _allCurrencies = [];
  bool _showPopularOnly = false;

  @override
  void initState() {
    super.initState();
    _currenciesFuture = CurrencyConstants.loadCurrencies();
    _loadCurrencies();
  }

  void _loadCurrencies() async {
    try {
      _allCurrencies = await CurrencyConstants.loadCurrencies();
      setState(() {
        _filteredCurrencies = _allCurrencies;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies =
            _showPopularOnly
                ? _allCurrencies
                    .where(
                      (c) => [
                        'USD',
                        'EUR',
                        'GBP',
                        'JPY',
                        'AUD',
                        'CAD',
                        'CHF',
                        'CNY',
                        'SEK',
                        'NZD',
                        'MXN',
                        'SGD',
                        'HKD',
                        'NOK',
                        'TRY',
                        'ZAR',
                        'BRL',
                        'INR',
                        'KRW',
                        'DKK',
                      ].contains(c.code),
                    )
                    .toList()
                : _allCurrencies;
      } else {
        final queryLower = query.toLowerCase();
        _filteredCurrencies =
            _allCurrencies.where((currency) {
              return currency.name.toLowerCase().contains(queryLower) ||
                  currency.code.toLowerCase().contains(queryLower) ||
                  currency.symbol.toLowerCase().contains(queryLower);
            }).toList();
      }
    });
  }

  void _togglePopularCurrencies() {
    setState(() {
      _showPopularOnly = !_showPopularOnly;
      _filterCurrencies(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 1,
        height: MediaQuery.of(context).size.height * 1,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.white, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search and filter section
            Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search currencies...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterCurrencies('');
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: _filterCurrencies,
                  ),
                  SizedBox(height: 4.h),

                  // Filter and info row
                  Row(
                    children: [
                      // Popular filter toggle
                      FilterChip(
                        label: const Text('Popular currencies'),
                        selected: _showPopularOnly,
                        onSelected: (_) => _togglePopularCurrencies(),
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                      ),

                      // Currency count
                      // FutureBuilder<List<Currency>>(
                      //   future: _currenciesFuture,
                      //   builder: (context, snapshot) {
                      //     final count =
                      //         snapshot.hasData ? snapshot.data!.length : 0;
                      //     return Text(
                      //       '${_filteredCurrencies.length} of $count currencies',
                      //       style: TextStyle(
                      //         color: Colors.grey[600],
                      //         fontSize: 12.sp,
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ],
              ),
            ),

            // Currency list
            Expanded(
              child: FutureBuilder<List<Currency>>(
                future: _currenciesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading currencies',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final isSelected =
                          widget.selectedCurrency.code == currency.code;

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : null,
                          border:
                              isSelected
                                  ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          leading: Container(
                            width: 50.w,
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Center(
                              child: Text(
                                currency.flag.isNotEmpty ? currency.flag : '💱',
                                style: TextStyle(fontSize: 28.sp),
                              ),
                            ),
                          ),
                          title: Text(
                            '${currency.symbol} ${currency.code}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[800],
                            ),
                          ),
                          subtitle: Text(
                            currency.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  )
                                  : Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[400],
                                    size: 16.sp,
                                  ),
                          onTap: () {
                            widget.onCurrencySelected(currency);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Contact picker dialog widget
class ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;

  const ContactPickerDialog({super.key, required this.contacts});

  @override
  _ContactPickerDialogState createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts =
            widget.contacts
                .where(
                  (contact) =>
                      contact.displayName.toLowerCase().contains(query),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.contact_phone, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Select Contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),

            // Contacts list
            Expanded(
              child:
                  _filteredContacts.isEmpty
                      ? Center(
                        child: Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                contact.displayName.isNotEmpty
                                    ? contact.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle:
                                contact.phones.isNotEmpty
                                    ? Text(contact.phones.first.number)
                                    : null,
                            onTap: () {
                              Navigator.of(context).pop(contact);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
