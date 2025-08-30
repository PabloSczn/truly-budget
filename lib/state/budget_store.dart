import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/month_budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/currency.dart';

class BudgetStore extends ChangeNotifier {
  final Map<String, MonthBudget> _budgets = {}; // key: YYYY-MM
  String? selectedYMKey;
  Currency currency = const Currency('GBP', '£');
  bool initialized = false;

  MonthBudget? get currentBudget =>
      selectedYMKey == null ? null : _budgets[selectedYMKey]!;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currency_code');
    final ym = prefs.getString('selected_ym');
    if (code != null) currency = Currencies.byCode(code);
    selectedYMKey = ym;
    initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', currency.code);
    if (selectedYMKey != null) {
      await prefs.setString('selected_ym', selectedYMKey!);
    }
  }

  void changeCurrency(Currency c) {
    currency = c;
    _persist();
    notifyListeners();
  }

  void selectMonth(int year, int month) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    _budgets.putIfAbsent(key, () => MonthBudget(year: year, month: month));
    selectedYMKey = key;
    _persist();
    notifyListeners();
  }

  // Categories
  Category addCategory(String name, String emoji) {
    final cat = Category(
      id: _rid(),
      name: name.trim(),
      emoji: emoji.trim().isEmpty ? '📦' : emoji.trim(),
    );
    currentBudget!.categories.add(cat);
    notifyListeners();
    return cat;
  }

  void allocateByAmounts(Map<String, double> amounts) {
    final b = currentBudget!;
    final available = max(0.0, b.spare);
    double totalAdd = 0;
    for (final v in amounts.values) {
      if (v.isNaN) continue;
      totalAdd += v;
    }
    if (totalAdd > available + 1e-6) {
      throw Exception('Allocation exceeds available income.');
    }
    for (final entry in amounts.entries) {
      final cat = b.categories.firstWhere((c) => c.id == entry.key);
      cat.allocated += entry.value;
    }
    notifyListeners();
  }

  void allocateByPercents(Map<String, double> percents) {
    final b = currentBudget!;
    final available = max(0.0, b.spare);
    double pctSum = 0;
    for (final p in percents.values) {
      pctSum += p;
    }
    if (pctSum > 100 + 1e-6) {
      throw Exception('Total percentage cannot exceed 100%.');
    }
    final amounts = <String, double>{};
    percents.forEach((id, p) {
      amounts[id] = available * (p / 100);
    });
    allocateByAmounts(amounts);
  }

  void addIncome(String source, double amount) {
    currentBudget!.incomes.add(Income(source: source, amount: amount));
    notifyListeners();
  }

  void addExpense(String categoryId, String note, double amount) {
    final b = currentBudget!;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    cat.expenses.add(Expense(note: note, amount: amount));
    notifyListeners();
  }

  // Year overview helpers
  double totalIncomeFor(int year, int month) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final b = _budgets[key];
    return b?.totalIncome ?? 0.0;
  }

  double totalExpenseFor(int year, int month) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final b = _budgets[key];
    if (b == null) return 0.0;
    double total = 0;
    for (final c in b.categories) {
      total += c.spent;
    }
    return total;
  }

  // simple random id
  String _rid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + Random().nextInt(8999)).toString();
}
