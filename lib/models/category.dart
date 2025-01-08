import 'package:uuid/uuid.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;

  ExpenseCategory({
    String? id,
    required this.name,
    required this.emoji,
  }) : id = id ?? const Uuid().v4();

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
      };

  // From JSON constructor
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: json['id'],
        name: json['name'],
        emoji: json['emoji'],
      );

  // For comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          emoji == other.emoji;

  @override
  int get hashCode => Object.hash(id, name, emoji);

  // Default categories
  static final List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(name: 'Food', emoji: '🍔'),
    ExpenseCategory(name: 'Transport', emoji: '🚗'),
    ExpenseCategory(name: 'Shopping', emoji: '🛍'),
    ExpenseCategory(name: 'Entertainment', emoji: '🎮'),
    ExpenseCategory(name: 'Bills', emoji: '📱'),
    ExpenseCategory(name: 'Others', emoji: '📦'),
  ];
}