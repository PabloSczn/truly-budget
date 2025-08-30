import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/currency.dart';
import '../state/budget_store.dart';

class CurrencySelectorAction extends StatelessWidget {
  const CurrencySelectorAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Change currency',
      icon: const Icon(Icons.currency_exchange),
      onPressed: () async {
        final store = context.read<BudgetStore>();
        final selected = await showModalBottomSheet<Currency>(
          context: context,
          showDragHandle: true,
          builder: (_) => const _CurrencySheet(),
        );
        if (selected != null) {
          store.changeCurrency(selected);
        }
      },
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    return SafeArea(
      child: RadioGroup<String>(
        groupValue: store.currency.code,
        onChanged: (code) {
          if (code == null) return;
          // Return the selected Currency to the bottom sheet caller.
          Navigator.of(context).pop(Currencies.byCode(code));
        },
        child: ListView(
          children: [
            const ListTile(title: Text('Choose currency')),
            for (final c in Currencies.list)
              RadioListTile<String>(
                value: c.code,
                title: Text('${c.symbol}  ${c.code}'),
              ),
          ],
        ),
      ),
    );
  }
}
