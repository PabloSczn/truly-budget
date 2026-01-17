import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  // File persistence
  File? _dbFile;
  Timer? _saveDebounce;

  UnmodifiableMapView<String, MonthBudget> get budgets =>
      UnmodifiableMapView(_budgets);

  MonthBudget? get currentBudget =>
      selectedYMKey == null ? null : _budgets[selectedYMKey];

  String _keyOf(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  Future<void> load() async {
    // Prepare file
    final dir = await getApplicationDocumentsDirectory();
    _dbFile = File('${dir.path}/budgets.json');

    if (await _dbFile!.exists()) {
      try {
        final raw = await _dbFile!.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final map = (data['budgets'] as Map<String, dynamic>? ?? {});
        _budgets.clear();
        map.forEach((k, v) {
          _budgets[k] = MonthBudget.fromJson(v as Map<String, dynamic>);
        });
        final code = data['currency_code'] as String?;
        if (code != null) currency = Currencies.byCode(code);
        selectedYMKey = data['selected_ym'] as String?;
      } catch (_) {
        // If file is corrupted, keep empty state
      }
    } else {
      // Fallback to previous prefs
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('currency_code');
      final ym = prefs.getString('selected_ym');
      if (code != null) currency = Currencies.byCode(code);
      selectedYMKey = ym;
      await _save();
    }

    initialized = true;
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'currency_code': currency.code,
        'selected_ym': selectedYMKey,
        'budgets': _budgets.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  Future<void> _save() async {
    if (_dbFile == null) return;
    final tmp = File('${_dbFile!.path}.tmp');
    await tmp.writeAsString(jsonEncode(_toJson()));
    if (await _dbFile!.exists()) {
      await _dbFile!.delete();
    }
    await tmp.rename(_dbFile!.path);
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () {
      // fire-and-forget
      _save();
    });
  }

  void changeCurrency(Currency c) {
    currency = c;
    _scheduleSave();
    notifyListeners();
  }

  void selectMonth(int year, int month) {
    final key = _keyOf(year, month);
    _budgets.putIfAbsent(key, () => MonthBudget(year: year, month: month));
    selectedYMKey = key;
    _scheduleSave();
    notifyListeners();
  }

  // Categories
  Category addCategory(String name, String emoji) {
    final cat = Category(
      id: _rid(),
      name: name.trim(),
      emoji: emoji.trim().isEmpty ? '🗂️' : emoji.trim(),
    );
    currentBudget!.categories.add(cat);
    _scheduleSave();
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
    _scheduleSave();
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

  /// Replace category allocations with the provided totals (not incremental)
  void setAllocationsByAmounts(Map<String, double> newAllocatedByCategoryId) {
    final b = currentBudget!;
    double newTotalAllocated = 0.0;

    for (final c in b.categories) {
      final v = newAllocatedByCategoryId[c.id] ?? c.allocated;
      if (v.isNaN || v.isInfinite || v < 0) {
        throw Exception('Invalid allocation for "${c.name}".');
      }
      newTotalAllocated += v;
    }

    if (newTotalAllocated > b.totalIncome + 1e-6) {
      throw Exception('Total allocations exceed total income.');
    }

    for (final c in b.categories) {
      if (newAllocatedByCategoryId.containsKey(c.id)) {
        c.allocated = newAllocatedByCategoryId[c.id]!;
      }
    }

    _scheduleSave();
    notifyListeners();
  }

  /// Replace allocations by percentages of TOTAL income
  void setAllocationsByPercents(Map<String, double> percentsByCategoryId) {
    final b = currentBudget!;
    final totalIncome = b.totalIncome;

    final amounts = <String, double>{};
    percentsByCategoryId.forEach((id, pct) {
      final p = (pct.isNaN || pct.isInfinite || pct < 0) ? 0.0 : pct;
      amounts[id] = totalIncome <= 0 ? 0.0 : totalIncome * (p / 100.0);
    });

    setAllocationsByAmounts(amounts);
  }

  void addIncome(String source, double amount) {
    currentBudget!.incomes.add(Income(source: source, amount: amount));
    _scheduleSave();
    notifyListeners();
  }

  void addExpense(String categoryId, String note, double amount,
      {String? emoji}) {
    final b = currentBudget!;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    cat.expenses.add(Expense(note: note, amount: amount, emoji: emoji));
    _scheduleSave();
    notifyListeners();
  }

  void updateExpense(
    String categoryId,
    int expenseIndex, {
    String? note,
    double? amount,
    DateTime? date,
    String? emoji,
  }) {
    final b = currentBudget!;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    if (expenseIndex < 0 || expenseIndex >= cat.expenses.length) return;
    final old = cat.expenses[expenseIndex];
    cat.expenses[expenseIndex] = Expense(
      note: note ?? old.note,
      amount: amount ?? old.amount,
      emoji: emoji ?? old.emoji,
      date: date ?? old.date,
    );
    _scheduleSave();
    notifyListeners();
  }

  // Delete a single expense by index from a category
  void removeExpense(String categoryId, int expenseIndex) {
    final b = currentBudget!;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    if (expenseIndex >= 0 && expenseIndex < cat.expenses.length) {
      cat.expenses.removeAt(expenseIndex);
      _scheduleSave();
      notifyListeners();
    }
  }

  // Year overview helpers
  double totalIncomeFor(int year, int month) {
    final b = _budgets[_keyOf(year, month)];
    return b?.totalIncome ?? 0.0;
  }

  double totalExpenseFor(int year, int month) {
    final b = _budgets[_keyOf(year, month)];
    if (b == null) return 0.0;
    double total = 0;
    for (final c in b.categories) {
      total += c.spent;
    }
    return total;
  }

  // List of month keys
  List<String> get monthKeysDesc {
    final keys = _budgets.keys.toList()..sort();
    return keys.reversed.toList();
  }

  // simple random id
  String _rid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + Random().nextInt(8999)).toString();
}
