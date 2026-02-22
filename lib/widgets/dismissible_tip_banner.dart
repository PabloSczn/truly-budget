import 'package:flutter/material.dart';

class DismissibleTipBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const DismissibleTipBanner({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.lightbulb_outline,
                color: colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              splashRadius: 18,
              tooltip: 'Dismiss tip',
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                color: colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
