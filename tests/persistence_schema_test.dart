import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/models/currency.dart';
import 'package:truly_budget/state/budget_store.dart';

void main() {
  group('Persistent storage schema', () {
    test('keeps the budgets.json schema stable', () {
      // This persisted JSON schema mustn't change without an explicit
      // migration plan and backward-compatibility review.
      final store = BudgetStore()
        ..currency = const Currency('USD', '\$')
        ..themeMode = ThemeMode.dark;

      final marchIncomeDate = DateTime.parse('2026-03-31T08:30:00.000');
      final marchExpenseDate = DateTime.parse('2026-03-31T09:45:00.000');
      final aprilIncomeDate = DateTime.parse('2026-04-01T08:00:00.000');
      final aprilExpenseDate = DateTime.parse('2026-04-01T10:15:00.000');
      final aprilDebtDate = DateTime.parse('2026-04-01T12:00:00.000');

      store.dismissTip('welcome-banner');
      store.createMonth(2026, 3, select: true);
      store.addIncome('Salary', 1000);
      store.updateIncome(0, date: marchIncomeDate);

      final rent = store.addCategory('Rent', '🏠', allocated: 900);
      store.addExpense(rent.id, 'Monthly rent', 1100, emoji: '🏡');
      store.updateExpense(
        rent.id,
        0,
        date: marchExpenseDate,
        emoji: '🏡',
      );

      expect(
        store.carryDebtForwardToNextMonth(
          '2026-03',
          createNextMonthIfMissing: true,
        ),
        CarryForwardDebtResult.success,
      );

      store.completeMonth('2026-03');
      store.selectMonth(2026, 4);
      store.addIncome('Bonus', 200);
      store.updateIncome(0, date: aprilIncomeDate);

      final aprilCurrent = store.currentBudget!;
      final uncategorized = aprilCurrent.categories.singleWhere(
        (category) => category.name == 'Uncategorized',
      );
      store.updateExpense(
        uncategorized.id,
        0,
        date: aprilDebtDate,
      );

      final travel = store.addCategory('Travel', '✈️', allocated: 50);
      store.addExpense(travel.id, 'Train tickets', 25, emoji: '🚆');
      store.updateExpense(
        travel.id,
        0,
        date: aprilExpenseDate,
        emoji: '🚆',
      );
      // This must NOT change
      expect(
        store.exportData(),
        equals({
          'currency_code': 'USD',
          'theme_mode': 'dark',
          'selected_ym': '2026-04',
          'dismissed_tips': ['welcome-banner'],
          'budgets': {
            '2026-03': {
              'year': 2026,
              'month': 3,
              'incomes': [
                {
                  'source': 'Salary',
                  'amount': 1000.0,
                  'date': marchIncomeDate.toIso8601String(),
                },
              ],
              'categories': [
                {
                  'id': rent.id,
                  'name': 'Rent',
                  'emoji': '🏠',
                  'allocated': 900.0,
                  'expenses': [
                    {
                      'note': 'Monthly rent',
                      'amount': 1100.0,
                      'emoji': '🏡',
                      'date': marchExpenseDate.toIso8601String(),
                    },
                  ],
                },
              ],
              'is_completed': true,
              'carried_debt_to_key': '2026-04',
              'carried_debt_amount': 100.0,
            },
            '2026-04': {
              'year': 2026,
              'month': 4,
              'incomes': [
                {
                  'source': 'Bonus',
                  'amount': 200.0,
                  'date': aprilIncomeDate.toIso8601String(),
                },
              ],
              'categories': [
                {
                  'id': uncategorized.id,
                  'name': 'Uncategorized',
                  'emoji': '🗂️',
                  'allocated': 0.0,
                  'expenses': [
                    {
                      'note': 'March 2026',
                      'amount': 100.0,
                      'emoji': '💸',
                      'date': aprilDebtDate.toIso8601String(),
                    },
                  ],
                },
                {
                  'id': travel.id,
                  'name': 'Travel',
                  'emoji': '✈️',
                  'allocated': 50.0,
                  'expenses': [
                    {
                      'note': 'Train tickets',
                      'amount': 25.0,
                      'emoji': '🚆',
                      'date': aprilExpenseDate.toIso8601String(),
                    },
                  ],
                },
              ],
              'is_completed': false,
              'carried_debt_to_key': null,
              'carried_debt_amount': 0.0,
            },
          },
        }),
      );
    });
  });
}
