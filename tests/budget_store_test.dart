import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/models/currency.dart';
import 'package:truly_budget/state/budget_store.dart';

void main() {
  group('BudgetStore zero-income category limits', () {
    late BudgetStore store;

    setUp(() {
      store = BudgetStore();
      store.createMonth(2026, 3, select: true);
    });

    test('allows adding a category limit before income exists', () {
      final category = store.addCategory(
        'Groceries',
        '🛒',
        allocated: 250,
      );

      expect(store.currentBudget!.categories, hasLength(1));
      expect(category.allocated, 250);
    });

    test('allows updating a category limit while income is still zero', () {
      final category = store.addCategory(
        'Transport',
        '🚌',
        allocated: 50,
      );

      store.updateCategory(category.id, allocated: 120);

      expect(store.currentBudget!.categories.single.allocated, 120);
    });

    test('treats zero-income expenses as debt', () {
      final category = store.addCategory(
        'Bills',
        '💡',
        allocated: 100,
      );

      store.addExpense(category.id, 'Electricity', 40);

      expect(store.debtForBudget(store.currentBudget!), 40);
    });

    test('moves an expense to another category', () {
      final groceries = store.addCategory(
        'Groceries',
        '🛒',
      );
      final dining = store.addCategory(
        'Dining',
        '🍽️',
      );

      store.addExpense(groceries.id, 'Milk', 12.5, emoji: '🥛');
      store.moveExpense(groceries.id, 0, dining.id);

      expect(groceries.expenses, isEmpty);
      expect(dining.expenses, hasLength(1));
      expect(dining.expenses.single.note, 'Milk');
      expect(dining.expenses.single.amount, 12.5);
      expect(dining.expenses.single.emoji, '🥛');
    });

    test('requires a different category when moving an expense', () {
      final groceries = store.addCategory(
        'Groceries',
        '🛒',
      );

      store.addExpense(groceries.id, 'Milk', 12.5);

      expect(
        () => store.moveExpense(groceries.id, 0, groceries.id),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            'Exception: Choose another category for this expense.',
          ),
        ),
      );
    });

    test('uses the updated allocation overflow message', () {
      store.addIncome('Salary', 100);
      final groceries = store.addCategory(
        'Groceries',
        '🛒',
        allocated: 60,
      );

      expect(
        () => store.setAllocationsByAmounts({
          groceries.id: 101,
        }),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            'Exception: Total allocations exceed total income',
          ),
        ),
      );
    });

    test('keeps uncategorized behavior after renaming the category', () {
      final uncategorized = store.ensureUncategorizedForCurrentBudget();
      store.addExpense(uncategorized.id, 'Coffee', 4.5);

      store.updateCategory(
        uncategorized.id,
        name: 'Floating expenses',
        emoji: '☕',
        allocated: 25,
      );

      final updated = store.currentBudget!.categories.single;
      expect(updated.name, 'Floating expenses');
      expect(updated.emoji, BudgetStore.uncategorizedEmoji);
      expect(updated.allocated, 0);
      expect(store.isUncategorizedCategory(updated), isTrue);
      expect(store.debtForBudget(store.currentBudget!), 4.5);
    });

    test('routes no-category expenses to the renamed uncategorized category',
        () {
      final uncategorized = store.ensureUncategorizedForCurrentBudget();
      store.updateCategory(uncategorized.id, name: 'Floating expenses');

      final categoryId = store.resolveExpenseCategoryId(null);
      store.addExpense(categoryId, 'Parking', 8);

      final updated = store.currentBudget!.categories.single;
      expect(categoryId, uncategorized.id);
      expect(updated.name, 'Floating expenses');
      expect(store.isUncategorizedCategory(updated), isTrue);
      expect(updated.expenses.single.note, 'Parking');
    });
  });

  group('BudgetStore JSON import', () {
    late BudgetStore store;

    setUp(() {
      store = BudgetStore();
    });

    test('only flags populated overlapping months for overwrite confirmation',
        () {
      store.createMonth(2026, 3);
      store.createMonth(2026, 4, select: true);
      store.addIncome('Salary', 1200);

      final importedStore = BudgetStore()
        ..createMonth(2026, 3, select: true)
        ..createMonth(2026, 4, select: true)
        ..addIncome('Replacement income', 800);

      final preview = store.prepareImportJson(
        jsonEncode(importedStore.exportData()),
      );

      expect(preview.overwrittenMonthKeys, equals(['2026-04']));
    });

    test('replaces imported months and keeps unrelated existing months',
        () async {
      store.dismissTip('current-tip');
      store.currency = const Currency('GBP', '£');
      store.themeMode = ThemeMode.light;

      store.createMonth(2026, 4, select: true);
      store.addIncome('Old salary', 100);
      final groceries = store.addCategory('Groceries', '🛒', allocated: 40);
      store.addExpense(groceries.id, 'Bread', 10);

      store.createMonth(2026, 5, select: true);
      store.addCategory('Utilities', '💡', allocated: 30);

      final importedStore = BudgetStore()
        ..dismissTip('welcome-banner')
        ..currency = const Currency('USD', '\$')
        ..themeMode = ThemeMode.dark;

      importedStore.createMonth(2026, 4, select: true);
      importedStore.addIncome('New salary', 250);
      final rent = importedStore.addCategory('Rent', '🏠', allocated: 150);
      importedStore.addExpense(rent.id, 'April rent', 150);

      importedStore.createMonth(2026, 6, select: true);
      importedStore.addCategory('Travel', '✈️', allocated: 75);

      final preview = store.prepareImportJson(
        jsonEncode(importedStore.exportData()),
      );

      expect(preview.overwrittenMonthKeys, equals(['2026-04']));

      await store.importPreparedData(preview);

      expect(store.currency.code, 'USD');
      expect(store.themeMode, ThemeMode.dark);
      expect(store.isTipDismissed('current-tip'), isTrue);
      expect(store.isTipDismissed('welcome-banner'), isTrue);
      expect(store.selectedYMKey, '2026-06');
      expect(store.monthKeysDesc, equals(['2026-06', '2026-05', '2026-04']));

      final aprilBudget = store.budgets['2026-04']!;
      expect(aprilBudget.incomes, hasLength(1));
      expect(aprilBudget.incomes.single.source, 'New salary');
      expect(aprilBudget.categories, hasLength(1));
      expect(aprilBudget.categories.single.name, 'Rent');
      expect(aprilBudget.categories.single.expenses.single.note, 'April rent');

      final mayBudget = store.budgets['2026-05']!;
      expect(mayBudget.categories, hasLength(1));
      expect(mayBudget.categories.single.name, 'Utilities');

      final juneBudget = store.budgets['2026-06']!;
      expect(juneBudget.categories, hasLength(1));
      expect(juneBudget.categories.single.name, 'Travel');
    });
  });
}
