import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/screens/add_income_screen.dart';
import 'package:truly_budget/state/budget_store.dart';
import 'package:truly_budget/widgets/expenses/add_expense_dialog.dart';
import 'package:truly_budget/widgets/expenses/add_expense_quick_dialog.dart';

void main() {
  Widget buildTestApp(BudgetStore store, Widget child) {
    return ChangeNotifierProvider<BudgetStore>.value(
      value: store,
      child: MaterialApp(home: child),
    );
  }

  Finder emojiSearchField() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search or paste an emoji…',
    );
  }

  testWidgets('changing the income emoji does not alter the income source',
      (tester) async {
    final store = BudgetStore();
    store.createMonth(2026, 4, select: true);

    await tester.pumpWidget(
      buildTestApp(
        store,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddIncomeScreen(),
                    ),
                  );
                },
                child: const Text('Open income form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open income form'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose emoji'));
    await tester.pumpAndSettle();

    await tester.enterText(emojiSearchField(), 'savings');
    await tester.pumpAndSettle();
    await tester.tap(find.text('💰'));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '100');
    await tester.tap(find.widgetWithText(FilledButton, 'Add income'));
    await tester.pumpAndSettle();

    expect(store.currentBudget!.incomes.single.source, 'Salary');
  });

  testWidgets('expense dialog starts with a placeholder and normal text input',
      (tester) async {
    final store = BudgetStore();
    store.createMonth(2026, 4, select: true);
    final category = store.addCategory('Groceries', '🛒');

    await tester.pumpWidget(
      buildTestApp(
        store,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AddExpenseDialog(categoryId: category.id),
                  );
                },
                child: const Text('Open expense dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open expense dialog'));
    await tester.pumpAndSettle();

    final noteField = find.byType(TextFormField).first;
    final noteTextField = find.byType(TextField).first;
    final initialNoteTextField = tester.widget<TextField>(noteTextField);
    expect(initialNoteTextField.controller?.text, isEmpty);
    expect(initialNoteTextField.autocorrect, isTrue);
    expect(initialNoteTextField.enableSuggestions, isTrue);
    expect(initialNoteTextField.decoration?.hintText, 'Expense');
    expect(initialNoteTextField.onTap, isNotNull);

    await tester.tap(noteField);
    await tester.pump();

    final focusedNoteTextField = tester.widget<TextField>(noteTextField);
    expect(focusedNoteTextField.controller?.text, isEmpty);
    expect(focusedNoteTextField.onTap, isNotNull);

    final editableText =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editableText.controller.text, isEmpty);
    expect(editableText.controller.selection.isCollapsed, isTrue);

    focusedNoteTextField.controller?.value = const TextEditingValue(
      text: 'Test name',
      selection: TextSelection(baseOffset: 5, extentOffset: 9),
    );
    focusedNoteTextField.onTap?.call();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      focusedNoteTextField.controller?.selection.isCollapsed,
      isTrue,
    );
    expect(focusedNoteTextField.controller?.text, 'Test name');

    await tester.enterText(noteField, 'Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), '4.50');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(category.expenses.single.note, 'Coffee');
  });

  testWidgets(
      'quick expense dialog starts with a placeholder and normal text input',
      (tester) async {
    final store = BudgetStore();
    store.createMonth(2026, 4, select: true);
    final category = store.addCategory('Transport', '🚌');
    QuickExpenseInput? result;

    await tester.pumpWidget(
      buildTestApp(
        store,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<QuickExpenseInput>(
                    context: context,
                    builder: (_) => QuickAddExpenseDialog(
                      categories: [category],
                    ),
                  ).then((value) => result = value);
                },
                child: const Text('Open quick expense dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open quick expense dialog'));
    await tester.pumpAndSettle();

    final noteField = find.byType(TextFormField).first;
    final noteTextField = find.byType(TextField).first;
    final initialNoteTextField = tester.widget<TextField>(noteTextField);
    expect(initialNoteTextField.controller?.text, isEmpty);
    expect(initialNoteTextField.autocorrect, isTrue);
    expect(initialNoteTextField.enableSuggestions, isTrue);
    expect(initialNoteTextField.decoration?.hintText, 'Expense');
    expect(initialNoteTextField.onTap, isNotNull);

    await tester.tap(noteField);
    await tester.pump();

    final focusedNoteTextField = tester.widget<TextField>(noteTextField);
    expect(focusedNoteTextField.controller?.text, isEmpty);
    expect(focusedNoteTextField.onTap, isNotNull);

    final editableText =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editableText.controller.text, isEmpty);
    expect(editableText.controller.selection.isCollapsed, isTrue);

    focusedNoteTextField.controller?.value = const TextEditingValue(
      text: 'Test name',
      selection: TextSelection(baseOffset: 5, extentOffset: 9),
    );
    focusedNoteTextField.onTap?.call();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      focusedNoteTextField.controller?.selection.isCollapsed,
      isTrue,
    );
    expect(focusedNoteTextField.controller?.text, 'Test name');

    await tester.enterText(noteField, 'Train ticket');
    await tester.enterText(find.byType(TextFormField).at(1), '8');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(result?.note, 'Train ticket');
  });
}
