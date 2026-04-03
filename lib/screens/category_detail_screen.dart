import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../state/budget_store.dart';
import '../utils/format.dart';
import '../widgets/bottom_banner_ad.dart';
import '../widgets/expenses/add_expense_dialog.dart';
import '../widgets/expenses/edit_expense_dialog.dart';
import '../widgets/expenses/move_expense_dialog.dart';

enum _CategoryBudgetTone { healthy, warning, danger, overBudget }

enum _ExpenseAction { move, delete, cancel }

enum _ExpenseDateSortOrder { ascending, descending }

class CategoryDetailScreen extends StatefulWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _showExpenseDates = false;
  _ExpenseDateSortOrder _expenseSortOrder = _ExpenseDateSortOrder.ascending;

  List<({int index, Expense expense})> _sortedExpenses(List<Expense> expenses) {
    final indexedExpenses = List.generate(
      expenses.length,
      (index) => (index: index, expense: expenses[index]),
      growable: false,
    );

    indexedExpenses.sort((a, b) {
      final comparison = a.expense.date.compareTo(b.expense.date);
      if (comparison != 0) {
        return _expenseSortOrder == _ExpenseDateSortOrder.ascending
            ? comparison
            : -comparison;
      }

      return _expenseSortOrder == _ExpenseDateSortOrder.ascending
          ? a.index.compareTo(b.index)
          : b.index.compareTo(a.index);
    });

    return indexedExpenses;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final canEdit = !b.isCompleted;
    final cat = b.categories.firstWhere((c) => c.id == widget.categoryId);
    final otherCategories = b.categories
        .where((c) => c.id != widget.categoryId)
        .toList(growable: false);
    final isUncategorized = store.isUncategorizedCategory(cat, budget: b);
    final expenseItems = _sortedExpenses(cat.expenses);

    final spent = cat.spent;
    final allocated = cat.allocated;
    final remaining = cat.remaining;
    final rawRatio = allocated > 0 ? spent / allocated : 0.0;
    final ratio = rawRatio.clamp(0.0, 1.0);

    final (_CategoryBudgetTone tone, String statusTitle, String statusBody) =
        rawRatio > 1.0
            ? (
                _CategoryBudgetTone.overBudget,
                'Over budget',
                'You have spent more than this category was allocated.',
              )
            : rawRatio <= 0.5
                ? (
                    _CategoryBudgetTone.healthy,
                    'On track',
                    'Less than 50% of this category has been spent',
                  )
                : rawRatio <= 0.8
                    ? (
                        _CategoryBudgetTone.warning,
                        'Keep an eye on it',
                        'Between 51% and 80% of this category is already used',
                      )
                    : (
                        _CategoryBudgetTone.danger,
                        'Close to the limit',
                        'More than 80% of this category has been spent',
                      );

    final statusColor = switch (tone) {
      _CategoryBudgetTone.healthy => Colors.green,
      _CategoryBudgetTone.warning => Colors.orange,
      _CategoryBudgetTone.danger => Colors.red,
      _CategoryBudgetTone.overBudget => Colors.deepOrange,
    };
    final statusIcon = switch (tone) {
      _CategoryBudgetTone.healthy => Icons.check_circle_outline,
      _CategoryBudgetTone.warning => Icons.pie_chart_outline,
      _CategoryBudgetTone.danger => Icons.error_outline,
      _CategoryBudgetTone.overBudget => Icons.warning_amber_rounded,
    };
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusBackground = Color.alphaBlend(
        statusColor.withValues(alpha: 0.1), colorScheme.surface);

    return Scaffold(
      appBar: AppBar(title: Text('${cat.name} ${cat.emoji}')),
      bottomNavigationBar: const BottomBannerAd(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: canEdit
          ? FloatingActionButton(
              tooltip: 'Add expense',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) =>
                      AddExpenseDialog(categoryId: widget.categoryId),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!canEdit) ...[
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('This completed month is read-only.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (!isUncategorized) ...[
            Text('Allocated vs Spent', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 14,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Allocated: ${Format.money(allocated, symbol: store.currency.symbol)}'),
                Text(
                    'Spent: ${Format.money(spent, symbol: store.currency.symbol)}'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: statusBackground,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (remaining <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text('No more money is available for this category.',
                    style: TextStyle(color: Colors.red.shade600)),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Expenses', style: theme.textTheme.titleMedium),
              const Spacer(),
              SizedBox.square(
                dimension: 32,
                child: IconButton(
                  tooltip: _showExpenseDates ? 'Hide dates' : 'Show dates',
                  onPressed: cat.expenses.isEmpty
                      ? null
                      : () => setState(() {
                            _showExpenseDates = !_showExpenseDates;
                          }),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: Icon(
                    _showExpenseDates
                        ? Icons.event_available_outlined
                        : Icons.event_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox.square(
                dimension: 32,
                child: IconButton(
                  tooltip: _expenseSortOrder == _ExpenseDateSortOrder.ascending
                      ? 'Sort newest first'
                      : 'Sort oldest first',
                  onPressed: cat.expenses.length < 2
                      ? null
                      : () => setState(() {
                            _expenseSortOrder = _expenseSortOrder ==
                                    _ExpenseDateSortOrder.ascending
                                ? _ExpenseDateSortOrder.descending
                                : _ExpenseDateSortOrder.ascending;
                          }),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: Icon(
                    _expenseSortOrder == _ExpenseDateSortOrder.ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: expenseItems.length,
              itemBuilder: (_, i) {
                final item = expenseItems[i];
                final e = item.expense;
                final expenseIndex = item.index;
                return ListTile(
                  leading: Text(e.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(e.note),
                  subtitle: _showExpenseDates
                      ? Text(
                          Format.dayMonth(e.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: Text(
                      Format.money(e.amount, symbol: store.currency.symbol)),
                  onTap: () async {
                    if (!canEdit) return;
                    final store = context.read<BudgetStore>();
                    final messenger = ScaffoldMessenger.of(context);
                    final edited = await showDialog<(String, double, String)?>(
                      context: context,
                      builder: (_) => EditExpenseDialog(
                        initialNote: e.note,
                        initialAmount: e.amount,
                        initialEmoji: e.emoji,
                      ),
                    );
                    if (!context.mounted || edited == null) return;
                    final (newNote, newAmount, newEmoji) = edited;
                    store.updateExpense(widget.categoryId, expenseIndex,
                        note: newNote, amount: newAmount, emoji: newEmoji);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Expense updated')));
                  },
                  onLongPress: () async {
                    if (!canEdit) return;
                    final store = context.read<BudgetStore>();
                    final messenger = ScaffoldMessenger.of(context);
                    final action = await showModalBottomSheet<_ExpenseAction>(
                      context: context,
                      showDragHandle: true,
                      builder: (sheetContext) => SafeArea(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.drive_file_move_outline),
                            title: const Text('Move to category'),
                            subtitle: otherCategories.isEmpty
                                ? const Text('Add another category first')
                                : null,
                            enabled: otherCategories.isNotEmpty,
                            onTap: otherCategories.isEmpty
                                ? null
                                : () => Navigator.pop(
                                      sheetContext,
                                      _ExpenseAction.move,
                                    ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: const Text('Delete expense',
                                style: TextStyle(color: Colors.red)),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _ExpenseAction.delete,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            leading: const Icon(Icons.close),
                            title: const Text('Cancel'),
                            onTap: () => Navigator.pop(
                              sheetContext,
                              _ExpenseAction.cancel,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    );
                    if (!context.mounted || action == null) return;

                    if (action == _ExpenseAction.move) {
                      final targetCategoryId = await showDialog<String>(
                        context: context,
                        builder: (_) => MoveExpenseDialog(
                          expense: e,
                          otherCategories: otherCategories,
                          currencySymbol: store.currency.symbol,
                        ),
                      );
                      if (!context.mounted || targetCategoryId == null) return;

                      store.moveExpense(
                        widget.categoryId,
                        expenseIndex,
                        targetCategoryId,
                      );
                      final movedTo = otherCategories.firstWhere(
                        (category) => category.id == targetCategoryId,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Expense moved to ${movedTo.name}'),
                        ),
                      );
                      return;
                    }

                    if (action != _ExpenseAction.delete) return;

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete expense?'),
                        content: Text(
                            'This will remove:\n\n${e.emoji}  ${e.note}\n'
                            '${Format.money(e.amount, symbol: store.currency.symbol)}'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted || confirm != true) return;
                    store.removeExpense(widget.categoryId, expenseIndex);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Expense deleted')));
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
