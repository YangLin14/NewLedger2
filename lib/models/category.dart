import 'package:uuid/uuid.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;
  List<String> collaborators;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    List<String>? collaborators,
  }) : collaborators = collaborators ?? [];

  // For JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'collaborators': collaborators,
      };

  // From JSON constructor
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: json['id'],
        name: json['name'],
        emoji: json['emoji'],
        collaborators: List<String>.from(json['collaborators'] ?? []),
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
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Food', 
      emoji: '🍔'
    ),
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Transport', 
      emoji: '🚗'
    ),
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Shopping', 
      emoji: '🛍'
    ),
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Entertainment', 
      emoji: '🎮'
    ),
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Bills', 
      emoji: '📱'
    ),
    ExpenseCategory(
      id: const Uuid().v4(),
      name: 'Others', 
      emoji: '📦'
    ),
  ];
}