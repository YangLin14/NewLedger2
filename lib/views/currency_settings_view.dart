import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../models/profile.dart';
import '../providers/expense_store.dart';
import '../services/currency_service.dart';

class CurrencySettingsView extends StatefulWidget {
  const CurrencySettingsView({Key? key}) : super(key: key);

  @override
  _CurrencySettingsViewState createState() => _CurrencySettingsViewState();
}

class _CurrencySettingsViewState extends State<CurrencySettingsView> {
  late Currency _selectedCurrency;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = Provider.of<ExpenseStore>(context, listen: false).profile.currency;
  }

  Future<void> _refreshRates() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<CurrencyService>(context, listen: false).fetchLatestRates();
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to fetch latest rates: ${error.toString()}';
        _showError = true;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _convertAmounts() {
    final store = Provider.of<ExpenseStore>(context, listen: false);
    if (_selectedCurrency == store.profile.currency) {
      Navigator.pop(context);
      return;
    }

    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    // Convert all expenses
    final convertedExpenses = store.expenses.map((expense) {
      final convertedAmount = currencyService.convert(
        amount: expense.amount,
        from: store.profile.currency,
        to: _selectedCurrency,
      );

      return Expense(
        id: expense.id,
        name: expense.name,
        amount: convertedAmount,
        date: expense.date,
        category: expense.category,
      );
    }).toList();

    store.updateAllExpenses(convertedExpenses);

    // Convert budget limits
    final settings = store.profile.budgetSettings;
    if (settings.dailyLimit != null) {
      settings.dailyLimit = currencyService.convert(
        amount: settings.dailyLimit!,
        from: store.profile.currency,
        to: _selectedCurrency,
      );
    }

    if (settings.monthlyLimit != null) {
      settings.monthlyLimit = currencyService.convert(
        amount: settings.monthlyLimit!,
        from: store.profile.currency,
        to: _selectedCurrency,
      );
    }

    if (settings.yearlyLimit != null) {
      settings.yearlyLimit = currencyService.convert(
        amount: settings.yearlyLimit!,
        from: store.profile.currency,
        to: _selectedCurrency,
      );
    }

    store.profile.currency = _selectedCurrency;
    store.synchronize();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _convertAmounts,
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Select Currency'),
            trailing: DropdownButton<Currency>(
              value: _selectedCurrency,
              onChanged: (Currency? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCurrency = newValue;
                  });
                }
              },
              items: Currency.values.map((currency) {
                return DropdownMenuItem<Currency>(
                  value: currency,
                  child: Text('${currency.symbol} ${currency.fullName}'),
                );
              }).toList(),
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 4,
              style: Theme.of(context).textTheme.bodyLarge,
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              underline: Container(
                height: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            title: const Text('Exchange Rates'),
            subtitle: currencyService.lastUpdated == null
                ? const Text('Never updated')
                : Text('Last updated: ${currencyService.lastUpdated}'),
            trailing: _isLoading
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshRates,
                  ),
          ),
          const Divider(),
          ...Currency.values.map((Currency currency) {
            final rate = currencyService.getExchangeRate(from: _selectedCurrency, to: currency);
            return ListTile(
              title: Text('${currency.symbol} ${currency.fullName}'),
              trailing: Text(rate.toStringAsFixed(2)),
            );
          }).toList(),
        ],
      ),
    );
  }
} 