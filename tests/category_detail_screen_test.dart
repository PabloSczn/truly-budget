import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/screens/category_detail_screen.dart';
import 'package:truly_budget/state/budget_store.dart';

void main() {
  Widget buildTestApp(BudgetStore store, Widget child) {
    return ChangeNotifierProvider<BudgetStore>.value(
      value: store,
      child: MaterialApp(home: child),
    );
  }

  testWidgets('long pressing an expense can move it to another category',
      (tester) async {
    final store = BudgetStore();
    store.createMonth(2026, 3, select: true);
    final groceries = store.addCategory('Groceries', '🛒');
    final dining = store.addCategory('Dining', '🍽️');
    store.addExpense(groceries.id, 'Milk', 12.5, emoji: '🥛');

    await tester.pumpWidget(
      buildTestApp(
        store,
        CategoryDetailScreen(categoryId: groceries.id),
      ),
    );

    expect(find.text('Milk'), findsOneWidget);

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(find.text('Move to category'), findsOneWidget);

    await tester.tap(find.text('Move to category'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Move expense'));
    await tester.pumpAndSettle();

    expect(groceries.expenses, isEmpty);
    expect(dining.expenses, hasLength(1));
    expect(dining.expenses.single.note, 'Milk');
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Expense moved to Dining'), findsOneWidget);
  });
}
