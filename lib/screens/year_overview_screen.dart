import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/month_overview_tile.dart';
import 'month_screen.dart';
import '../utils/format.dart';
import '../utils/year_month.dart';

enum _YearMonthTileAction { complete, delete, cancel }

enum _YearDebtChoice { keepInMonth, carryForward, cancel }

class YearOverviewScreen extends StatefulWidget {
  const YearOverviewScreen({super.key});

  @override
  State<YearOverviewScreen> createState() => _YearOverviewScreenState();
}

class _YearOverviewScreenState extends State<YearOverviewScreen> {
  int year = DateTime.now().year;

  Future<void> _handleCarryForwardForCompletion(String ymKey) async {
    final store = context.read<BudgetStore>();
    final nextMonthLabel = YearMonth.labelFromKey(store.nextMonthKeyOf(ymKey));
    var carryResult = store.carryDebtForwardToNextMonth(ymKey);

    if (carryResult == CarryForwardDebtResult.nextMonthMissing) {
      final createNext = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Create next month first?'),
          content: Text(
            'To carry debt forward, create $nextMonthLabel first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create month'),
            ),
          ],
        ),
      );
      if (!mounted || createNext != true) return;
      carryResult = store.carryDebtForwardToNextMonth(ymKey,
          createNextMonthIfMissing: true);
    }

    if (!mounted) return;

    if (carryResult != CarryForwardDebtResult.success) {
      var message = 'Debt could not be carried forward.';
      if (carryResult == CarryForwardDebtResult.nextMonthCompleted) {
        message = '$nextMonthLabel is completed. Reopen it first.';
      } else if (carryResult == CarryForwardDebtResult.debtAlreadyCarried) {
        message = 'Debt was already carried forward.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    store.completeMonth(ymKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Month completed and debt carried to next month.'),
      ),
    );
  }

  Future<void> _completeMonthFlow(String ymKey) async {
    final store = context.read<BudgetStore>();
    final b = store.budgets[ymKey];
    if (b == null) return;

    final debt = store.debtForBudget(b);
    final debtAlreadyCarried =
        (b.carriedDebtToKey ?? '').isNotEmpty && b.carriedDebtAmount > 0;

    if (debt <= 0 || debtAlreadyCarried) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Complete this month budget?'),
          content: Text(
            debtAlreadyCarried
                ? 'Debt was already carried forward. This month will become read-only.'
                : 'This month will become read-only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (!mounted || confirm != true) return;
      store.completeMonth(ymKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Month budget completed.')),
      );
      return;
    }

    final debtChoice = await showDialog<_YearDebtChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('This month has debt'),
        content: Text(
          'Debt: ${Format.money(debt, symbol: store.currency.symbol)}.\n\n'
          'How should this debt be handled before completing the month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _YearDebtChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _YearDebtChoice.keepInMonth),
            child: const Text('Keep debt in this month'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _YearDebtChoice.carryForward),
            child: const Text('Carry debt forward'),
          ),
        ],
      ),
    );

    if (!mounted ||
        debtChoice == null ||
        debtChoice == _YearDebtChoice.cancel) {
      return;
    }

    if (debtChoice == _YearDebtChoice.keepInMonth) {
      store.completeMonth(ymKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Month completed. Debt stayed in this month.')),
      );
      return;
    }

    await _handleCarryForwardForCompletion(ymKey);
  }

  Future<void> _showMonthActions(String ymKey) async {
    final store = context.read<BudgetStore>();
    final b = store.budgets[ymKey];
    if (b == null) return;

    final action = await showModalBottomSheet<_YearMonthTileAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!b.isCompleted)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Complete month budget'),
                onTap: () =>
                    Navigator.pop(context, _YearMonthTileAction.complete),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete month budget',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, _YearMonthTileAction.delete),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, _YearMonthTileAction.cancel),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null || action == _YearMonthTileAction.cancel) {
      return;
    }

    if (action == _YearMonthTileAction.complete) {
      await _completeMonthFlow(ymKey);
      return;
    }

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this month budget?'),
        content: Text(
          '${YearMonth.labelFromKey(ymKey)} will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmDelete != true) return;
    store.deleteMonth(ymKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Month budget deleted.')),
    );
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

    final ymKeys =
        store.monthKeysDesc.where((k) => k.startsWith('$year-')).toList();

    // Yearly totals
    double totalIncome = 0;
    double totalExpenses = 0;
    for (int m = 1; m <= 12; m++) {
      totalIncome += store.totalIncomeFor(year, m);
      totalExpenses += store.totalExpenseFor(year, m);
    }
    final spare = totalIncome - totalExpenses;
    final ratio =
        totalIncome <= 0 ? 1.0 : (totalExpenses / totalIncome).clamp(0.0, 1.0);
    final statusColor = _statusColor(totalIncome, totalExpenses);

    return Scaffold(
      appBar: AppBar(title: const Text('Year Overview')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year selector
              Row(
                children: [
                  const Text('Year:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: year,
                    items: [
                      for (int y = DateTime.now().year - 3;
                          y <= DateTime.now().year + 3;
                          y++)
                        DropdownMenuItem(value: y, child: Text(y.toString()))
                    ],
                    onChanged: (v) => setState(() => year = v ?? year),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Month cards
              Expanded(
                child: ymKeys.isEmpty
                    ? Center(
                        child: Text(
                          'No budgets for $year yet.\nCreate a month to see its overview here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: ymKeys.length,
                        itemBuilder: (_, i) {
                          final key = ymKeys[i];
                          return MonthOverviewTile(
                            ymKey: key,
                            onTap: () {
                              final parts = key.split('-');
                              final y = int.parse(parts[0]);
                              final m = int.parse(parts[1]);
                              store.selectMonth(y, m);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MonthScreen()),
                              );
                            },
                            onLongPress: () => _showMonthActions(key),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Year totals
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Year totals',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 12,
                          color: statusColor,
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _TotalTile(
                              label: 'Income',
                              value: Format.money(totalIncome,
                                  symbol: store.currency.symbol),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TotalTile(
                              label: 'Expenses',
                              value: Format.money(totalExpenses,
                                  symbol: store.currency.symbol),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            spare >= 0
                                ? Icons.trending_up
                                : Icons.warning_amber_outlined,
                            size: 18,
                            color: spare >= 0 ? Colors.green : Colors.red,
                          ),
                          label: Text(
                            (spare >= 0 ? 'Left: ' : 'Debt: ') +
                                Format.money(spare.abs(),
                                    symbol: store.currency.symbol),
                            style: TextStyle(
                              color: spare >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          side: BorderSide(
                            color: spare >= 0 ? Colors.green : Colors.red,
                          ),
                          backgroundColor:
                              (spare >= 0 ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final String value;
  const _TotalTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelMedium),
          const SizedBox(height: 4),
          Text(value,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
