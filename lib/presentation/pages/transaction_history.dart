import 'package:flutter/material.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      body: Center(
        child: Text(
          'Transaction History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      appBar: AppBar(
        title: Text('Transaction History'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to add a new transaction
          Navigator.pushNamed(context, '/addTransaction');
        },
        child: Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}