import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/currency_service.dart';
import '../../injection/injection_container.dart';
import '../bloc/transacton_bloc/transaction_bloc.dart';
import '../bloc/transacton_bloc/transaction_event.dart';
import '../bloc/currency_bloc/currency_bloc.dart';
import '../bloc/currency_bloc/currency_event.dart';
import '../bloc/currency_bloc/currency_state.dart';
import 'currency_selection_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              serviceLocator<CurrencyBloc>()..add(LoadCurrentCurrencyEvent()),
      child: Scaffold(
        appBar: AppBar(title: Text('Settings'), centerTitle: true),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildSectionHeader('Currency'),
            _buildCurrencyTile(context),

            SizedBox(height: 24.h),

            _buildSectionHeader('Data Management'),
        
       

            SizedBox(height: 24.h),

            _buildSectionHeader('About'),
            _buildAppInfoTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.teal[800],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        if (state is CurrencyLoaded) {
          final currentCurrency = state.currentCurrency;
          return Card(
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.monetization_on, color: Colors.teal[600]),
              ),
              title: Text('Currency'),
              subtitle: Text(
                '${currentCurrency.flag} ${currentCurrency.name} (${currentCurrency.symbol})',
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => CurrencySelectionPage(),
                      ),
                    )
                    .then((currencyChanged) {
                      if (currencyChanged == true) {
                        // Reload transactions to update currency formatting
                        context.read<TransactionBloc>().add(
                          LoadTransactionsEvent(),
                        );
                        // Refresh currency bloc
                        context.read<CurrencyBloc>().add(
                          LoadCurrentCurrencyEvent(),
                        );
                      }
                    });
              },
            ),
          );
        } else {
          // Fallback when loading or error
          final currentCurrency = CurrencyService.instance.currentCurrency;
          return Card(
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.monetization_on, color: Colors.teal[600]),
              ),
              title: Text('Currency'),
              subtitle: Text(
                '${currentCurrency.flag} ${currentCurrency.name} (${currentCurrency.symbol})',
              ),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => CurrencySelectionPage(),
                      ),
                    )
                    .then((currencyChanged) {
                      if (currencyChanged == true) {
                        // Reload transactions to update currency formatting
                        context.read<TransactionBloc>().add(
                          LoadTransactionsEvent(),
                        );
                        // Refresh currency bloc
                        context.read<CurrencyBloc>().add(
                          LoadCurrentCurrencyEvent(),
                        );
                      }
                    });
              },
            ),
          );
        }
      },
    );
  }
  }


  Widget _buildAppInfoTile() {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.info, color: Colors.purple[600]),
        ),
        title: Text('App Information'),
        subtitle: Text('Version 1.0.0'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => _showAppInfoDialog(),
      ),
    );
  }

  void _showSampleDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Sample Data'),
            content: Text(
              'This will add some sample transactions to help you explore the app. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // You can add logic here to create sample data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sample data added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All Data'),
            content: Text(
              'This will permanently delete all your transactions. This action cannot be undone. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                  // You can add logic here to clear data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _showAppInfoDialog() {
    // You can implement this to show app information
  }
