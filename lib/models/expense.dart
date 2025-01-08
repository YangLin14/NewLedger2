import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = id ?? const Uuid().v4();

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category.toJson(),
      };

  // From JSON constructor
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        name: json['name'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        category: ExpenseCategory.fromJson(json['category']),
      );

  // Get receipt image path
  Future<String?> get receiptImagePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipts/$id.jpg';
  }
}