import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/widgets/emoji_selector.dart';

import '../state/budget_store.dart';
import 'money_amount_form_field.dart';

class AddCategoryResult {
  final String name;
  final String emoji;
  final double allocated;

  const AddCategoryResult({
    required this.name,
    required this.emoji,
    this.allocated = 0.0,
  });
}

class AddCategoryDialog extends StatefulWidget {
  final bool showLimitField;

  const AddCategoryDialog({
    super.key,
    this.showLimitField = false,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final nameCtrl = TextEditingController();
  final limitCtrl = TextEditingController(text: '0.00');
  String selectedEmoji = '🗂️';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final e = await pickEmoji(context);
    if (e != null && e.isNotEmpty) {
      setState(() => selectedEmoji = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<BudgetStore>().currency.symbol;
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickEmoji,
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(selectedEmoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),
                ),
              ],
            ),
            if (widget.showLimitField) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                decoration: moneyAmountInputDecoration(
                  context,
                  currencySymbol: currencySymbol,
                  labelText: 'Category limit',
                ),
                validator: (value) {
                  final amount =
                      double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
                  if (amount == null || amount < 0) {
                    return 'Enter zero or a valid amount';
                  }
                  return null;
                },
              ),
            ],
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
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                AddCategoryResult(
                  name: nameCtrl.text.trim(),
                  emoji: selectedEmoji,
                  allocated: widget.showLimitField
                      ? double.parse(limitCtrl.text.trim().replaceAll(',', '.'))
                      : 0.0,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
