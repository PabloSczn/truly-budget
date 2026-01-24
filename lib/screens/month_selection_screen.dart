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

  static const months = [
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
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;

    final baseOutlined = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      alignment: Alignment.center,
    );

    final baseFilled = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      alignment: Alignment.center,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Month')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
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
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Center(
            // Prevents weird stretching on large screens
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                          for (int y = nowYear - 3; y <= nowYear + 3; y++)
                            DropdownMenuItem(
                                value: y, child: Text(y.toString()))
                        ],
                        onChanged: (v) => setState(() => year = v ?? year),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 48,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, i) {
                        final idx = i + 1;
                        final isSelected = idx == month;

                        final label = Text(
                          months[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );

                        return isSelected
                            ? FilledButton.tonal(
                                style: baseFilled,
                                onPressed: () => setState(() => month = idx),
                                child: label,
                              )
                            : OutlinedButton(
                                style: baseOutlined,
                                onPressed: () => setState(() => month = idx),
                                child: label,
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
