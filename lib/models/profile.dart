import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency.dart';

enum BudgetPeriod {
  daily('Daily'),
  monthly('Monthly'),
  yearly('Yearly');

  final String value;
  const BudgetPeriod(this.value);

  factory BudgetPeriod.fromString(String value) {
    return BudgetPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BudgetPeriod.monthly,
    );
  }
}

class BudgetSettings {
  double? dailyLimit;
  double? monthlyLimit;
  double? yearlyLimit;

  BudgetSettings({
    this.dailyLimit,
    this.monthlyLimit,
    this.yearlyLimit,
  });

  Map<String, dynamic> toJson() => {
    'dailyLimit': dailyLimit,
    'monthlyLimit': monthlyLimit,
    'yearlyLimit': yearlyLimit,
  };

  factory BudgetSettings.fromJson(Map<String, dynamic> json) => BudgetSettings(
    dailyLimit: json['dailyLimit']?.toDouble(),
    monthlyLimit: json['monthlyLimit']?.toDouble(),
    yearlyLimit: json['yearlyLimit']?.toDouble(),
  );

  factory BudgetSettings.defaultSettings() => BudgetSettings();
}

class Profile {
  String name;
  Uint8List? imageData;
  Uint8List? backgroundImageData;
  BudgetSettings budgetSettings;
  Currency _currency;

  Profile({
    this.name = 'User',
    this.imageData,
    this.backgroundImageData,
    BudgetSettings? budgetSettings,
  })  : budgetSettings = budgetSettings ?? BudgetSettings(),
        _currency = Currency.USD;

  // Currency getter and setter
  Currency get currency {
    return _currency;
  }

  // Add a separate method for loading currency
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrency = prefs.getString('selectedCurrency');
    if (storedCurrency != null) {
      _currency = Currency.values.firstWhere(
        (c) => c.name == storedCurrency,
        orElse: () => Currency.USD,
      );
    }
  }

  set currency(Currency value) {
    _currency = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('selectedCurrency', value.name);
    });
  }

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'name': name,
        'budgetSettings': budgetSettings.toJson(),
        'currency': _currency.name,
      };

  // From JSON constructor
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String? ?? 'User',
        budgetSettings: BudgetSettings.fromJson(json['budgetSettings'] as Map<String, dynamic>),
      )..currency = Currency.values.firstWhere(
          (c) => c.name == (json['currency'] as String?),
          orElse: () => Currency.USD,
        );
}