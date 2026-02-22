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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 430;

                final newMonthButton = FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MonthSelectionScreen(),
                      ),
                    );
                  },
                  child: const _ActionButtonLabel(
                    icon: Icons.add_circle_outline,
                    label: 'New Month',
                  ),
                );

                final yearOverviewButton = OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const YearOverviewScreen(),
                      ),
                    );
                  },
                  child: const _ActionButtonLabel(
                    icon: Icons.calendar_month_outlined,
                    label: 'Year Overview',
                  ),
                );

                if (isCompact) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: newMonthButton),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: yearOverviewButton,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: newMonthButton),
                    const SizedBox(width: 12),
                    Expanded(child: yearOverviewButton),
                  ],
                );
              },
            ),
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

class _ActionButtonLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButtonLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
