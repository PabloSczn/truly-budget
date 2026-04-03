import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/income.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/category_card.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/delete_category_dialog.dart';
import '../widgets/edit_category_dialog.dart';
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
  String? _expandedIncomeRecordsMonthKey;
  String? _expandedOverBudgetCategoriesMonthKey;

  void _goHome() {
    context.read<BudgetStore>().clearSelectedMonth();
  }

  String _messageFromError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isEmpty ? 'Something went wrong.' : raw;
  }

  bool _areIncomeRecordsExpanded(String ymKey) {
    return _expandedIncomeRecordsMonthKey == ymKey;
  }

  void _toggleIncomeRecords(String ymKey) {
    setState(() {
      _expandedIncomeRecordsMonthKey =
          _expandedIncomeRecordsMonthKey == ymKey ? null : ymKey;
    });
  }

  bool _areOverBudgetCategoriesExpanded(String ymKey) {
    return _expandedOverBudgetCategoriesMonthKey == ymKey;
  }

  void _toggleOverBudgetCategories(String ymKey) {
    setState(() {
      _expandedOverBudgetCategoriesMonthKey =
          _expandedOverBudgetCategoriesMonthKey == ymKey ? null : ymKey;
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<AddCategoryResult>(
      context: context,
      builder: (_) => const AddCategoryDialog(showLimitField: true),
    );
    if (!mounted || result == null) return;
    try {
      context.read<BudgetStore>().addCategory(
            result.name,
            result.emoji,
            allocated: result.allocated,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    }
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

    final categoryId = store.resolveExpenseCategoryId(result.categoryId);
    store.addExpense(
      categoryId,
      result.note,
      result.amount,
      emoji: result.emoji,
    );
  }

  Future<void> _showIncomeEditor({int? incomeIndex}) async {
    final store = context.read<BudgetStore>();
    final b = store.currentBudget;
    if (b == null) return;

    Income? income;
    if (incomeIndex != null &&
        incomeIndex >= 0 &&
        incomeIndex < b.incomes.length) {
      income = b.incomes[incomeIndex];
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddIncomeScreen(
          incomeIndex: incomeIndex,
          initialSource: income?.source ?? 'Salary',
          initialAmount: income?.amount,
          initialDate: income?.date,
        ),
      ),
    );
  }

  Future<void> _showIncomeActions(int incomeIndex) async {
    final store = context.read<BudgetStore>();
    final b = store.currentBudget;
    if (b == null ||
        b.isCompleted ||
        incomeIndex < 0 ||
        incomeIndex >= b.incomes.length) {
      return;
    }

    final income = b.incomes[incomeIndex];
    final action = await showModalBottomSheet<_IncomeTileAction>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  title: const Text(
                    'Delete income',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _IncomeTileAction.delete,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _IncomeTileAction.cancel,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action != _IncomeTileAction.delete) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete income?'),
        content: Text(
          'This will remove:\n\n${income.source.trim().isEmpty ? 'Income' : income.source}\n${Format.money(income.amount, symbol: store.currency.symbol)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;

    try {
      store.removeIncome(incomeIndex);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    }
  }

  Future<void> _showCategoryActions(Category category) async {
    final action = await showModalBottomSheet<_CategoryTileAction>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _CategoryTileAction.edit,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _CategoryTileAction.delete,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _CategoryTileAction.cancel,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null || action == _CategoryTileAction.cancel) {
      return;
    }

    switch (action) {
      case _CategoryTileAction.edit:
        await _editCategory(category);
        break;
      case _CategoryTileAction.delete:
        await _deleteCategory(category);
        break;
      case _CategoryTileAction.cancel:
        break;
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<EditCategoryResult>(
      context: context,
      builder: (_) => EditCategoryDialog(
        initialName: category.name,
        initialEmoji: category.emoji,
        initialAllocated: category.allocated,
        allowEmojiEditing:
            !context.read<BudgetStore>().isUncategorizedCategory(category),
        showLimitField:
            !context.read<BudgetStore>().isUncategorizedCategory(category),
      ),
    );

    if (!mounted || result == null) return;

    try {
      context.read<BudgetStore>().updateCategory(
            category.id,
            name: result.name,
            emoji: result.emoji,
            allocated: result.allocated,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final store = context.read<BudgetStore>();
    final otherCategories = store.currentBudget!.categories
        .where((current) => current.id != category.id)
        .toList();
    final expenseCount = category.expenses.length;
    final deleteResult = await showDialog<DeleteCategoryResult>(
      context: context,
      builder: (_) => DeleteCategoryDialog(
        category: category,
        otherCategories: otherCategories,
        currencySymbol: store.currency.symbol,
      ),
    );

    if (!mounted || deleteResult == null) return;

    try {
      store.removeCategory(
        category.id,
        moveExpensesToCategoryId: deleteResult.targetCategoryId,
        deleteExpenses:
            deleteResult.action == DeleteCategoryExpenseAction.deleteExpenses,
      );
      if (!mounted) return;

      final moveTargetName = otherCategories
          .where((current) => current.id == deleteResult.targetCategoryId)
          .map((current) => current.name)
          .fold<String?>(null, (_, name) => name);
      final message = deleteResult.action ==
                  DeleteCategoryExpenseAction.moveExpenses &&
              expenseCount > 0
          ? 'Category deleted and $expenseCount expense${expenseCount == 1 ? '' : 's'} moved to ${moveTargetName ?? 'the selected category'}.'
          : 'Category deleted';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
    final b = store.currentBudget;
    if (b == null) {
      return const SizedBox.shrink();
    }
    final canEdit = !b.isCompleted;
    final ymKey = YearMonth(b.year, b.month).key;
    final ymLabel = YearMonth(b.year, b.month).label;
    final debtAlreadyCarried = store.hasCarriedDebt(b);
    final effectiveExpenses = store.effectiveExpenseForBudget(b);
    final remainingAfterExpenses = store.effectiveBalanceForBudget(b);
    final overallDebt = store.debtForBudget(b);
    final overCats = b.categories
        .where((c) =>
            !store.isUncategorizedCategory(c, budget: b) &&
            c.spent > c.allocated)
        .toList();
    final statusColor = _statusColor(b.totalIncome, effectiveExpenses);
    final ratio = b.totalIncome <= 0
        ? 1.0
        : (effectiveExpenses / b.totalIncome).clamp(0.0, 1.0);
    final canOpenAllocate =
        canEdit && ((b.totalIncome > 0) || (b.totalAllocated > 0));
    final nextMonthLabel = YearMonth.labelFromKey(store.nextMonthKeyOf(ymKey));
    final hasNextMonth = store.hasNextMonthCreated(ymKey);
    final carriedToLabel =
        debtAlreadyCarried ? YearMonth.labelFromKey(b.carriedDebtToKey!) : null;
    final isIncomeRecordsExpanded = _areIncomeRecordsExpanded(ymKey);
    final isOverBudgetCategoriesExpanded =
        _areOverBudgetCategoriesExpanded(ymKey);
    final hasRecordedExpenses =
        b.categories.any((category) => category.expenses.isNotEmpty);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ymLabel),
          actions: const [
            ThemeModeSelectorAction(),
            CurrencySelectorAction(),
          ],
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
                            'Expenses: ${Format.money(effectiveExpenses, symbol: store.currency.symbol)}'),
                      ],
                    ),
                    if (debtAlreadyCarried) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.forward_outlined,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Debt carried to $carriedToLabel: ${Format.money(b.carriedDebtAmount, symbol: store.currency.symbol)}',
                                style: TextStyle(color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else if (overallDebt > 0) ...[
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
                      if (canEdit) ...[
                        const SizedBox(height: 8),
                        if (hasNextMonth)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _carryDebtForwardFromCurrentMonth,
                              icon: const Icon(Icons.forward),
                              label: Text('Carry debt to $nextMonthLabel'),
                            ),
                          )
                        else
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
            const SizedBox(height: 6),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: !canEdit ? null : () => _showIncomeEditor(),
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
                                    builder: (_) =>
                                        const AllocateIncomeScreen(),
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
            if (b.incomes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _IncomeRecordsCard(
                incomes: b.incomes,
                currencySymbol: store.currency.symbol,
                canEdit: canEdit,
                isExpanded: isIncomeRecordsExpanded,
                onToggle: () => _toggleIncomeRecords(ymKey),
                onTapIncome: (incomeIndex) =>
                    _showIncomeEditor(incomeIndex: incomeIndex),
                onLongPressIncome: _showIncomeActions,
              ),
            ],
            if (overCats.isNotEmpty) ...[
              const SizedBox(height: 12),
              _OverBudgetCategoriesCard(
                categories: overCats,
                currencySymbol: store.currency.symbol,
                isExpanded: isOverBudgetCategoriesExpanded,
                onToggle: () => _toggleOverBudgetCategories(ymKey),
              ),
            ],
            const SizedBox(height: 16),
            if (hasRecordedExpenses &&
                remainingAfterExpenses > 0 &&
                !store.isTipDismissed(_monthSpareTipId))
              DismissibleTipBanner(
                message:
                    'You still have ${Format.money(remainingAfterExpenses, symbol: store.currency.symbol)} left this month! If you want to save money, you could create a savings category and record these as an expense to help you save.',
                onClose: () {
                  context.read<BudgetStore>().dismissTip(_monthSpareTipId);
                },
              ),
            const SizedBox(height: 8),
            if (b.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18.0),
                child: Text(
                    'Nothing here yet. Add your income and allocate your funds to start taking control of your finances!'),
              ),
            ...b.categories.map((c) => CategoryCard(
                  category: c,
                  isUncategorized: store.isUncategorizedCategory(c, budget: b),
                  currencySymbol: store.currency.symbol,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(categoryId: c.id),
                      ),
                    );
                  },
                  onLongPress: canEdit ? () => _showCategoryActions(c) : null,
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _IncomeRecordsCard extends StatelessWidget {
  final List<Income> incomes;
  final String currencySymbol;
  final bool canEdit;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onTapIncome;
  final ValueChanged<int> onLongPressIncome;

  const _IncomeRecordsCard({
    required this.incomes,
    required this.currencySymbol,
    required this.canEdit,
    required this.isExpanded,
    required this.onToggle,
    required this.onTapIncome,
    required this.onLongPressIncome,
  });

  String _incomeLabel(Income income) {
    final source = income.source.trim();
    return source.isEmpty ? 'Income' : source;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final totalIncome = incomes.fold<double>(
      0.0,
      (sum, income) => sum + income.amount,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Income records',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        Format.money(totalIncome, symbol: currencySymbol),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < incomes.length; i++) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canEdit ? () => onTapIncome(i) : null,
                            onLongPress:
                                canEdit ? () => onLongPressIncome(i) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _incomeLabel(incomes[i]),
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          localizations.formatMediumDate(
                                            incomes[i].date,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    Format.money(
                                      incomes[i].amount,
                                      symbol: currencySymbol,
                                    ),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (i != incomes.length - 1)
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant,
                            indent: 14,
                            endIndent: 14,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _OverBudgetCategoriesCard extends StatelessWidget {
  final List<Category> categories;
  final String currencySymbol;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _OverBudgetCategoriesCard({
    required this.categories,
    required this.currencySymbol,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalOverBudget = categories.fold<double>(
      0.0,
      (sum, category) => sum + (category.spent - category.allocated),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Over-budget categories',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        '+ ${Format.money(totalOverBudget, symbol: currencySymbol)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < categories.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${categories[i].emoji}  ${categories[i].name}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '+ ${Format.money(categories[i].spent - categories[i].allocated, symbol: currencySymbol)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != categories.length - 1)
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant,
                            indent: 14,
                            endIndent: 14,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
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

enum _CategoryTileAction { edit, delete, cancel }

enum _IncomeTileAction { delete, cancel }
