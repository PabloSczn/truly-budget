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

  testWidgets('expenses can show dates and sort by date', (tester) async {
    final store = BudgetStore();
    store.createMonth(2026, 4, select: true);
    final groceries = store.addCategory('Groceries', '🛒');

    store.addExpense(groceries.id, 'Recent expense', 18);
    store.updateExpense(
      groceries.id,
      0,
      date: DateTime(2026, 4, 9, 18, 30),
    );

    store.addExpense(groceries.id, 'Older expense', 7);
    store.updateExpense(
      groceries.id,
      1,
      date: DateTime(2026, 4, 6, 9, 15),
    );

    await tester.pumpWidget(
      buildTestApp(
        store,
        CategoryDetailScreen(categoryId: groceries.id),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Older expense')).dy,
      lessThan(tester.getTopLeft(find.text('Recent expense')).dy),
    );
    expect(find.text('6 April'), findsNothing);
    expect(find.text('9 April'), findsNothing);

    await tester.tap(find.byTooltip('Show dates'));
    await tester.pumpAndSettle();

    expect(find.text('6 April'), findsOneWidget);
    expect(find.text('9 April'), findsOneWidget);

    await tester.tap(find.byTooltip('Sort newest first'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Recent expense')).dy,
      lessThan(tester.getTopLeft(find.text('Older expense')).dy),
    );
  });
}
