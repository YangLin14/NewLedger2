import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';

class Expense {
  final String? id;
  final String name;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImageId;

  Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImageId,
  });

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
        'categoryId': category.id,
        'receiptImageId': receiptImageId,
      };

  // From JSON constructor
  factory Expense.fromJson(Map<String, dynamic> json, ExpenseCategory category) => Expense(
        id: json['id'],
        name: json['name'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        category: category,
        receiptImageId: json['receiptImageId'],
      );

  // Get receipt image path
  Future<String?> get receiptImagePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipts/$id.jpg';
  }
}