import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/data_management_screen.dart';
import '../screens/year_overview_screen.dart';
import '../screens/about_screen.dart';
import '../services/app_ads_controller.dart';
import '../state/budget_store.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final adsController = context.watch<AppAdsController?>();
    final showPrivacyChoices = adsController?.privacyOptionsRequired ?? false;

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const _DrawerBrandHeader(),
            ListTile(
              leading: const Icon(Icons.home_outlined, size: 22),
              title: const Text('Home'),
              onTap: () {
                final navigator = Navigator.of(context);
                final store = context.read<BudgetStore>();
                navigator.pop();
                store.clearSelectedMonth();
                navigator.popUntil((route) => route.isFirst);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined, size: 21.5),
              title: const Text('Year Overview'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const YearOverviewScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_shared_outlined, size: 22),
              title: const Text('Data & Exports'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DataManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, size: 22),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            if (showPrivacyChoices)
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, size: 22),
                title: const Text('Privacy choices'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  final errorMessage =
                      await adsController?.showPrivacyOptionsForm();
                  if (!context.mounted || errorMessage == null) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBrandHeader extends StatelessWidget {
  const _DrawerBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth * 0.82,
              height: constraints.maxHeight,
              child: ClipRect(
                child: Image.asset(
                  'assets/logo_with_text_below.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  semanticLabel: 'TrulyBudget',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
