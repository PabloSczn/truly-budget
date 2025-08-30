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

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final ymLabel = YearMonth(b.year, b.month).label;
    final spare = b.spare;

    return Scaffold(
      appBar: AppBar(
        title: Text('$ymLabel — Income: ' +
            Format.money(b.totalIncome, symbol: store.currency.symbol)),
        actions: const [CurrencySelectorAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                onPressed: spare <= 0
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
                  'You have ' +
                      Format.money(spare, symbol: store.currency.symbol) +
                      ' spare! You can use this as your savings.\nTip: Create a category for savings and take your savings as expenses so you save every month.',
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
