import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/profile.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class ExpenseStore extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = ExpenseCategory.defaultCategories;
  Profile _profile = Profile(name: 'User');
  final _receiptBox = Hive.box('receipts');

  // Keys for SharedPreferences
  static const String _expensesKey = 'savedExpenses';
  static const String _categoriesKey = 'savedCategories';
  static const String _profileKey = 'savedProfile';

  // Getters
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  Profile get profile => _profile;

  // Add theme mode property
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;

  // Add a map to store the last payer for each category
  final Map<String, String> _lastPayers = {};

  // Add getter and setter for last payer
  String? getLastPayer(String categoryId) => _lastPayers[categoryId];
  
  void setLastPayer(String categoryId, String payerId) {
    _lastPayers[categoryId] = payerId;
  }

  ExpenseStore() {
    init();
  }

  // Initialize the store
  Future<void> init() async {
    await loadData();
    await profile.loadCurrency();
    notifyListeners();
  }

  // CRUD Operations for Expenses
  Future<void> addExpense(Expense expense, {Uint8List? receiptImage}) async {
    String? imageId;
    if (receiptImage != null) {
      imageId = await saveReceiptImage(receiptImage);
    }

    // Create the new expense with payment info if category has collaborators
    final newExpense = Expense(
      id: const Uuid().v4(),
      name: expense.name,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      receiptImageId: imageId,
      payment: expense.payment, // Make sure to include the payment info
    );

    _expenses.add(newExpense);
    await _saveExpenses();
    notifyListeners();

    // Update last payer if there's a payment
    if (expense.payment != null) {
      setLastPayer(expense.category.id, expense.payment!.payerId);
    }
  }

  void deleteExpense(Expense expense) {
    _expenses.removeWhere((e) => e.id == expense.id);
    synchronize();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      synchronize();
      notifyListeners();
    }
  }

  // Category Operations
  void addCategory(ExpenseCategory category) {
    _categories.add(category);
    synchronize();
    notifyListeners();
  }

  void deleteCategory(ExpenseCategory category) {
    _categories.removeWhere((c) => c.id == category.id);
    _expenses.removeWhere((e) => e.category.id == category.id);
    synchronize();
    notifyListeners();
  }

  void updateCategory(ExpenseCategory category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      
      // Recalculate splits for all expenses in this category
      for (var expense in _expenses.where((e) => e.category.id == category.id)) {
        if (expense.payment != null && expense.payment!.isEqualSplit) {
          expense.payment!.recalculateEqualSplits(category.collaborators);
        }
      }
      
      synchronize();
      notifyListeners();
    }
  }

  // Calculations
  double totalForCategory(ExpenseCategory category) {
    return _expenses
        .where((expense) => expense.category.id == category.id)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double totalExpenses() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  // Data persistence
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Load categories first since expenses depend on them
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _categories = decoded.map((c) => ExpenseCategory.fromJson(c)).toList();
      }

      // Then load expenses with category references
      final expensesJson = prefs.getString(_expensesKey);
      if (expensesJson != null) {
        final List<dynamic> expensesList = jsonDecode(expensesJson);
        _expenses = expensesList.map((e) => Expense.fromJson(e)).toList();
      }

      // Load profile
      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        _profile = Profile.fromJson(jsonDecode(profileJson));
        
        // Load profile images
        final directory = await getApplicationDocumentsDirectory();
        final profileImageFile = File('${directory.path}/profile_image.jpg');
        final backgroundImageFile = File('${directory.path}/profile_background.jpg');

        if (await profileImageFile.exists()) {
          _profile.imageData = await profileImageFile.readAsBytes();
        }
        if (await backgroundImageFile.exists()) {
          _profile.backgroundImageData = await backgroundImageFile.readAsBytes();
        }
      }

      // Load theme preference
      final themeModeString = prefs.getString('themeMode') ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == 'ThemeMode.$themeModeString',
        orElse: () => ThemeMode.system,
      );
      
    } catch (e) {
      debugPrint('Error loading data: $e');
      resetToDefault();
    }
    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final String encoded = jsonEncode(_expenses.map((e) => e.toJson()).toList());
      await prefs.setString(_expensesKey, encoded);
    } catch (e) {
      debugPrint('Error saving expenses: $e');
    }
  }

  Future<void> saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final String encoded = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString(_categoriesKey, encoded);
    } catch (e) {
      debugPrint('Error saving categories: $e');
    }
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final Map<String, dynamic> profileData = _profile.toJson();
      await prefs.setString(_profileKey, jsonEncode(profileData));

      // Handle profile image
      final directory = await getApplicationDocumentsDirectory();
      final profileImageFile = File('${directory.path}/profile_image.jpg');
      final backgroundImageFile = File('${directory.path}/profile_background.jpg');

      // Save or delete profile image
      if (_profile.imageData != null) {
        await profileImageFile.writeAsBytes(_profile.imageData!);
      } else if (await profileImageFile.exists()) {
        await profileImageFile.delete();
      }

      // Save or delete background image
      if (_profile.backgroundImageData != null) {
        await backgroundImageFile.writeAsBytes(_profile.backgroundImageData!);
      } else if (await backgroundImageFile.exists()) {
        await backgroundImageFile.delete();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  Future<void> _saveImageToFile(Uint8List imageData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageData);
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }

  Future<Uint8List?> _loadImageFromFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return null;
  }

  Future<void> synchronize() async {
    try {
      await Future.wait([
        _saveExpenses(),
        saveCategories(),
        saveProfile(),
      ]);
    } catch (e) {
      debugPrint('Error synchronizing data: $e');
    }
  }

  void resetToDefault() {
    _expenses = [];
    _categories = ExpenseCategory.defaultCategories;
    _profile = Profile(name: 'User');
    _profile.imageData = null;
    _profile.backgroundImageData = null;
    _deleteProfileImages();
    synchronize();
    notifyListeners();
  }

  Future<void> _deleteProfileImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileImageFile = File('${directory.path}/profile_image.jpg');
      final backgroundImageFile = File('${directory.path}/profile_background.jpg');

      if (await profileImageFile.exists()) {
        await profileImageFile.delete();
      }
      if (await backgroundImageFile.exists()) {
        await backgroundImageFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting profile images: $e');
    }
  }

  // Receipt image handling
  Future<String> saveReceiptImage(Uint8List imageData) async {
    final imageId = const Uuid().v4();
    await _receiptBox.put(imageId, imageData);
    return imageId;
  }

  Uint8List? getReceiptImage(String? imageId) {
    if (imageId == null) return null;
    return _receiptBox.get(imageId);
  }

  void updateAllExpenses(List<Expense> newExpenses) {
    _expenses = newExpenses;
    synchronize();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }
} 