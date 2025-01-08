import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/expense_store.dart';

class BudgetSettingsView extends StatefulWidget {
  const BudgetSettingsView({Key? key}) : super(key: key);

  @override
  State<BudgetSettingsView> createState() => _BudgetSettingsViewState();
}

class _BudgetSettingsViewState extends State<BudgetSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dailyController;
  late TextEditingController _monthlyController;
  late TextEditingController _yearlyController;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ExpenseStore>(context, listen: false);
    final settings = store.profile.budgetSettings;
    
    _dailyController = TextEditingController(
      text: settings.dailyLimit?.toStringAsFixed(2) ?? '',
    );
    _monthlyController = TextEditingController(
      text: settings.monthlyLimit?.toStringAsFixed(2) ?? '',
    );
    _yearlyController = TextEditingController(
      text: settings.yearlyLimit?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (!_formKey.currentState!.validate()) return;

    final store = Provider.of<ExpenseStore>(context, listen: false);
    final settings = store.profile.budgetSettings;

    settings.dailyLimit = _dailyController.text.isEmpty 
        ? null 
        : double.parse(_dailyController.text);
    settings.monthlyLimit = _monthlyController.text.isEmpty 
        ? null 
        : double.parse(_monthlyController.text);
    settings.yearlyLimit = _yearlyController.text.isEmpty 
        ? null 
        : double.parse(_yearlyController.text);

    store.synchronize();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);
    final currency = store.profile.currency.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
        actions: [
          TextButton(
            onPressed: _saveBudget,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Set your spending limits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Leave a field empty to remove its budget limit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _dailyController,
              decoration: InputDecoration(
                labelText: 'Daily Budget',
                border: const OutlineInputBorder(),
                prefixText: currency,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter a positive number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyController,
              decoration: InputDecoration(
                labelText: 'Monthly Budget',
                border: const OutlineInputBorder(),
                prefixText: currency,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter a positive number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _yearlyController,
              decoration: InputDecoration(
                labelText: 'Yearly Budget',
                border: const OutlineInputBorder(),
                prefixText: currency,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Please enter a positive number';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
} 