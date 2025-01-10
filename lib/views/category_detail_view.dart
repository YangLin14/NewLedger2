import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'expense_detail_view.dart';
import 'package:provider/provider.dart';
import '../widgets/collaborator_dialog.dart';
import 'add_expense_view.dart';

class CategoryDetailView extends StatefulWidget {
  final ExpenseCategory category;
  final List<Expense> expenses;
  final String currencySymbol;

  const CategoryDetailView({
    Key? key,
    required this.category,
    required this.expenses,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  State<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  void _showEditCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: widget.category.name);
    final TextEditingController emojiController = TextEditingController(text: widget.category.emoji);

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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Category'),
                        content: Text(
                          'Are you sure you want to delete "${widget.category.name}"? This will also delete all expenses in this category.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              final store = Provider.of<ExpenseStore>(context, listen: false);
                              store.deleteCategory(widget.category);
                              Navigator.pop(context); // Close delete dialog
                              Navigator.pop(context); // Close edit dialog
                              Navigator.pop(context); // Return to previous screen
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Category'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }

                final store = Provider.of<ExpenseStore>(context, listen: false);
                final updatedCategory = ExpenseCategory(
                  id: widget.category.id,
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

  List<Widget> _buildSplitSummary(BuildContext context, List<Expense> expenses, ExpenseStore store) {
    // Calculate totals for each person
    Map<String, double> owedAmounts = {'me': 0.0};
    Map<String, double> paidAmounts = {'me': 0.0};
    
    // Initialize maps with all collaborators
    for (String collaborator in widget.category.collaborators) {
      owedAmounts[collaborator] = 0.0;
      paidAmounts[collaborator] = 0.0;
    }

    // Calculate totals
    for (var expense in expenses) {
      if (expense.payment != null) {
        // Add to paid amounts
        final payer = expense.payment!.payerId;
        paidAmounts[payer] = (paidAmounts[payer] ?? 0) + expense.amount;

        // Add split amounts to owed amounts
        expense.payment!.splits.forEach((person, amount) {
          owedAmounts[person] = (owedAmounts[person] ?? 0) + amount;
        });
      }
    }

    // Calculate who owes who
    List<Widget> summaryWidgets = [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Split Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];

    // Create a map of who owes who
    Map<String, Map<String, double>> finalDebts = {};
    
    // For each person who has paid
    for (var payer in paidAmounts.keys) {
      final paid = paidAmounts[payer] ?? 0;
      final owed = owedAmounts[payer] ?? 0;
      final net = paid - owed;
      
      if (net > 0) {  // This person needs to be paid back
        // Find people who owe money
        for (var debtor in owedAmounts.keys) {
          final debtorPaid = paidAmounts[debtor] ?? 0;
          final debtorOwed = owedAmounts[debtor] ?? 0;
          final debtorNet = debtorPaid - debtorOwed;
          
          if (debtorNet < 0 && debtor != payer) {  // This person needs to pay
            final debt = (-debtorNet).clamp(0, net).toDouble();
            if (debt > 0.01) {  // Only show debts greater than 1 cent
              finalDebts[debtor] = finalDebts[debtor] ?? {};
              finalDebts[debtor]![payer] = debt;
            }
          }
        }
      }
    }

    // Update the debt summary items
    finalDebts.forEach((debtor, creditors) {
      creditors.forEach((creditor, amount) {
        if (amount > 0.01) {
          summaryWidgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: _formatName(debtor),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: ' owes '),
                          TextSpan(
                            text: _formatName(creditor),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${store.profile.currency.symbol}${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    });

    if (summaryWidgets.length == 1) {
      summaryWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Everyone is settled up!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return summaryWidgets;
  }

  // Helper method to format names
  String _formatName(String name) {
    return name == 'me' ? 'You' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                widget.category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.category.name,
                style: TextStyle(
                  fontSize: widget.category.name.length > 15 ? 16 : 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (context) => Container(
                  margin: const EdgeInsets.only(top: 80),
                  child: AddExpenseView(
                    onClose: () => Navigator.pop(context),
                    initialCategory: widget.category,
                  ),
                ),
              );
            },
            tooltip: 'Add Expense',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Category'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'collaborators',
                child: Row(
                  children: [
                    Icon(Icons.group),
                    SizedBox(width: 8),
                    Text('Manage Collaborators'),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _showEditCategoryDialog(context);
                  break;
                case 'collaborators':
                  showDialog(
                    context: context,
                    builder: (context) => CollaboratorDialog(
                      category: widget.category,
                      onSaved: () {
                        // Force rebuild of the view
                        setState(() {});
                      },
                    ),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body: Consumer<ExpenseStore>(
        builder: (context, store, child) {
          final expenses = store.expenses
              .where((e) => e.category.id == widget.category.id)
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
                      if (widget.category.collaborators.isNotEmpty) ...[
                        const Divider(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            ..._buildSplitSummary(context, expenses, store),
                          ],
                        ),
                      ],
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('MMM d, y').format(expense.date),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (expense.payment != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Paid by ${_formatName(expense.payment!.payerId)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${store.profile.currency.symbol}${expense.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      if (expense.payment != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Split',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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