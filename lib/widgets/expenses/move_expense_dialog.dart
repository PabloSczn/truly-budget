import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/expense.dart';
import '../../utils/format.dart';

class MoveExpenseDialog extends StatefulWidget {
  final Expense expense;
  final List<Category> otherCategories;
  final String currencySymbol;

  const MoveExpenseDialog({
    super.key,
    required this.expense,
    required this.otherCategories,
    required this.currencySymbol,
  });

  @override
  State<MoveExpenseDialog> createState() => _MoveExpenseDialogState();
}

class _MoveExpenseDialogState extends State<MoveExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _targetCategoryId;

  @override
  void initState() {
    super.initState();
    _targetCategoryId =
        widget.otherCategories.isEmpty ? null : widget.otherCategories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move expense'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move ${widget.expense.emoji}  ${widget.expense.note} for ${Format.money(widget.expense.amount, symbol: widget.currencySymbol)} to another category.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _targetCategoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Move to'),
              items: [
                for (final category in widget.otherCategories)
                  DropdownMenuItem<String>(
                    value: category.id,
                    child: Text('${category.emoji}  ${category.name}'),
                  ),
              ],
              validator: (value) =>
                  value == null ? 'Choose a category for this expense' : null,
              onChanged: (value) => setState(() => _targetCategoryId = value),
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
            Navigator.pop(context, _targetCategoryId);
          },
          child: const Text('Move expense'),
        ),
      ],
    );
  }
}
