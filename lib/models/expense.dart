import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';
import 'payment.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImageId;
  final Payment? payment;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImageId,
    this.payment,
  });

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category.toJson(),
        'receiptImageId': receiptImageId,
        'payment': payment?.toJson(),
      };

  // From JSON constructor
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        name: json['name'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        category: ExpenseCategory.fromJson(json['category']),
        receiptImageId: json['receiptImageId'],
        payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
      );

  // Get receipt image path
  Future<String?> get receiptImagePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/receipts/$id.jpg';
  }
}