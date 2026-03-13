import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/budget_store.dart';
import '../emoji_prefix_button.dart';
import '../emoji_selector.dart';
import '../money_amount_form_field.dart';

class EditExpenseDialog extends StatefulWidget {
  final String initialNote;
  final double initialAmount;
  final String initialEmoji;
  const EditExpenseDialog({
    super.key,
    required this.initialNote,
    required this.initialAmount,
    required this.initialEmoji,
  });

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  late final TextEditingController noteCtrl;
  late final TextEditingController amountCtrl;
  late final FocusNode amountFocusNode;
  final _formKey = GlobalKey<FormState>();
  late String leadingEmoji;

  @override
  void initState() {
    super.initState();
    noteCtrl = TextEditingController(text: widget.initialNote);
    amountCtrl =
        TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
    amountFocusNode = FocusNode();
    leadingEmoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    amountCtrl.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final e = await pickEmoji(context);
    if (!mounted || e == null || e.isEmpty) return;
    setState(() => leadingEmoji = e);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<BudgetStore>().currency.symbol;
    return AlertDialog(
      title: const Text('Edit expense'),
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
          MoneyAmountFormField(
            controller: amountCtrl,
            currencySymbol: currencySymbol,
            focusNode: amountFocusNode,
            selectAllOnFocus: true,
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
              final d = double.parse(amountCtrl.text.replaceAll(',', '.'));
              Navigator.pop<(String, double, String)>(
                  context, (noteCtrl.text.trim(), d, leadingEmoji));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
