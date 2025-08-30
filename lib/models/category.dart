import 'expense.dart';

class Category {
  final String id;
  String name;
  String emoji; // e.g. "🍔"
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
}
