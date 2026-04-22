import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_store.dart';
import '../emoji_selector.dart';
import '../money_amount_form_field.dart';
import 'expense_note_form_field.dart';

class AddExpenseDialog extends StatefulWidget {
  final String categoryId;
  const AddExpenseDialog({super.key, required this.categoryId});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final noteCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String leadingEmoji = '🧾';

  @override
  void dispose() {
    noteCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final e = await pickEmoji(context);
    if (e == null || e.isEmpty) return;
    setState(() => leadingEmoji = e);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<BudgetStore>().currency.symbol;
    return AlertDialog(
      title: const Text('Add expense'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExpenseNoteFormField(
            controller: noteCtrl,
            emoji: leadingEmoji,
            onPickEmoji: _pickEmoji,
          ),
          const SizedBox(height: 8),
          MoneyAmountFormField(
            controller: amountCtrl,
            currencySymbol: currencySymbol,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final store = context.read<BudgetStore>();
              final d = double.parse(amountCtrl.text.replaceAll(',', '.'));
              store.addExpense(widget.categoryId, noteCtrl.text.trim(), d,
                  emoji: leadingEmoji);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
