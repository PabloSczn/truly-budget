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
import '../utils/year_month.dart';

enum CarryForwardDebtResult {
  success,
  monthMissing,
  monthHasNoDebt,
  debtAlreadyCarried,
  nextMonthMissing,
  nextMonthCompleted,
}

class BudgetStore extends ChangeNotifier {
  final Map<String, MonthBudget> _budgets = {}; // key: YYYY-MM
  final Set<String> _dismissedTipIds = <String>{};
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

  (int, int) _partsFromKey(String ymKey) {
    final parts = ymKey.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid month key: $ymKey');
    }
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  String nextMonthKeyOf(String ymKey) {
    final (year, month) = _partsFromKey(ymKey);
    if (month == 12) {
      return _keyOf(year + 1, 1);
    }
    return _keyOf(year, month + 1);
  }

  bool hasMonthKey(String ymKey) => _budgets.containsKey(ymKey);

  bool hasNextMonthCreated(String ymKey) => hasMonthKey(nextMonthKeyOf(ymKey));

  bool isMonthCompleted(String ymKey) => _budgets[ymKey]?.isCompleted ?? false;

  double debtForMonthKey(String ymKey) {
    final b = _budgets[ymKey];
    if (b == null) return 0.0;
    return debtForBudget(b);
  }

  double debtForBudget(MonthBudget budget) {
    final expenses = budget.categories.fold<double>(0.0, (s, c) => s + c.spent);
    final debt = expenses - budget.totalIncome;
    return debt > 0 ? debt : 0.0;
  }

  Category _ensureUncategorized(MonthBudget b) {
    for (final c in b.categories) {
      if (c.name.trim().toLowerCase() == 'uncategorized') return c;
    }
    final cat = Category(
      id: _rid(),
      name: 'Uncategorized',
      emoji: '🗂️',
    );
    b.categories.add(cat);
    return cat;
  }

  void _assertEditable(MonthBudget b) {
    if (b.isCompleted) {
      throw Exception(
          'This month is completed. Reopen it before making changes.');
    }
  }

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
        _dismissedTipIds
          ..clear()
          ..addAll(
            (data['dismissed_tips'] as List<dynamic>? ?? [])
                .whereType<String>(),
          );
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
        'dismissed_tips': _dismissedTipIds.toList()..sort(),
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

  bool isTipDismissed(String tipId) => _dismissedTipIds.contains(tipId);

  void dismissTip(String tipId) {
    if (_dismissedTipIds.add(tipId)) {
      _scheduleSave();
      notifyListeners();
    }
  }

  void createMonth(int year, int month, {bool select = false}) {
    final key = _keyOf(year, month);
    _budgets.putIfAbsent(key, () => MonthBudget(year: year, month: month));
    if (select) {
      selectedYMKey = key;
    }
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

  bool completeMonth(String ymKey) {
    final b = _budgets[ymKey];
    if (b == null) return false;
    if (b.isCompleted) return true;
    b.isCompleted = true;
    if (selectedYMKey == ymKey) {
      final activeKeys = activeMonthKeysDesc;
      selectedYMKey = activeKeys.isNotEmpty ? activeKeys.first : null;
    }
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool reopenMonth(String ymKey) {
    final b = _budgets[ymKey];
    if (b == null) return false;
    if (!b.isCompleted) return true;
    b.isCompleted = false;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool deleteMonth(String ymKey) {
    final removed = _budgets.remove(ymKey);
    if (removed == null) return false;
    if (selectedYMKey == ymKey) {
      final activeKeys = activeMonthKeysDesc;
      selectedYMKey = activeKeys.isNotEmpty ? activeKeys.first : null;
    }
    for (final b in _budgets.values) {
      if (b.carriedDebtToKey == ymKey) {
        b.carriedDebtToKey = null;
        b.carriedDebtAmount = 0.0;
      }
    }
    _scheduleSave();
    notifyListeners();
    return true;
  }

  CarryForwardDebtResult carryDebtForwardToNextMonth(
    String ymKey, {
    bool createNextMonthIfMissing = false,
  }) {
    final source = _budgets[ymKey];
    if (source == null) return CarryForwardDebtResult.monthMissing;
    final debt = debtForBudget(source);
    if (debt <= 0) return CarryForwardDebtResult.monthHasNoDebt;
    if ((source.carriedDebtToKey ?? '').isNotEmpty &&
        source.carriedDebtAmount > 0) {
      return CarryForwardDebtResult.debtAlreadyCarried;
    }

    final nextKey = nextMonthKeyOf(ymKey);
    MonthBudget? target = _budgets[nextKey];
    if (target == null) {
      if (!createNextMonthIfMissing) {
        return CarryForwardDebtResult.nextMonthMissing;
      }
      final (nextYear, nextMonth) = _partsFromKey(nextKey);
      target = MonthBudget(year: nextYear, month: nextMonth);
      _budgets[nextKey] = target;
    }

    final targetBudget = target;
    if (targetBudget.isCompleted) {
      return CarryForwardDebtResult.nextMonthCompleted;
    }

    final uncategorized = _ensureUncategorized(targetBudget);
    final (year, month) = _partsFromKey(ymKey);
    uncategorized.expenses.add(
      Expense(
        note: YearMonth(year, month).label,
        amount: debt,
        emoji: '💸',
      ),
    );
    source.carriedDebtToKey = nextKey;
    source.carriedDebtAmount = debt;
    _scheduleSave();
    notifyListeners();
    return CarryForwardDebtResult.success;
  }

  // Categories
  Category addCategory(String name, String emoji) {
    _assertEditable(currentBudget!);
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
    _assertEditable(b);
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
    _assertEditable(b);
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
    _assertEditable(b);
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
    _assertEditable(b);
    final totalIncome = b.totalIncome;

    final amounts = <String, double>{};
    percentsByCategoryId.forEach((id, pct) {
      final p = (pct.isNaN || pct.isInfinite || pct < 0) ? 0.0 : pct;
      amounts[id] = totalIncome <= 0 ? 0.0 : totalIncome * (p / 100.0);
    });

    setAllocationsByAmounts(amounts);
  }

  void addIncome(String source, double amount) {
    _assertEditable(currentBudget!);
    currentBudget!.incomes.add(Income(source: source, amount: amount));
    _scheduleSave();
    notifyListeners();
  }

  void addExpense(String categoryId, String note, double amount,
      {String? emoji}) {
    final b = currentBudget!;
    _assertEditable(b);
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
    _assertEditable(b);
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
    _assertEditable(b);
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

  List<String> get activeMonthKeysDesc {
    final keys = _budgets.entries
        .where((e) => !e.value.isCompleted)
        .map((e) => e.key)
        .toList()
      ..sort();
    return keys.reversed.toList();
  }

  List<String> get completedMonthKeysDesc {
    final keys = _budgets.entries
        .where((e) => e.value.isCompleted)
        .map((e) => e.key)
        .toList()
      ..sort();
    return keys.reversed.toList();
  }

  // simple random id
  String _rid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + Random().nextInt(8999)).toString();
}
