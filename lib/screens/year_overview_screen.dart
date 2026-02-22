import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/month_overview_tile.dart';
import 'month_screen.dart';
import '../utils/format.dart';

class YearOverviewScreen extends StatefulWidget {
  const YearOverviewScreen({super.key});

  @override
  State<YearOverviewScreen> createState() => _YearOverviewScreenState();
}

class _YearOverviewScreenState extends State<YearOverviewScreen> {
  int year = DateTime.now().year;

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

    final ymKeys = store.budgets.keys
        .where((k) => k.startsWith('$year-'))
        .toList()
      ..sort();

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
