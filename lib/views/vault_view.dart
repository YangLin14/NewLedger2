import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'add_expense_view.dart';
import 'expense_detail_view.dart';
import 'category_detail_view.dart';

enum TimePeriod {
  daily,
  monthly,
  yearly,
}

extension TimePeriodExtension on TimePeriod {
  String get description {
    switch (this) {
      case TimePeriod.daily:
        return 'Daily expenses';
      case TimePeriod.monthly:
        return 'Monthly expenses';
      case TimePeriod.yearly:
        return 'Yearly expenses';
    }
  }

  String get name {
    switch (this) {
      case TimePeriod.daily:
        return 'Daily';
      case TimePeriod.monthly:
        return 'Monthly';
      case TimePeriod.yearly:
        return 'Yearly';
    }
  }
}

class VaultView extends StatefulWidget {
  final VoidCallback onAddExpense;

  const VaultView({
    Key? key,
    required this.onAddExpense,
  }) : super(key: key);

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  ExpenseCategory? _selectedCategory;
  bool _showingAddExpense = false;
  TimePeriod _selectedPeriod = TimePeriod.daily;
  DateTime _selectedDate = DateTime.now();
  bool _showingDatePicker = false;
  String _searchText = '';
  bool _isSearching = false;

  String get _greetingMessage {
    final hour = DateTime.now().hour;
    final name = Provider.of<ExpenseStore>(context, listen: false).profile.name;
    if (hour < 12) {
      return 'Good Morning, $name';
    } else if (hour < 18) {
      return 'Good Afternoon, $name';
    } else {
      return 'Good Evening, $name';
    }
  }

  List<Expense> get _filteredExpenses {
    final store = Provider.of<ExpenseStore>(context);
    var expenses = store.expenses;

    if (_selectedCategory != null) {
      expenses = expenses.where((expense) => expense.category.id == _selectedCategory!.id).toList();
    }

    switch (_selectedPeriod) {
      case TimePeriod.daily:
        expenses = expenses.where((expense) => expense.date.year == _selectedDate.year && expense.date.month == _selectedDate.month && expense.date.day == _selectedDate.day).toList();
        break;
      case TimePeriod.monthly:
        expenses = expenses.where((expense) => expense.date.year == _selectedDate.year && expense.date.month == _selectedDate.month).toList();
        break;
      case TimePeriod.yearly:
        expenses = expenses.where((expense) => expense.date.year == _selectedDate.year).toList();
        break;
    }

    if (_searchText.isNotEmpty) {
      expenses = expenses.where((expense) => expense.name.toLowerCase().contains(_searchText.toLowerCase())).toList();
    }

    return expenses;
  }

  double get _totalExpenses {
    return _filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  String get _formattedSelectedDate {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return DateFormat('EEEE, MMMM d, y').format(_selectedDate);
      case TimePeriod.monthly:
        return DateFormat('MMMM y').format(_selectedDate);
      case TimePeriod.yearly:
        return DateFormat('y').format(_selectedDate);
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case TimePeriod.daily:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case TimePeriod.monthly:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
          break;
        case TimePeriod.yearly:
          _selectedDate = DateTime(_selectedDate.year - 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case TimePeriod.daily:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case TimePeriod.monthly:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
          break;
        case TimePeriod.yearly:
          _selectedDate = DateTime(_selectedDate.year + 1);
          break;
      }
    });
  }

  IconData _getPeriodIcon(TimePeriod period) {
    switch (period) {
      case TimePeriod.daily:
        return Icons.today;
      case TimePeriod.monthly:
        return Icons.calendar_month;
      case TimePeriod.yearly:
        return Icons.calendar_today;
    }
  }

  Widget _buildBudgetStatusCard(ExpenseStore store) {
    final settings = store.profile.budgetSettings;
    final currency = store.profile.currency.symbol;
    
    // Get the relevant budget limit based on current period
    double? budgetLimit = switch (_selectedPeriod) {
      TimePeriod.daily => settings.dailyLimit,
      TimePeriod.monthly => settings.monthlyLimit,
      TimePeriod.yearly => settings.yearlyLimit,
    };

    if (budgetLimit == null) {
      return const SizedBox.shrink(); // Don't show if no budget is set
    }

    final remaining = budgetLimit - _totalExpenses;
    final isOverBudget = remaining < 0;
    final percentage = (_totalExpenses / budgetLimit * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(
                  isOverBudget ? Icons.warning : Icons.check_circle,
                  color: isOverBudget 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                ? 'Over ${_selectedPeriod.name.toLowerCase()} budget by ${store.profile.currency.symbol}${(-remaining).toStringAsFixed(2)}'
                : 'Remaining ${_selectedPeriod.name.toLowerCase()} budget: ${store.profile.currency.symbol}${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                color: isOverBudget 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedPeriod.name} budget: ${store.profile.currency.symbol}${budgetLimit.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Spent: ${store.profile.currency.symbol}${_totalExpenses.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummaryCard(ExpenseStore store) {
    if (_searchText.isEmpty) return const SizedBox.shrink();

    final searchTotal = _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalPercentage = store.expenses.isEmpty ? 0.0 : 
      (searchTotal / store.expenses.fold(0.0, (sum, expense) => sum + expense.amount) * 100);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredExpenses.length} expense${_filteredExpenses.length == 1 ? '' : 's'} found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  '${store.profile.currency.symbol}${searchTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${totalPercentage.toStringAsFixed(1)}% of total expenses',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search expenses...',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  )
                : const Text('NewLedger 🏦'),
            leading: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext bottomSheetContext) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        return ListView(
                          children: [
                            ListTile(
                              title: const Text('Filter by Category'),
                              trailing: DropdownButton<ExpenseCategory?>(
                                value: _selectedCategory,
                                onChanged: (ExpenseCategory? newValue) {
                                  setModalState(() {
                                    _selectedCategory = newValue;
                                  });
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                                items: [
                                  const DropdownMenuItem<ExpenseCategory?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(Icons.all_inclusive, size: 20),
                                        SizedBox(width: 8),
                                        Text('All Categories'),
                                      ],
                                    ),
                                  ),
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
                                          Text(
                                            category.name,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
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
                              title: const Text('Filter by Period'),
                              trailing: DropdownButton<TimePeriod>(
                                value: _selectedPeriod,
                                onChanged: (TimePeriod? newValue) {
                                  setModalState(() {
                                    _selectedPeriod = newValue!;
                                  });
                                  setState(() {
                                    _selectedPeriod = newValue!;
                                  });
                                },
                                items: TimePeriod.values.map((period) {
                                  return DropdownMenuItem(
                                    value: period,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getPeriodIcon(period),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          period.name,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
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
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      transitionAnimationController: AnimationController(
                        duration: const Duration(milliseconds: 300),
                        vsync: Navigator.of(context),
                      ),
                      builder: (context) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: AddExpenseView(
                            onClose: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchText = '';
                    }
                  });
                },
              ),
            ],
            floating: true,
            snap: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searchText.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingMessage,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                          '${store.profile.currency.symbol}${_totalExpenses.toStringAsFixed(2)}',
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
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formattedSelectedDate,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _previousPeriod,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _nextPeriod,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildBudgetStatusCard(store),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_filteredExpenses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                ] else ...[
                  _buildSearchSummaryCard(store),
                ],
              ],
            ),
          ),
          _filteredExpenses.isEmpty
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add a new expense',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_searchText.isNotEmpty) {
                        // Show expenses when searching
                        if (index >= _filteredExpenses.length) return null;
                        final expense = _filteredExpenses[index];
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                expense.category.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
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
                                Text(
                                  expense.category.name,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
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
                      } else {
                        // Show categories when not searching
                        final categoriesToShow = _selectedPeriod == TimePeriod.daily
                          ? store.categories.where((category) {
                              return store.expenses.any((expense) => 
                                expense.category == category && 
                                expense.date.year == _selectedDate.year &&
                                expense.date.month == _selectedDate.month &&
                                expense.date.day == _selectedDate.day
                              );
                            }).toList()
                          : store.categories;

                        if (index >= categoriesToShow.length) return null;

                        final category = categoriesToShow[index];
                        final expenses = store.expenses.where((e) => 
                          e.category == category &&
                          switch (_selectedPeriod) {
                            TimePeriod.daily => 
                              e.date.year == _selectedDate.year &&
                              e.date.month == _selectedDate.month &&
                              e.date.day == _selectedDate.day,
                            TimePeriod.monthly =>
                              e.date.year == _selectedDate.year &&
                              e.date.month == _selectedDate.month,
                            TimePeriod.yearly =>
                              e.date.year == _selectedDate.year,
                          }
                        ).toList();
                        final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetailView(
                                    category: category,
                                    expenses: expenses,
                                    currencySymbol: store.profile.currency.symbol,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      category.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          expenses.isEmpty 
                                            ? 'No expenses' 
                                            : '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${store.profile.currency.symbol}${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    childCount: _searchText.isNotEmpty 
                        ? _filteredExpenses.length 
                        : store.categories.length,
                  ),
                ),
        ],
      ),
    );
  }
}

class SearchResultRow extends StatelessWidget {
  final Expense expense;

  const SearchResultRow({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(expense.category.emoji),
              const SizedBox(width: 8),
              Text(
                expense.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${store.profile.currency.symbol}${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Text(DateFormat('EEEE, MMMM d, y').format(expense.date)),
              const Text(' • '),
              Text(expense.category.name),
            ],
          ),
        ],
      ),
    );
  }
} 