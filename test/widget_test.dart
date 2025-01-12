// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:newledger/main.dart';
import 'package:newledger/providers/expense_store.dart';
import 'package:newledger/services/currency_service.dart';
import 'package:newledger/views/splash_view.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    await Hive.openBox('expenses');
    await Hive.openBox('categories');
    await Hive.openBox('receipts');
  });

  tearDown(() async {
    // Clean up Hive boxes after tests
    await Hive.deleteBoxFromDisk('expenses');
    await Hive.deleteBoxFromDisk('categories');
    await Hive.deleteBoxFromDisk('receipts');
  });

  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Initialize stores
    final expenseStore = ExpenseStore();
    await expenseStore.loadData();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: expenseStore),
          ChangeNotifierProvider(create: (_) => CurrencyService.instance),
        ],
        child: MyApp(expenseStore: expenseStore),
      ),
    );

    // Verify that the splash screen is shown initially
    expect(find.byType(SplashView), findsOneWidget);

    // Wait for animations to complete
    await tester.pumpAndSettle();

    // Additional test cases
    expect(find.text('NewLedger 🏦'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
