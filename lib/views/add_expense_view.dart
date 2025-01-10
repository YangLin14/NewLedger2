import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment.dart';
import '../providers/expense_store.dart';
import '../services/receipt_scanner_service.dart';
import 'package:uuid/uuid.dart';

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
  final ExpenseCategory? initialCategory;

  const AddExpenseView({
    Key? key,
    this.expense,
    this.isEditing = false,
    required this.onClose,
    this.initialCategory,
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
  Uint8List? _receiptImage;
  String? _selectedPayer;
  bool _splitEqually = true;
  Map<String, double> _customSplits = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.isEditing ? widget.expense?.category : widget.initialCategory;
    
    // Initialize selected payer and splits
    if (widget.isEditing) {
      _selectedPayer = widget.expense?.payment?.payerId;
      _customSplits = widget.expense?.payment?.splits ?? {};
    } else if (widget.initialCategory != null) {
      // Set default payer to 'me' for new expenses
      _selectedPayer = 'me';
      // Initialize splits if amount is already set
      if (_amountController.text.isNotEmpty) {
        _updateSplits();
      }
    }

    // Add listener to amount controller
    _amountController.addListener(_updateSplits);

    // Load existing receipt if editing
    if (widget.isEditing && widget.expense?.receiptImageId != null) {
      final store = Provider.of<ExpenseStore>(context, listen: false);
      final receiptImage = store.getReceiptImage(widget.expense!.receiptImageId);
      if (receiptImage != null) {
        _receiptImage = receiptImage;
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateSplits);
    _amountController.dispose();
    _nameController.dispose();
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

    final amount = double.parse(_amountController.text);
    
    // Create payment object if there are collaborators
    Payment? payment;
    if (_selectedCategory!.collaborators.isNotEmpty) {
      // Ensure splits are calculated
      if (_customSplits.isEmpty) {
        _updateSplits();
      }
      
      payment = Payment(
        payerId: _selectedPayer ?? 'me',
        amount: amount,
        splits: Map<String, double>.from(_customSplits),
      );
    }

    final baseExpense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      name: _nameController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory!,
      payment: payment,
      receiptImageId: widget.expense?.receiptImageId,
    );

    final store = Provider.of<ExpenseStore>(context, listen: false);
    
    if (widget.isEditing) {
      store.updateExpense(baseExpense);
    } else {
      store.addExpense(baseExpense, receiptImage: _receiptImage);
      if (payment != null) {
        store.setLastPayer(_selectedCategory!.id, payment.payerId);
      }
    }

    widget.onClose();
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emojiController = TextEditingController();
    List<String> collaborators = [];

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
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Collaborators',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                            onPressed: () async {
                              final email = await showDialog<String>(
                                context: context,
                                builder: (context) => _AddCollaboratorDialog(),
                              );
                              if (email != null && email.isNotEmpty) {
                                setState(() {
                                  collaborators.add(email);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (collaborators.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...collaborators.map((email) => ListTile(
                          dense: true,
                          title: Text(email),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                collaborators.remove(email);
                              });
                            },
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )).toList(),
                      ],
                    ],
                  );
                },
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
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  emoji: emojiController.text.trim().isEmpty ? '📍' : emojiController.text.trim(),
                  collaborators: collaborators,
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
        if (result['date'] != null) {
          _selectedDate = result['date'];
        }
        if (result['imageData'] != null) {
          _receiptImage = result['imageData'];
        }
      });
    }
  }

  Widget _buildSplitSection(BuildContext context, ExpenseStore store) {
    if (_selectedCategory == null || _selectedCategory!.collaborators.isEmpty) {
      return const SizedBox.shrink();
    }

    // Initialize splits if empty
    if (_customSplits.isEmpty && _amountController.text.isNotEmpty) {
      _updateSplits();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Split Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPayer,
          decoration: const InputDecoration(
            labelText: 'Paid by',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: 'me',
              child: Text('Me'),
            ),
            ..._selectedCategory!.collaborators.map((collaborator) {
              return DropdownMenuItem(
                value: collaborator,
                child: Text(collaborator),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPayer = value;
              // Recalculate splits with new payer
              _updateSplits();
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select who paid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Split equally',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Switch(
              value: _splitEqually,
              onChanged: (value) {
                setState(() {
                  _splitEqually = value;
                  _updateSplits();
                });
              },
            ),
          ],
        ),
        if (!_splitEqually) ...[
          const SizedBox(height: 16),
          ...['me', ..._selectedCategory!.collaborators].map((person) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                initialValue: _customSplits[person]?.toString() ?? '0',
                decoration: InputDecoration(
                  labelText: person == 'me' ? 'My share' : '$person\'s share',
                  border: const OutlineInputBorder(),
                  prefixText: store.profile.currency.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  setState(() {
                    _customSplits[person] = amount;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  void _updateSplits() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() {
      if (_splitEqually) {
        final totalPeople = _selectedCategory!.collaborators.length + 1;
        
        if (_selectedPayer == null) {
          _selectedPayer = 'me';  // Default to 'me' if not set
        }

        // Calculate split amount excluding the payer
        final splitAmount = amount / totalPeople;

        // Initialize splits for everyone except the payer
        _customSplits = {
          for (final person in ['me', ..._selectedCategory!.collaborators])
            person: person == _selectedPayer ? 0 : splitAmount
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        titleSpacing: 16,
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.only(top: 8),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  if (_selectedCategory?.collaborators.isNotEmpty == true) {
                    _updateSplits();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
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
                      items: [
                        ...store.categories.map((category) {
                          return DropdownMenuItem<ExpenseCategory>(
                            value: category,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (ExpenseCategory? value) {
                        setState(() {
                          _selectedCategory = value;
                          // Initialize splits and payer when category changes
                          if (value?.collaborators.isNotEmpty == true) {
                            _selectedPayer = 'me';
                            _splitEqually = true;  // Reset to equal splits
                            if (_amountController.text.isNotEmpty) {
                              _updateSplits();
                            }
                          } else {
                            _selectedPayer = null;
                            _customSplits = {};
                          }
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
              if (_receiptImage != null || (widget.expense?.receiptImageId != null)) ...[
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Receipt',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_receiptImage != null || widget.expense?.receiptImageId != null)
                              IconButton(
                                icon: const Icon(Icons.fullscreen),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(
                                          title: const Text('Receipt'),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Image.memory(
                                              _receiptImage ?? 
                                              store.getReceiptImage(widget.expense!.receiptImageId)!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      AspectRatio(
                        aspectRatio: 2/3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: _receiptImage != null
                              ? Image.memory(
                                  _receiptImage!,
                                  fit: BoxFit.cover,
                                )
                              : widget.expense?.receiptImageId != null
                                  ? Image.memory(
                                      store.getReceiptImage(widget.expense!.receiptImageId)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildSplitSection(context, store),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCollaboratorDialog extends StatelessWidget {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Collaborator'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Enter collaborator name',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
} 