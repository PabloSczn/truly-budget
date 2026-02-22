import 'package:flutter/material.dart';
import '../screens/landing_screen.dart';
import '../screens/year_overview_screen.dart';
import '../screens/about_screen.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('TrulyBudget', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined, size: 22),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                );
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
              leading: const Icon(Icons.info_outline, size: 22),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
