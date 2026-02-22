import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truly_budget/screens/month_screen.dart';
import '../state/budget_store.dart';
import '../widgets/currency_selector.dart';
import 'month_selection_screen.dart';
import 'year_overview_screen.dart';
import '../widgets/app_menu_drawer.dart';
import '../widgets/dismissible_tip_banner.dart';
import '../widgets/month_overview_tile.dart';
import '../utils/format.dart';
import '../utils/year_month.dart';

const _landingStartTipId = 'landing_start_tip';

enum _MonthTileAction { complete, delete, cancel }

enum _DebtChoice { keepInMonth, carryForward, cancel }

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _handleCarryForwardForCompletion(
    BuildContext context,
    String ymKey,
  ) async {
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

      if (!context.mounted || createNext != true) return;
      carryResult = store.carryDebtForwardToNextMonth(ymKey,
          createNextMonthIfMissing: true);
    }

    if (!context.mounted) return;

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

  Future<void> _completeMonthFlow(BuildContext context, String ymKey) async {
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
      if (!context.mounted || confirm != true) return;
      store.completeMonth(ymKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Month budget completed.')),
      );
      return;
    }

    final debtChoice = await showDialog<_DebtChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('This month has debt'),
        content: Text(
          'Debt: ${Format.money(debt, symbol: store.currency.symbol)}.\n\n'
          'How should this debt be handled before completing the month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DebtChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DebtChoice.keepInMonth),
            child: const Text('Keep debt in this month'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _DebtChoice.carryForward),
            child: const Text('Carry debt forward'),
          ),
        ],
      ),
    );

    if (!context.mounted ||
        debtChoice == null ||
        debtChoice == _DebtChoice.cancel) {
      return;
    }

    if (debtChoice == _DebtChoice.keepInMonth) {
      store.completeMonth(ymKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Month completed. Debt stayed in this month.')),
      );
      return;
    }

    await _handleCarryForwardForCompletion(context, ymKey);
  }

  Future<void> _showMonthActions(BuildContext context, String ymKey) async {
    final store = context.read<BudgetStore>();
    final b = store.budgets[ymKey];
    if (b == null) return;

    final action = await showModalBottomSheet<_MonthTileAction>(
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
                onTap: () => Navigator.pop(context, _MonthTileAction.complete),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete month budget',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(context, _MonthTileAction.delete),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, _MonthTileAction.cancel),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted ||
        action == null ||
        action == _MonthTileAction.cancel) {
      return;
    }

    if (action == _MonthTileAction.complete) {
      await _completeMonthFlow(context, ymKey);
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
    if (!context.mounted || confirmDelete != true) return;
    store.deleteMonth(ymKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Month budget deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final monthKeys = store.activeMonthKeysDesc;

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
                onLongPress: () => _showMonthActions(context, key),
              ),
          ] else if (!store.isTipDismissed(_landingStartTipId))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: DismissibleTipBanner(
                message:
                    'Start by creating a new month. You can switch currency from the top right.',
                onClose: () {
                  context.read<BudgetStore>().dismissTip(_landingStartTipId);
                },
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
