import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../providers/expense_store.dart';
import '../services/receipt_scanner_service.dart';

enum ExpenseFrequency {
  once,
  monthly,
  yearly,
}

extension ExpenseFrequencyExtension on ExpenseFrequency {
  String get name {
    switch (this) {
      case ExpenseFrequency.once:
        return 'One-time';
      case ExpenseFrequency.monthly:
        return 'Monthly';
      case ExpenseFrequency.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case ExpenseFrequency.once:
        return 'This will create a single expense entry.';
      case ExpenseFrequency.monthly:
        return 'This will create 12 monthly recurring expenses starting from the selected date.';
      case ExpenseFrequency.yearly:
        return 'This will create 5 yearly recurring expenses starting from the selected date.';
    }
  }
}

class AddExpenseView extends StatefulWidget {
  final Expense? expense;
  final bool isEditing;
  final VoidCallback onClose;

  const AddExpenseView({
    Key? key,
    this.expense,
    this.isEditing = false,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late ExpenseCategory? _selectedCategory;
  bool _showAddCategory = false;
  final _formKey = GlobalKey<FormState>();
  late ExpenseFrequency _selectedFrequency = ExpenseFrequency.once;
  final _receiptScanner = ReceiptScannerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.isEditing ? widget.expense?.category : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final store = Provider.of<ExpenseStore>(context, listen: false);
    final baseExpense = Expense(
      id: widget.expense?.id,
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category: _selectedCategory!,
    );

    if (widget.isEditing) {
      store.updateExpense(baseExpense);
    } else {
      switch (_selectedFrequency) {
        case ExpenseFrequency.once:
          store.addExpense(baseExpense);
          break;
        case ExpenseFrequency.monthly:
          for (int i = 0; i < 12; i++) {
            store.addExpense(
              Expense(
                name: baseExpense.name,
                amount: baseExpense.amount,
                date: DateTime(
                  baseExpense.date.year,
                  baseExpense.date.month + i,
                  baseExpense.date.day,
                ),
                category: baseExpense.category,
              ),
            );
          }
          break;
        case ExpenseFrequency.yearly:
          for (int i = 0; i < 5; i++) {
            store.addExpense(
              Expense(
                name: baseExpense.name,
                amount: baseExpense.amount,
                date: DateTime(
                  baseExpense.date.year + i,
                  baseExpense.date.month,
                  baseExpense.date.day,
                ),
                category: baseExpense.category,
              ),
            );
          }
          break;
      }
    }

    widget.onClose();
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emojiController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
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
                final newCategory = ExpenseCategory(
                  name: nameController.text.trim(),
                  emoji: emojiController.text.trim().isEmpty ? '📍' : emojiController.text.trim(),
                );
                
                store.addCategory(newCategory);
                setState(() {
                  _selectedCategory = newCategory;
                });
                
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanReceipt() async {
    final result = await _receiptScanner.scanReceipt();
    if (result != null) {
      setState(() {
        if (result['name'] != null) {
          _nameController.text = result['name'];
        }
        if (result['amount'] != null) {
          _amountController.text = result['amount'].toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: const Text('Save'),
          ),
        ],
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.document_scanner),
                    onPressed: _scanReceipt,
                    tooltip: 'Scan Receipt',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: store.profile.currency.symbol,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Category'),
                      items: store.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Text(category.emoji),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (ExpenseCategory? value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton.filled(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add),
                      tooltip: 'Create New Category',
                    ),
                  ),
                ],
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<ExpenseFrequency>(
                      value: _selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: ExpenseFrequency.values.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency.name),
                        );
                      }).toList(),
                      onChanged: (ExpenseFrequency? value) {
                        setState(() {
                          _selectedFrequency = value!;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Text(
                        _selectedFrequency.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      store.deleteExpense(widget.expense!);
                      widget.onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete Expense'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 