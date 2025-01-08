import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class CurrencyService extends ChangeNotifier {
  static CurrencyService? _instance;
  static CurrencyService get instance => _instance ??= CurrencyService._();

  CurrencyService._() {
    _loadRates();
  }

  Map<String, double> _rates = {};
  DateTime? _lastUpdated;

  DateTime? get lastUpdated => _lastUpdated;

  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6/3407a8a179f3568855977454/latest/USD';
  static const String _ratesKey = 'exchangeRates';
  static const String _lastUpdatedKey = 'ratesLastUpdated';

  Future<void> _loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_ratesKey);
    final lastUpdatedStr = prefs.getString(_lastUpdatedKey);

    if (ratesJson != null) {
      _rates = Map<String, double>.from(jsonDecode(ratesJson));
    }
    if (lastUpdatedStr != null) {
      _lastUpdated = DateTime.parse(lastUpdatedStr);
    }

    // If rates are older than 24 hours or don't exist, fetch new ones
    if (_lastUpdated == null ||
        DateTime.now().difference(_lastUpdated!) > const Duration(hours: 24)) {
      await fetchLatestRates();
    }
  }

  Future<void> fetchLatestRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(
          data['conversion_rates'].map((key, value) => MapEntry(
            key,
            value is int ? value.toDouble() : value,
          )),
        );
        _lastUpdated = DateTime.now();

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_ratesKey, jsonEncode(_rates));
        await prefs.setString(_lastUpdatedKey, _lastUpdated!.toIso8601String());

        notifyListeners();
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
      // If fetching fails, use fallback rates
      _useFallbackRates();
    }
  }

  void _useFallbackRates() {
    _rates = {
      'USD': 1.0,
      'TWD': 31.0,
      'EUR': 0.91,
      'JPY': 148.0,
      'GBP': 0.79,
      // Add more fallback rates as needed
    };
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  double getExchangeRate({required Currency from, required Currency to}) {
    if (from == to) return 1.0;

    final fromRate = _rates[from.name] ?? from.fallbackRate;
    final toRate = _rates[to.name] ?? to.fallbackRate;

    return toRate / fromRate;
  }

  double convert({
    required double amount,
    required Currency from,
    required Currency to,
  }) {
    return amount * getExchangeRate(from: from, to: to);
  }
}