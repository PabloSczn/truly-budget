import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../utils/format.dart';
import '../widgets/expenses/add_expense_dialog.dart';
import '../widgets/expenses/edit_expense_dialog.dart';

enum _CategoryBudgetTone { healthy, warning, danger, overBudget }

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final canEdit = !b.isCompleted;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);
    final isUncategorized = cat.name.trim().toLowerCase() == 'uncategorized';

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
                    'Less than 50% of this category has been spent.',
                  )
                : rawRatio <= 0.8
                    ? (
                        _CategoryBudgetTone.warning,
                        'Keep an eye on it',
                        'Between 51% and 80% of this category is already used.',
                      )
                    : (
                        _CategoryBudgetTone.danger,
                        'Close to the limit',
                        'More than 80% of this category has been spent.',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: canEdit
          ? FloatingActionButton(
              tooltip: 'Add expense',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => AddExpenseDialog(categoryId: categoryId),
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
          Text('Expenses', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: cat.expenses.length,
              itemBuilder: (_, i) {
                final e = cat.expenses[i];
                return ListTile(
                  leading: Text(e.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(e.note),
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
                    store.updateExpense(categoryId, i,
                        note: newNote, amount: newAmount, emoji: newEmoji);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Expense updated')));
                  },
                  onLongPress: () async {
                    if (!canEdit) return;
                    final store = context.read<BudgetStore>();
                    final messenger = ScaffoldMessenger.of(context);
                    final action = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => SafeArea(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          ListTile(
                            leading: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: const Text('Delete expense',
                                style: TextStyle(color: Colors.red)),
                            onTap: () => Navigator.pop(context, 'delete'),
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            leading: const Icon(Icons.close),
                            title: const Text('Cancel'),
                            onTap: () => Navigator.pop(context, 'cancel'),
                          ),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    );
                    if (!context.mounted || action != 'delete') return;

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
                    store.removeExpense(categoryId, i);
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
