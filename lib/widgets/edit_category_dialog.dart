import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/budget_store.dart';
import 'emoji_prefix_button.dart';
import 'emoji_selector.dart';
import 'money_amount_form_field.dart';

class EditCategoryResult {
  final String name;
  final String emoji;
  final double allocated;

  const EditCategoryResult({
    required this.name,
    required this.emoji,
    required this.allocated,
  });
}

class EditCategoryDialog extends StatefulWidget {
  final String initialName;
  final String initialEmoji;
  final double initialAllocated;
  final bool allowEmojiEditing;
  final bool showLimitField;

  const EditCategoryDialog({
    super.key,
    required this.initialName,
    required this.initialEmoji,
    required this.initialAllocated,
    this.allowEmojiEditing = true,
    this.showLimitField = true,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _limitCtrl;
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _limitCtrl =
        TextEditingController(text: widget.initialAllocated.toStringAsFixed(2));
    _selectedEmoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final emoji = await pickEmoji(context);
    if (!mounted || emoji == null || emoji.isEmpty) return;
    setState(() => _selectedEmoji = emoji);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<BudgetStore>().currency.symbol;
    return AlertDialog(
      title: const Text('Edit category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Category name',
                prefixIcon: widget.allowEmojiEditing
                    ? EmojiPrefixButton(
                        emoji: _selectedEmoji,
                        onTap: _pickEmoji,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _selectedEmoji,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, height: 1),
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 52,
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            if (widget.showLimitField) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitCtrl,
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
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              EditCategoryResult(
                name: _nameCtrl.text.trim(),
                emoji: _selectedEmoji,
                allocated: widget.showLimitField
                    ? double.parse(_limitCtrl.text.trim().replaceAll(',', '.'))
                    : widget.initialAllocated,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
