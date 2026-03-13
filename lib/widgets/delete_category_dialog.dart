import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/format.dart';

enum DeleteCategoryExpenseAction { moveExpenses, deleteExpenses }

class DeleteCategoryResult {
  final DeleteCategoryExpenseAction action;
  final String? targetCategoryId;

  const DeleteCategoryResult({
    required this.action,
    this.targetCategoryId,
  });
}

class DeleteCategoryDialog extends StatefulWidget {
  final Category category;
  final List<Category> otherCategories;
  final String currencySymbol;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.otherCategories,
    required this.currencySymbol,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  late DeleteCategoryExpenseAction _action;
  String? _targetCategoryId;
  final _formKey = GlobalKey<FormState>();

  bool get _hasExpenses => widget.category.expenses.isNotEmpty;
  bool get _canMoveExpenses => widget.otherCategories.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _action = _hasExpenses && _canMoveExpenses
        ? DeleteCategoryExpenseAction.moveExpenses
        : DeleteCategoryExpenseAction.deleteExpenses;
    _targetCategoryId =
        _canMoveExpenses ? widget.otherCategories.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final expenseCount = widget.category.expenses.length;
    final expenseTotal = widget.category.spent;

    return AlertDialog(
      title: Text('Delete ${widget.category.name}?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hasExpenses
                  ? 'This category has $expenseCount expense${expenseCount == 1 ? '' : 's'} worth ${Format.money(expenseTotal, symbol: widget.currencySymbol)}.'
                  : 'This category has no expenses. Its limit and history on this screen will be removed.',
            ),
            if (_hasExpenses) ...[
              const SizedBox(height: 16),
              SegmentedButton<DeleteCategoryExpenseAction>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<DeleteCategoryExpenseAction>(
                    value: DeleteCategoryExpenseAction.moveExpenses,
                    label: const Text('Move expenses'),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    enabled: _canMoveExpenses,
                  ),
                  const ButtonSegment<DeleteCategoryExpenseAction>(
                    value: DeleteCategoryExpenseAction.deleteExpenses,
                    label: Text('Delete all'),
                    icon: Icon(Icons.delete_outline_rounded),
                  ),
                ],
                selected: <DeleteCategoryExpenseAction>{_action},
                onSelectionChanged: (selection) {
                  final nextAction = selection.first;
                  if (nextAction == DeleteCategoryExpenseAction.moveExpenses &&
                      !_canMoveExpenses) {
                    return;
                  }
                  setState(() => _action = nextAction);
                },
              ),
              const SizedBox(height: 12),
              if (_action == DeleteCategoryExpenseAction.moveExpenses &&
                  _canMoveExpenses)
                DropdownButtonFormField<String>(
                  initialValue: _targetCategoryId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Move expenses to'),
                  items: [
                    for (final category in widget.otherCategories)
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Text('${category.emoji}  ${category.name}'),
                      ),
                  ],
                  validator: (value) => value == null
                      ? 'Choose a category for these expenses'
                      : null,
                  onChanged: (value) =>
                      setState(() => _targetCategoryId = value),
                )
              else if (_action == DeleteCategoryExpenseAction.moveExpenses)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'There are no other categories available, so these expenses will be deleted with the category.',
                  ),
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
            if (_hasExpenses &&
                _action == DeleteCategoryExpenseAction.moveExpenses &&
                !_formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(
              context,
              DeleteCategoryResult(
                action: _action,
                targetCategoryId:
                    _action == DeleteCategoryExpenseAction.moveExpenses
                        ? _targetCategoryId
                        : null,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete category'),
        ),
      ],
    );
  }
}
