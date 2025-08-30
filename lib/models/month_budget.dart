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
}
