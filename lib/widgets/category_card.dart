import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/format.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final String currencySymbol;
  final VoidCallback? onTap;
  const CategoryCard({
    super.key,
    required this.category,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double spent = category.spent;
    final double allocated = category.allocated;
    final double remaining = category.remaining;
    final bool isUncategorized =
        category.name.trim().toLowerCase() == 'uncategorized';

    // clamp() -> num, so call .toDouble()
    final double ratio =
        allocated > 0 ? (spent / allocated).clamp(0.0, 1.0).toDouble() : 0.0;

    final Color barColor = isUncategorized
        ? Colors.blueGrey
        : (ratio <= 0.5
            ? Colors.green
            : (ratio <= 0.8 ? Colors.orange : Colors.red));

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isUncategorized)
                    Text(Format.money(allocated, symbol: currencySymbol)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  color: barColor,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spent: ${Format.money(spent, symbol: currencySymbol)}'),
                  Text(
                      'Left: ${Format.money(remaining.clamp(0, double.infinity), symbol: currencySymbol)}'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
