import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'package:provider/provider.dart';
import 'expense_detail_view.dart';

class SplitDetailsView extends StatelessWidget {
  final String person1; // debtor
  final String person2; // creditor
  final ExpenseCategory category; // Add category parameter instead of expenses list

  const SplitDetailsView({
    Key? key,
    required this.person1,
    required this.person2,
    required this.category, // Update constructor
  }) : super(key: key);

  String _formatName(String name) {
    return name == 'me' ? 'You' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseStore>(
      builder: (context, store, child) {
        // Get the latest category from the store
        final currentCategory = store.categories.firstWhere(
          (c) => c.id == category.id,
          orElse: () => category,
        );

        // Calculate splits using the store method
        final splits = store.calculateSplitsBetween(person1, person2, currentCategory);
        final totalOwed = splits['amount'] ?? 0;

        // Get latest expenses for display
        final expenses = store.expenses
            .where((e) => e.category.id == currentCategory.id)
            .toList();
        
        // Sort expenses by date, most recent first
        final sortedExpenses = List<Expense>.from(expenses)
          ..sort((a, b) => b.date.compareTo(a.date));

        // Filter and calculate relevant expenses for display
        List<Map<String, dynamic>> splitDetails = [];
        
        for (var expense in sortedExpenses) {
          if (expense.payment != null) {
            final payment = expense.payment!;
            double? amount;

            // Case 1: person1 owes person2 for this expense
            if (payment.payerId == person2 && payment.splits.containsKey(person1)) {
              amount = payment.splits[person1];
            }
            // Case 2: person2 owes person1 for this expense (will be negative)
            else if (payment.payerId == person1 && payment.splits.containsKey(person2)) {
              amount = -(payment.splits[person2] ?? 0);
            }

            if (amount != null && amount.abs() > 0.01) {
              splitDetails.add({
                'expense': expense,
                'amount': amount,
                'payer': payment.payerId,
              });
            }
          }
        }

        // Force rebuild by using a unique key based on the data
        return Scaffold(
          key: ValueKey('split_details_${currentCategory.id}_${totalOwed}_${splitDetails.length}'),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatName(person1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Text(_formatName(person2)),
              ],
            ),
          ),
          body: Column(
            children: [
              // Total amount card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total Outstanding',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '${store.profile.currency.symbol}${totalOwed.abs().toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: store.isSplitSettled(person1, person2, currentCategory.id)
                                  ? Colors.green.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              store.isSplitSettled(person1, person2, currentCategory.id)
                                  ? totalOwed > 0
                                      ? '${_formatName(person1)} owed ${_formatName(person2)}'
                                      : '${_formatName(person2)} owed ${_formatName(person1)}'
                                  : totalOwed > 0
                                      ? '${_formatName(person1)} owes ${_formatName(person2)}'
                                      : '${_formatName(person2)} owes ${_formatName(person1)}',
                              style: TextStyle(
                                color: store.isSplitSettled(person1, person2, currentCategory.id)
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expenses list header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Expense History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${splitDetails.length} expense${splitDetails.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // List of expenses
              Expanded(
                child: splitDetails.isEmpty
                    ? Center(
                        child: Text(
                          'No expenses to show',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: splitDetails.length,
                        itemBuilder: (context, index) {
                          final detail = splitDetails[index];
                          final expense = detail['expense'] as Expense;
                          final amount = detail['amount'] as double;
                          final payer = detail['payer'] as String;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpenseDetailView(expense: expense),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                          radius: 16,
                                          child: Text(
                                            expense.category.emoji,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                expense.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM d, y').format(expense.date),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${store.profile.currency.symbol}${amount.abs().toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: amount < 0 
                                                    ? Colors.green 
                                                    : Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Paid by ${_formatName(payer)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Spacer(),
              // Settle up button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (store.isSplitSettled(person1, person2, currentCategory.id)) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            store.unsettleSplit(person1, person2, currentCategory);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Settled'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: totalOwed.abs() > 0.01 
                              ? () => showSettleUpDialog(context, store, totalOwed, currentCategory)
                              : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Settle Up'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Move showSettleUpDialog inside the build method to access store and context
  void showSettleUpDialog(BuildContext context, ExpenseStore store, double totalOwed, ExpenseCategory currentCategory) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Settle Up'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                      child: const Icon(
                        Icons.currency_exchange,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${store.profile.currency.symbol}${totalOwed.abs().toStringAsFixed(2)}',
                            style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(dialogContext).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(dialogContext).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: _formatName(person1),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' will send to '),
                                TextSpan(
                                  text: _formatName(person2),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will mark this debt as settled. The expense history will be preserved.',
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                store.settleSplit(person1, person2, currentCategory);
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Return to category view
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Settle Up'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        );
      },
    );
  }
} 