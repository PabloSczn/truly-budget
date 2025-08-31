import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/widgets/emoji_selector.dart';
import '../state/budget_store.dart';
import '../utils/format.dart';

class _EmojiPrefixButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const _EmojiPrefixButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 20,
        onPressed: onTap,
        tooltip: 'Choose emoji',
        // Nudge the emoji slightly down to align with the text baseline
        icon: Transform.translate(
          offset: const Offset(1, 7),
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 22,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final cat = b.categories.firstWhere((c) => c.id == categoryId);

    final spent = cat.spent;
    final allocated = cat.allocated;
    final remaining = cat.remaining;
    final ratio = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;

    MaterialColor statusColor;
    String statusText;

    if (ratio <= 0.5) {
      statusColor = Colors.green;
      statusText = 'Great! Less than 50% spent.';
    } else if (ratio <= 0.8) {
      statusColor = Colors.orange;
      statusText = 'Heads up: 51–80% spent.';
    } else {
      statusColor = Colors.red;
      statusText = 'Warning: 81–100% spent.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${cat.name} — ${cat.emoji}'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add expense',
        onPressed: remaining <= 0
            ? null
            : () async {
                await showDialog(
                  context: context,
                  builder: (_) => _AddExpenseDialog(categoryId: categoryId),
                );
              },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocated vs Spent',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            Card(
              color: statusColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(statusText,
                    style: TextStyle(color: statusColor.shade700)),
              ),
            ),
            if (remaining <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'No more money is available for this category.',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            const SizedBox(height: 16),
            Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: cat.expenses.length,
                itemBuilder: (_, i) {
                  final e = cat.expenses[i];
                  return ListTile(
                    title: Text(e.note),
                    trailing: Text(
                        Format.money(e.amount, symbol: store.currency.symbol)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final String categoryId;
  const _AddExpenseDialog({required this.categoryId});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
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

  Future<void> _insertEmojiFromPicker() async {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'What for?',
                prefixIcon: _EmojiPrefixButton(
                  emoji: leadingEmoji,
                  onTap: _insertEmojiFromPicker,
                ),
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
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (d == null || d <= 0) return 'Enter a valid amount';
                return null;
              },
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
            if (_formKey.currentState!.validate()) {
              final store = context.read<BudgetStore>();
              final d = double.parse(amountCtrl.text.replaceAll(',', '.'));
              store.addExpense(widget.categoryId, noteCtrl.text.trim(), d);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        )
      ],
    );
  }
}
