import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import '../widgets/add_category_dialog.dart';

class AllocateIncomeScreen extends StatefulWidget {
  const AllocateIncomeScreen({super.key});

  @override
  State<AllocateIncomeScreen> createState() => _AllocateIncomeScreenState();
}

class _AllocateIncomeScreenState extends State<AllocateIncomeScreen> {
  bool usePercent = false;
  final Map<String, TextEditingController> ctrls = {};

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();
    final b = store.currentBudget!;
    final available = b.spare <= 0 ? 0 : b.spare;

    return Scaffold(
      appBar: AppBar(title: const Text('Allocate income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocate your remaining income to categories. You can enter allocations as ${usePercent ? 'percentages (%)' : 'actual amounts'}.',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Use %'),
                Switch(
                  value: usePercent,
                  onChanged: (v) => setState(() => usePercent = v),
                ),
                const Spacer(),
                Text(
                    'Available: ${available.toStringAsFixed(2)} ${store.currency.code}'),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final c in b.categories)
                    ListTile(
                      title: Text('${c.emoji}  ${c.name}'),
                      subtitle: Text(
                          'Currently allocated: ${c.allocated.toStringAsFixed(2)} ${store.currency.code}'),
                      trailing: SizedBox(
                        width: 120,
                        child: TextField(
                          controller: ctrls.putIfAbsent(
                              c.id, () => TextEditingController()),
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: usePercent ? '%' : store.currency.code,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final res = await showDialog<(String, String)?>(
                        context: context,
                        builder: (_) => const AddCategoryDialog(),
                      );
                      if (res != null) {
                        final (name, emoji) = res;
                        store.addCategory(name, emoji);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add category'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: available <= 0
                  ? null
                  : () {
                      try {
                        if (usePercent) {
                          final map = <String, double>{};
                          ctrls.forEach((id, c) {
                            final v =
                                double.tryParse(c.text.replaceAll(',', '.')) ??
                                    0.0;
                            if (v > 0) map[id] = v;
                          });
                          store.allocateByPercents(map);
                        } else {
                          final map = <String, double>{};
                          ctrls.forEach((id, c) {
                            final v =
                                double.tryParse(c.text.replaceAll(',', '.')) ??
                                    0.0;
                            if (v > 0) map[id] = v;
                          });
                          store.allocateByAmounts(map);
                        }
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        // Back to month screen automatically
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Income allocated.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
              child: const Text('Add allocation'),
            )
          ],
        ),
      ),
    );
  }
}
