import 'package:flutter_test/flutter_test.dart';
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
            'Exception: Total allocations exceeded total income',
          ),
        ),
      );
    });
  });
}
