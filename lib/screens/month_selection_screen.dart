import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';
import 'month_screen.dart';

class MonthSelectionScreen extends StatefulWidget {
  const MonthSelectionScreen({super.key});

  @override
  State<MonthSelectionScreen> createState() => _MonthSelectionScreenState();
}

class _MonthSelectionScreenState extends State<MonthSelectionScreen> {
  int year = DateTime.now().year;
  int month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Select Month')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Year: '),
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
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final idx = i + 1;
                  final isSelected = idx == month;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    onPressed: () => setState(() => month = idx),
                    child: Text(months[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final store = context.read<BudgetStore>();
                store.selectMonth(year, month);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MonthScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Open Month Budget'),
            )
          ],
        ),
      ),
    );
  }
}
