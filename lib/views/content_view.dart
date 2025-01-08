import 'package:flutter/material.dart';
import 'vault_view.dart';
import 'profile_view.dart';
import 'add_expense_view.dart';

class ContentView extends StatefulWidget {
  const ContentView({Key? key}) : super(key: key);

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _showingAddExpense = false;
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _pages.addAll([
      VaultView(
        key: const PageStorageKey('vault_view'),
        onAddExpense: () => setState(() => _showingAddExpense = true),
      ),
      const ProfileView(
        key: PageStorageKey('profile_view'),
      ),
    ]);

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
      _animationController.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Previous page (stays visible underneath)
          _pages[_previousIndex],

          // New page fading in on top
          FadeTransition(
            opacity: _fadeAnimation,
            child: _pages[_selectedIndex],
          ),

          // Modal overlay
          if (_showingAddExpense)
            ModalBarrier(
              color: Colors.black54,
              dismissible: true,
              onDismiss: () => setState(() => _showingAddExpense = false),
            ),

          // Add expense view
          if (_showingAddExpense)
            AddExpenseView(
              onClose: () => setState(() => _showingAddExpense = false),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        animationDuration: const Duration(milliseconds: 300),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}