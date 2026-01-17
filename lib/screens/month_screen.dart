import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import '../widgets/category_card.dart';
import '../widgets/add_category_dialog.dart';
import '../utils/format.dart';
import '../utils/year_month.dart';
import 'year_overview_screen.dart';
import 'add_income_screen.dart';
import 'allocate_income_screen.dart';
import 'category_detail_screen.dart';
import '../widgets/app_menu_drawer.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

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
    final ymLabel = YearMonth(b.year, b.month).label;
    final spare = b.spare;
    final totalExpenses = b.categories.fold<double>(0.0, (s, c) => s + c.spent);
    final overallDebt = (totalExpenses - b.totalIncome) > 0
        ? (totalExpenses - b.totalIncome)
        : 0.0;
    final overCats = b.categories.where((c) => c.spent > c.allocated).toList();
    final statusColor = _statusColor(b.totalIncome, totalExpenses);
    final ratio = b.totalIncome <= 0
        ? 1.0
        : (totalExpenses / b.totalIncome).clamp(0.0, 1.0);
    final canOpenAllocate = (b.totalIncome > 0) || (b.totalAllocated > 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(ymLabel),
        actions: const [CurrencySelectorAction()],
      ),
      drawer: const AppMenuDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
                  );
                },
                child: const Text('Add income'),
              ),
              FilledButton.tonal(
                onPressed: !canOpenAllocate
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AllocateIncomeScreen()),
                        );
                      },
                child: const Text('Allocate income'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final result = await showDialog<(String, String)?>(
                    context: context,
                    builder: (_) => const AddCategoryDialog(),
                  );
                  if (result != null) {
                    final (name, emoji) = result;
                    store.addCategory(name, emoji);
                  }
                },
                child: const Text('Add expense category'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const YearOverviewScreen(),
                    ),
                  );
                },
                child: const Text('See Year Overview'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (spare > 0)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'You have ${Format.money(spare, symbol: store.currency.symbol)} spare! You can use this as your savings.\nTip: Create a category for savings and take your savings as expenses so you save every month.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (b.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18.0),
              child: Text('No categories yet. Add one to get started.'),
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
