import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/models/category.dart';
import 'package:truly_budget/models/expense.dart';
import 'package:truly_budget/utils/format.dart';
import 'package:truly_budget/widgets/category_card.dart';

void main() {
  testWidgets('over-budget category shows the negative amount left in red',
      (tester) async {
    const currencySymbol = r'$';
    final category = Category(
      id: 'groceries',
      name: 'Groceries',
      emoji: 'G',
      allocated: 50,
      expenses: [
        Expense(note: 'Shop', amount: 70),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: category,
            isUncategorized: false,
            currencySymbol: currencySymbol,
          ),
        ),
      ),
    );

    expect(
      find.text('Left: ${Format.money(0, symbol: currencySymbol)}'),
      findsNothing,
    );

    expect(
      find.text('Overspent: ${Format.money(20, symbol: currencySymbol)}'),
      findsNothing,
    );

    final negativeLeftText =
        find.text('Left: ${Format.money(-20, symbol: currencySymbol)}');
    expect(negativeLeftText, findsOneWidget);

    final textWidget = tester.widget<Text>(negativeLeftText);
    expect(textWidget.style?.color, Colors.red.shade700);
  });
}
