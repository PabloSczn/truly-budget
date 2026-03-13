import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../emoji_prefix_button.dart';
import '../emoji_selector.dart';
import '../../models/category.dart';
import '../../state/budget_store.dart';
import '../money_amount_form_field.dart';

class QuickExpenseInput {
  final String note;
  final double amount;
  final String emoji;
  final String? categoryId;

  const QuickExpenseInput({
    required this.note,
    required this.amount,
    required this.emoji,
    required this.categoryId,
  });
}

class QuickAddExpenseDialog extends StatefulWidget {
  final List<Category> categories;

  const QuickAddExpenseDialog({
    super.key,
    required this.categories,
  });

  @override
  State<QuickAddExpenseDialog> createState() => _QuickAddExpenseDialogState();
}

class _QuickAddExpenseDialogState extends State<QuickAddExpenseDialog> {
  final noteCtrl = TextEditingController(text: 'Expense');
  final amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String leadingEmoji = '🧾';
  String? selectedCategoryId;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'What for?',
                prefixIcon:
                    EmojiPrefixButton(emoji: leadingEmoji, onTap: _pickEmoji),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 52,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a note'
                  : null,
            ),
            const SizedBox(height: 8),
            MoneyAmountFormField(
              controller: amountCtrl,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: selectedCategoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              hint: const Text('Select category (optional)'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'No category',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
                for (final c in widget.categories)
                  DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(
                      '${c.emoji}  ${c.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => selectedCategoryId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final amount = double.parse(amountCtrl.text.replaceAll(',', '.'));
            Navigator.pop(
              context,
              QuickExpenseInput(
                note: noteCtrl.text.trim(),
                amount: amount,
                emoji: leadingEmoji,
                categoryId: selectedCategoryId,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
