import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/state/budget_store.dart';
import 'package:truly_budget/widgets/edit_category_dialog.dart';

void main() {
  Widget buildTestApp(BudgetStore store, Widget child) {
    return ChangeNotifierProvider<BudgetStore>.value(
      value: store,
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'uncategorized categories cannot edit emoji or limit',
    (tester) async {
      final store = BudgetStore();

      await tester.pumpWidget(
        buildTestApp(
          store,
          const EditCategoryDialog(
            initialName: 'Floating expenses',
            initialEmoji: '🗂️',
            initialAllocated: 0,
            allowEmojiEditing: false,
            showLimitField: false,
          ),
        ),
      );

      expect(find.byTooltip('Choose emoji'), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Floating expenses'), findsOneWidget);
    },
  );
}
