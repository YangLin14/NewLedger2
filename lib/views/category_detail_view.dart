import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'expense_detail_view.dart';
import 'package:provider/provider.dart';

class CategoryDetailView extends StatelessWidget {
  final ExpenseCategory category;
  final List<Expense> expenses;
  final String currencySymbol;

  const CategoryDetailView({
    Key? key,
    required this.category,
    required this.expenses,
    required this.currencySymbol,
  }) : super(key: key);

  void _showEditCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    final TextEditingController emojiController = TextEditingController(text: category.emoji);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                  hintText: 'Enter an emoji (default: 📍)',
                  counterText: '',
                ),
                maxLength: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final store = Provider.of<ExpenseStore>(context, listen: false);
                final updatedCategory = ExpenseCategory(
                  id: category.id,
                  name: nameController.text.trim(),
                  emoji: emojiController.text.trim().isEmpty ? '📍' : emojiController.text.trim(),
                );
                
                store.updateCategory(updatedCategory);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete "${category.name}"? This will also delete all expenses in this category.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                final store = Provider.of<ExpenseStore>(context, listen: false);
                store.deleteCategory(category);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(category.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCategoryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Consumer<ExpenseStore>(
        builder: (context, store, child) {
          final expenses = store.expenses
              .where((e) => e.category.id == category.id)
              .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

          final total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expenses',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${store.profile.currency.symbol}${total.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.account_balance_wallet,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Text('No expenses in this category'),
                      )
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                expense.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMMM d, y').format(expense.date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${store.profile.currency.symbol}${expense.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpenseDetailView(expense: expense),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
} 