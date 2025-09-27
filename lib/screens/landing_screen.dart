import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/screens/month_screen.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import 'month_selection_screen.dart';
import 'year_overview_screen.dart';
import '../widgets/app_menu_drawer.dart';
import '../widgets/month_overview_tile.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final monthKeys = store.monthKeysDesc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrulyBudget'),
        actions: const [CurrencySelectorAction()],
      ),
      drawer: const AppMenuDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick actions
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MonthSelectionScreen(),
                    ),
                  );
                },
                child: const Text('New Month'),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 24),

          // Existing (active) month budgets
          if (monthKeys.isNotEmpty) ...[
            Text('Your budgets',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final key in monthKeys)
              MonthOverviewTile(
                ymKey: key,
                onTap: () {
                  final parts = key.split('-');
                  final y = int.parse(parts[0]);
                  final m = int.parse(parts[1]);
                  store.selectMonth(y, m);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MonthScreen()),
                  );
                },
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Tip: Start by creating a new month. You can switch currency from the top right.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
