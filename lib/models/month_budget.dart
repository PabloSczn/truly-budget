import 'category.dart';
import 'income.dart';

class MonthBudget {
  final int year;
  final int month; // 1-12
  final List<Income> incomes;
  final List<Category> categories;

  MonthBudget({
    required this.year,
    required this.month,
    List<Income>? incomes,
    List<Category>? categories,
  })  : incomes = incomes ?? [],
        categories = categories ?? [];

  double get totalIncome => incomes.fold(0.0, (s, i) => s + i.amount);
  double get totalAllocated => categories.fold(0.0, (s, c) => s + c.allocated);
  double get spare => totalIncome - totalAllocated;

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'incomes': incomes.map((i) => i.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  factory MonthBudget.fromJson(Map<String, dynamic> json) => MonthBudget(
        year: json['year'] as int,
        month: json['month'] as int,
        incomes: (json['incomes'] as List<dynamic>? ?? const [])
            .map((i) => Income.fromJson(i as Map<String, dynamic>))
            .toList(),
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
