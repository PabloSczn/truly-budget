import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import '../widgets/category_card.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/expenses/add_expense_quick_dialog.dart';
import '../utils/format.dart';
import '../utils/year_month.dart';
import 'add_income_screen.dart';
import 'allocate_income_screen.dart';
import 'category_detail_screen.dart';
import '../widgets/app_menu_drawer.dart';
import '../widgets/dismissible_tip_banner.dart';

const _monthSpareTipId = 'month_spare_tip';

class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (_) => const AddCategoryDialog(),
    );
    if (!mounted || result == null) return;
    final (name, emoji) = result;
    context.read<BudgetStore>().addCategory(name, emoji);
  }

  String _resolveCategoryForExpense(BudgetStore store, String? categoryId) {
    final b = store.currentBudget!;
    if (categoryId != null && b.categories.any((c) => c.id == categoryId)) {
      return categoryId;
    }

    Category? uncategorized;
    for (final c in b.categories) {
      if (c.name.trim().toLowerCase() == 'uncategorized') {
        uncategorized = c;
        break;
      }
    }

    return (uncategorized ?? store.addCategory('Uncategorized', '🗂️')).id;
  }

  Future<void> _showAddExpenseDialog() async {
    final store = context.read<BudgetStore>();
    final b = store.currentBudget;
    if (b == null) return;

    final result = await showDialog<QuickExpenseInput?>(
      context: context,
      builder: (_) => QuickAddExpenseDialog(categories: b.categories),
    );
    if (!mounted || result == null) return;

    final categoryId = _resolveCategoryForExpense(store, result.categoryId);
    store.addExpense(
      categoryId,
      result.note,
      result.amount,
      emoji: result.emoji,
    );
  }

  Future<void> _carryDebtForwardFromCurrentMonth() async {
    final store = context.read<BudgetStore>();
    final b = store.currentBudget;
    if (b == null) return;
    if (b.isCompleted) return;

    final ymKey = YearMonth(b.year, b.month).key;
    final debt = store.debtForBudget(b);
    if (debt <= 0) return;

    final nextMonthLabel = YearMonth.labelFromKey(store.nextMonthKeyOf(ymKey));
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carry debt forward?'),
        content: Text(
          'Move ${Format.money(debt, symbol: store.currency.symbol)} to $nextMonthLabel as an expense in Uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Carry forward'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    final result = store.carryDebtForwardToNextMonth(ymKey);
    if (!mounted) return;

    switch (result) {
      case CarryForwardDebtResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debt carried to $nextMonthLabel.')),
        );
        break;
      case CarryForwardDebtResult.nextMonthMissing:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Create $nextMonthLabel first to carry debt forward.',
            ),
          ),
        );
        break;
      case CarryForwardDebtResult.nextMonthCompleted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$nextMonthLabel is completed. Reopen it before carrying debt.',
            ),
          ),
        );
        break;
      case CarryForwardDebtResult.debtAlreadyCarried:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt was already carried forward.')),
        );
        break;
      case CarryForwardDebtResult.monthHasNoDebt:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This month has no debt to carry.')),
        );
        break;
      case CarryForwardDebtResult.monthMissing:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Month not found.')),
        );
        break;
    }
  }

  Color _statusColor(double income, double expenses) {
    if (income == 0 && expenses == 0) return Colors.blueGrey.shade200;
    if (income <= 0 && expenses > 0) return Colors.red;
    final ratio = income <= 0 ? 1.0 : expenses / income;
    if (ratio <= 0.6) return Colors.green;
    if (ratio <= 1.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final canEdit = !b.isCompleted;
    final ymKey = YearMonth(b.year, b.month).key;
    final ymLabel = YearMonth(b.year, b.month).label;
    final totalExpenses = b.categories.fold<double>(0.0, (s, c) => s + c.spent);
    final remainingAfterExpenses = b.totalIncome - totalExpenses;
    final overallDebt = (totalExpenses - b.totalIncome) > 0
        ? (totalExpenses - b.totalIncome)
        : 0.0;
    final overCats = b.categories
        .where((c) =>
            c.name.trim().toLowerCase() != 'uncategorized' &&
            c.spent > c.allocated)
        .toList();
    final statusColor = _statusColor(b.totalIncome, totalExpenses);
    final ratio = b.totalIncome <= 0
        ? 1.0
        : (totalExpenses / b.totalIncome).clamp(0.0, 1.0);
    final canOpenAllocate =
        canEdit && ((b.totalIncome > 0) || (b.totalAllocated > 0));
    final nextMonthLabel = YearMonth.labelFromKey(store.nextMonthKeyOf(ymKey));
    final hasNextMonth = store.hasNextMonthCreated(ymKey);
    final debtAlreadyCarried =
        (b.carriedDebtToKey ?? '').isNotEmpty && b.carriedDebtAmount > 0;
    final carriedToLabel =
        debtAlreadyCarried ? YearMonth.labelFromKey(b.carriedDebtToKey!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ymLabel),
        actions: const [CurrencySelectorAction()],
      ),
      drawer: const AppMenuDrawer(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: canEdit
          ? _QuickAddFab(
              onAddExpense: _showAddExpenseDialog,
              onAddCategory: _showAddCategoryDialog,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                      child: Text(
                        'This month budget is completed. It is now read-only.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Income vs Expenses summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 12,
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Income: ${Format.money(b.totalIncome, symbol: store.currency.symbol)}'),
                      Text(
                          'Expenses: ${Format.money(totalExpenses, symbol: store.currency.symbol)}'),
                    ],
                  ),
                  if (overallDebt > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined,
                              color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Debt this month: ${Format.money(overallDebt, symbol: store.currency.symbol)}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canEdit && debtAlreadyCarried) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Debt already carried to $carriedToLabel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else if (canEdit && hasNextMonth) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _carryDebtForwardFromCurrentMonth,
                          icon: const Icon(Icons.forward),
                          label: Text('Carry debt to $nextMonthLabel'),
                        ),
                      ),
                    ] else if (canEdit) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Create $nextMonthLabel to carry this debt forward.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (overCats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Over-budget categories',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    for (final c in overCats)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${c.emoji}  ${c.name}'),
                            Text(
                              '+ ${Format.money((c.spent - c.allocated), symbol: store.currency.symbol)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: !canEdit
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddIncomeScreen(),
                                ),
                              );
                            },
                      child: const Text('Add income'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: !canOpenAllocate
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AllocateIncomeScreen(),
                                ),
                              );
                            },
                      child: const Text('Allocate funds'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (remainingAfterExpenses > 0 &&
              !store.isTipDismissed(_monthSpareTipId))
            DismissibleTipBanner(
              message:
                  'You still have ${Format.money(remainingAfterExpenses, symbol: store.currency.symbol)} left this month! If you want to save money, you could create a savings category and record these as an expense so you force yourself to save.',
              onClose: () {
                context.read<BudgetStore>().dismissTip(_monthSpareTipId);
              },
            ),
          const SizedBox(height: 8),
          if (b.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18.0),
              child: Text(
                  'Nothing here yet. Add an expense or category to get started.'),
            ),
          ...b.categories.map((c) => CategoryCard(
                category: c,
                currencySymbol: store.currency.symbol,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(categoryId: c.id),
                    ),
                  );
                },
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _QuickAddFab extends StatefulWidget {
  final Future<void> Function() onAddExpense;
  final Future<void> Function() onAddCategory;

  const _QuickAddFab({
    required this.onAddExpense,
    required this.onAddCategory,
  });

  @override
  State<_QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<_QuickAddFab> {
  bool _isOpen = false;

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isOpen = false);
    await action();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: 0,
            bottom: 72,
            child: IgnorePointer(
              ignoring: !_isOpen,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _isOpen ? Offset.zero : const Offset(0, 0.12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _isOpen ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _QuickActionChip(
                        icon: Icons.category_outlined,
                        label: 'Add category',
                        onPressed: () => _runAction(widget.onAddCategory),
                      ),
                      const SizedBox(height: 10),
                      _QuickActionChip(
                        icon: Icons.receipt_long_outlined,
                        label: 'Add expense',
                        onPressed: () => _runAction(widget.onAddExpense),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: 'month_quick_add_fab',
            tooltip: _isOpen ? 'Close quick actions' : 'Open quick actions',
            onPressed: () => setState(() => _isOpen = !_isOpen),
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      color: colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
