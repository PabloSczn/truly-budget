import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import 'month_selection_screen.dart';
import 'year_overview_screen.dart';
import 'month_screen.dart';
import '../widgets/app_menu_drawer.dart';
import '../utils/year_month.dart';
import '../utils/format.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final current = store.currentBudget;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrulyBudget'),
        actions: const [CurrencySelectorAction()],
      ),
      drawer: const AppMenuDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                Text(
                  'Tip: Start by creating a new month. You can switch currency from the top right.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
