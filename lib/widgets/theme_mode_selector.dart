import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/budget_store.dart';

class ThemeModeSelectorAction extends StatelessWidget {
  const ThemeModeSelectorAction({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<BudgetStore, ThemeMode>((store) => store.themeMode);

    return IconButton(
      tooltip: 'Change theme',
      icon: Icon(_iconFor(themeMode)),
      onPressed: () async {
        final store = context.read<BudgetStore>();
        final selected = await showModalBottomSheet<ThemeMode>(
          context: context,
          showDragHandle: true,
          builder: (_) => const _ThemeModeSheet(),
        );
        if (selected != null) {
          store.changeThemeMode(selected);
        }
      },
    );
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<BudgetStore, ThemeMode>((store) => store.themeMode);

    return SafeArea(
      child: RadioGroup<ThemeMode>(
        groupValue: themeMode,
        onChanged: (mode) {
          if (mode == null) return;
          Navigator.of(context).pop(mode);
        },
        child: ListView(
          shrinkWrap: true,
          children: const [
            ListTile(title: Text('Choose theme')),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              secondary: Icon(Icons.brightness_auto_outlined),
              title: Text('System default'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              secondary: Icon(Icons.light_mode_outlined),
              title: Text('Light'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              secondary: Icon(Icons.dark_mode_outlined),
              title: Text('Dark'),
            ),
          ],
        ),
      ),
    );
  }
}
