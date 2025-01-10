import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile.dart';
import '../providers/expense_store.dart';
import '../models/category.dart';
import 'budget_settings_view.dart';
import 'currency_settings_view.dart';
import 'profile_edit_sheet.dart';
import 'budget_settings_view.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker _picker = ImagePicker();
  bool _showingResetConfirmation = false;
  bool _showingBudgetSettings = false;
  bool _showingCurrencySettings = false;
  bool _showingProfileEditSheet = false;

  // Refined, muted color palette
  final List<Color> categoryColors = const [
    Color.fromRGBO(178, 118, 121, 1), // Muted rose
    Color.fromRGBO(118, 140, 156, 1), // Slate blue
    Color.fromRGBO(149, 165, 139, 1), // Sage green
    Color.fromRGBO(186, 151, 123, 1), // Warm taupe
    Color.fromRGBO(142, 129, 161, 1), // Dusty purple
    Color.fromRGBO(155, 155, 155, 1), // Warm gray
  ];

  Future<void> _pickImage(bool isProfilePicture) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final store = Provider.of<ExpenseStore>(context, listen: false);
      if (isProfilePicture) {
        store.profile.imageData = bytes;
      } else {
        store.profile.backgroundImageData = bytes;
      }
      store.synchronize();
      setState(() {});
    }
  }

  void _removeProfileImage() {
    final store = Provider.of<ExpenseStore>(context, listen: false);
    store.profile.imageData = null;
    store.synchronize();
    setState(() {});
  }

  void _removeBackgroundImage() {
    final store = Provider.of<ExpenseStore>(context, listen: false);
    store.profile.backgroundImageData = null;
    store.synchronize();
    setState(() {});
  }

  String _getBudgetSettingsSubtitle(BudgetSettings settings) {
    final store = Provider.of<ExpenseStore>(context);
    final currency = store.profile.currency.symbol;
    
    List<String> limits = [];
    
    if (settings.dailyLimit != null) {
      limits.add('Daily: $currency${settings.dailyLimit!.toStringAsFixed(2)}');
    }
    if (settings.monthlyLimit != null) {
      limits.add('Monthly: $currency${settings.monthlyLimit!.toStringAsFixed(2)}');
    }
    if (settings.yearlyLimit != null) {
      limits.add('Yearly: $currency${settings.yearlyLimit!.toStringAsFixed(2)}');
    }
    
    return limits.isEmpty ? 'No budget set' : limits.join(' • ');
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'This will delete all your expenses, categories, and profile settings. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                final store = Provider.of<ExpenseStore>(context, listen: false);
                store.resetToDefault();
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been reset'),
                  ),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryPieChart(List<MapEntry<ExpenseCategory, double>> categoryTotals) {
    final total = categoryTotals.fold(0.0, (sum, entry) => sum + entry.value);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: categoryTotals.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value.key;
                final amount = entry.value.value;
                final percentage = (amount / total * 100);

                return PieChartSectionData(
                  color: categoryColors[index % categoryColors.length],
                  value: amount,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);
    final categoryTotals = store.categories
        .map((category) => MapEntry(category, store.totalForCategory(category)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            toolbarHeight: 80,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 20),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image or Gradient
                  if (store.profile.backgroundImageData != null)
                    Image.memory(
                      store.profile.backgroundImageData!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade800,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  // Profile Info
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              image: store.profile.imageData != null
                                  ? DecorationImage(
                                      image: MemoryImage(store.profile.imageData!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: store.profile.imageData == null
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Settings
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                store.profile.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, color: Colors.white70),
                                    label: const Text(
                                      'Edit Profile',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (context) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: 400,
                                              maxHeight: MediaQuery.of(context).size.height * 0.8,
                                            ),
                                            child: ProfileEditSheet(
                                              onClose: () {
                                                Navigator.pop(context);
                                                setState(() {}); // Refresh the view after edit
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
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
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Settings Section
              ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('Currency Settings'),
                subtitle: Text('Current: ${store.profile.currency.symbol} ${store.profile.currency.fullName}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CurrencySettingsView(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Budget Settings'),
                subtitle: Text(_getBudgetSettingsSubtitle(store.profile.budgetSettings)),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetSettingsView(),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: Icon(store.themeMode == ThemeMode.dark 
                  ? Icons.dark_mode 
                  : store.themeMode == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.brightness_auto),
                title: const Text('Theme'),
                subtitle: Text(
                  store.themeMode == ThemeMode.system
                    ? 'System default'
                    : store.themeMode == ThemeMode.light
                      ? 'Light mode'
                      : 'Dark mode'
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Choose Theme'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text('System'),
                            value: ThemeMode.system,
                            groupValue: store.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                store.setThemeMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Light'),
                            value: ThemeMode.light,
                            groupValue: store.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                store.setThemeMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark'),
                            value: ThemeMode.dark,
                            groupValue: store.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                store.setThemeMode(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(),

              // Category Statistics
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    // Add total expense count
                    Text(
                      '${store.expenses.length} total expense${store.expenses.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryPieChart(categoryTotals),
                    const SizedBox(height: 16),
                    ...List.generate(
                      categoryTotals.length,
                      (index) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: categoryColors[index % categoryColors.length],
                          child: Center(
                            child: Text(
                              categoryTotals[index].key.emoji,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        title: Text(
                          categoryTotals[index].key.name,
                          style: TextStyle(
                            color: categoryColors[index % categoryColors.length],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '${store.profile.currency.symbol}${categoryTotals[index].value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: categoryColors[index % categoryColors.length],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reset Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _showResetConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset All Data'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
} 