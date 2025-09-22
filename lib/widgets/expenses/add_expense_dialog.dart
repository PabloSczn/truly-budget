import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_store.dart';
import '../emoji_prefix_button.dart';
import '../emoji_selector.dart';

class AddExpenseDialog extends StatefulWidget {
  final String categoryId;
  const AddExpenseDialog({super.key, required this.categoryId});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final noteCtrl = TextEditingController(text: 'Expense');
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
    return AlertDialog(
      title: const Text('Add expense'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: 'What for?',
              prefixIcon:
                  EmojiPrefixButton(emoji: leadingEmoji, onTap: _pickEmoji),
              prefixIconConstraints: const BoxConstraints(
                  minWidth: 44, minHeight: 44, maxWidth: 52),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a note' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: amountCtrl,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final d = double.tryParse(v?.replaceAll(',', '.') ?? '');
              if (d == null || d <= 0) return 'Enter a valid amount';
              return null;
            },
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
