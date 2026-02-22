import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../utils/year_month.dart';
import '../utils/format.dart';

class MonthOverviewTile extends StatelessWidget {
  final String ymKey;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MonthOverviewTile({
    super.key,
    required this.ymKey,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final store = context.read<BudgetStore>();
    final b = store.budgets[ymKey]!;
    final income = b.totalIncome;
    final expenses = b.categories.fold<double>(0, (s, c) => s + c.spent);
    final spare = income - expenses;
    final statusLabel = b.isCompleted ? 'Completed' : 'Active';

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: Text(YearMonth.labelFromKey(ymKey)),
        subtitle: Text(
          '$statusLabel month budget\n'
          'Income: ${Format.money(income, symbol: store.currency.symbol)}\n'
          'Expenses: ${Format.money(expenses, symbol: store.currency.symbol)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(spare >= 0 ? 'Left' : 'Debt',
                style: Theme.of(context).textTheme.labelSmall),
            Text(
              Format.money(spare.abs(), symbol: store.currency.symbol),
              style: TextStyle(
                color: spare >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
