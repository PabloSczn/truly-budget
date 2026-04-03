import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/screens/allocate_income_screen.dart';
import 'package:truly_budget/screens/month_screen.dart';
import 'package:truly_budget/state/budget_store.dart';
import 'package:truly_budget/utils/format.dart';

void main() {
  Widget buildTestApp(BudgetStore store, Widget child) {
    return ChangeNotifierProvider<BudgetStore>.value(
      value: store,
      child: MaterialApp(home: child),
    );
  }

  group('AllocateIncomeScreen', () {
    testWidgets(
      'does not queue duplicate over-allocation snackbars while one is visible',
      (tester) async {
        final store = BudgetStore();
        store.createMonth(2026, 3, select: true);
        store.addIncome('Salary', 100);
        store.addCategory('Groceries', '🛒', allocated: 60);

        await tester.pumpWidget(
          buildTestApp(store, const AllocateIncomeScreen()),
        );

        await tester.enterText(find.byType(TextField), '101');
        await tester.pump();

        await tester.tap(find.text('Save allocations'));
        await tester.pump();
        await tester.tap(find.text('Save allocations'));
        await tester.pump();

        expect(
          find.text('Total allocations exceed total income'),
          findsOneWidget,
        );

        final screenContext = tester.element(find.byType(AllocateIncomeScreen));
        ScaffoldMessenger.of(screenContext).hideCurrentSnackBar();
        await tester.pumpAndSettle();

        expect(
          find.text('Total allocations exceed total income'),
          findsNothing,
        );
      },
    );
  });

  group('MonthScreen', () {
    testWidgets(
      'shows the spare-money tip only after at least one expense exists and keeps dismissal behavior',
      (tester) async {
        final store = BudgetStore();
        store.createMonth(2026, 3, select: true);
        store.addIncome('Salary', 100);

        await tester.pumpWidget(buildTestApp(store, const MonthScreen()));

        expect(find.textContaining('You still have '), findsNothing);

        final savings = store.addCategory('Savings', '💰', allocated: 0);
        store.addExpense(savings.id, 'Transfer', 20);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('You still have '), findsOneWidget);

        await tester.tap(find.byTooltip('Dismiss tip'));
        await tester.pumpAndSettle();

        expect(find.textContaining('You still have '), findsNothing);

        store.addExpense(savings.id, 'Another transfer', 5);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('You still have '), findsNothing);
      },
    );

    testWidgets(
      'shows over-budget categories as an expandable card below income records',
      (tester) async {
        final store = BudgetStore();
        store.createMonth(2026, 3, select: true);
        store.addIncome('Salary', 200);

        final groceries = store.addCategory('Groceries', '🛒', allocated: 50);
        final transport = store.addCategory('Transport', '🚌', allocated: 30);

        store.addExpense(groceries.id, 'Shop', 70);
        store.addExpense(transport.id, 'Fuel', 45);

        await tester.pumpWidget(buildTestApp(store, const MonthScreen()));

        final incomeRecords = find.text('Income records');
        final overBudgetCategories = find.text('Over-budget categories');

        expect(incomeRecords, findsOneWidget);
        expect(overBudgetCategories, findsOneWidget);
        expect(
          tester.getTopLeft(overBudgetCategories).dy,
          greaterThan(tester.getTopLeft(incomeRecords).dy),
        );

        final overBudgetCard = find.ancestor(
          of: overBudgetCategories,
          matching: find.byType(Card),
        );
        final collapsedHeight = tester.getSize(overBudgetCard.first).height;
        final groceriesOverBudget =
            '+ ${Format.money(20, symbol: store.currency.symbol)}';
        final transportOverBudget =
            '+ ${Format.money(15, symbol: store.currency.symbol)}';

        await tester.tap(overBudgetCategories);
        await tester.pumpAndSettle();

        final expandedHeight = tester.getSize(overBudgetCard.first).height;
        expect(expandedHeight, greaterThan(collapsedHeight));
        expect(find.text(groceriesOverBudget), findsOneWidget);
        expect(find.text(transportOverBudget), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'renamed uncategorized category is not treated as over-budget',
      (tester) async {
        final store = BudgetStore();
        store.createMonth(2026, 3, select: true);

        final uncategorized = store.ensureUncategorizedForCurrentBudget();
        store.addExpense(uncategorized.id, 'Coffee', 4.5);
        store.updateCategory(uncategorized.id, name: 'Floating expenses');
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(buildTestApp(store, const MonthScreen()));

        expect(find.text('Over-budget categories'), findsNothing);
        expect(find.text('Floating expenses'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting no category still adds expenses to the renamed uncategorized category',
      (tester) async {
        final store = BudgetStore();
        store.createMonth(2026, 3, select: true);

        final uncategorized = store.ensureUncategorizedForCurrentBudget();
        store.updateCategory(uncategorized.id, name: 'Floating expenses');
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(buildTestApp(store, const MonthScreen()));

        await tester.tap(find.byTooltip('Open quick actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add expense'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Parking');
        await tester.enterText(find.byType(TextFormField).at(1), '8');
        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();

        expect(store.currentBudget!.categories, hasLength(1));
        expect(store.currentBudget!.categories.single.id, uncategorized.id);
        expect(
            store.currentBudget!.categories.single.name, 'Floating expenses');
        expect(
          store.isUncategorizedCategory(store.currentBudget!.categories.single),
          isTrue,
        );
        expect(store.currentBudget!.categories.single.expenses, hasLength(1));
        expect(
          store.currentBudget!.categories.single.expenses.single.note,
          'Parking',
        );
      },
    );
  });
}
