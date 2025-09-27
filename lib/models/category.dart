import 'expense.dart';

class Category {
  final String id;
  String name;
  String emoji;
  double allocated;
  final List<Expense> expenses;

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.allocated = 0,
    List<Expense>? expenses,
  }) : expenses = expenses ?? [];

  double get spent => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get remaining => allocated - spent;
  double get spentRatio => allocated <= 0 ? 0 : (spent / allocated).clamp(0, 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'allocated': allocated,
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '🗂️',
        allocated: (json['allocated'] as num?)?.toDouble() ?? 0.0,
        expenses: (json['expenses'] as List<dynamic>? ?? const [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
