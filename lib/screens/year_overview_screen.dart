import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/budget_store.dart';

class YearOverviewScreen extends StatefulWidget {
  const YearOverviewScreen({super.key});

  @override
  State<YearOverviewScreen> createState() => _YearOverviewScreenState();
}

class _YearOverviewScreenState extends State<YearOverviewScreen> {
  int year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BudgetStore>();

    List<BarChartGroupData> groups = [
      for (int m = 1; m <= 12; m++)
        BarChartGroupData(
          x: m,
          barsSpace: 6,
          barRods: [
            BarChartRodData(toY: store.totalIncomeFor(year, m), width: 10),
            BarChartRodData(toY: store.totalExpenseFor(year, m), width: 10),
          ],
        )
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Year Overview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Year:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: year,
                  items: [for (int y = DateTime.now().year - 3; y <= DateTime.now().year + 3; y++)
                    DropdownMenuItem(value: y, child: Text(y.toString()))
                  ],
                  onChanged: (v) => setState(() => year = v ?? year),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: groups,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const names = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(names[value.toInt() - 1]),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      barTouchData: BarTouchData(enabled: true),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _LegendDot(),
                SizedBox(width: 6),
                Text('Income'),
                SizedBox(width: 16),
                _LegendDot(),
                SizedBox(width: 6),
                Text('Expenses'),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Graph shows total income and total expenses for each month.'),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot();

  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue));
  }
}
