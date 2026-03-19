import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/budget_store.dart';
import 'screens/landing_screen.dart';
import 'screens/month_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = BudgetStore();
  await store.load();
  runApp(TrulyBudgetApp(store: store));
}

class TrulyBudgetApp extends StatelessWidget {
  final BudgetStore store;
  const TrulyBudgetApp({super.key, required this.store});

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
      brightness: brightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<BudgetStore>(
        builder: (_, s, __) => MaterialApp(
          title: 'TrulyBudget',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: s.themeMode,
          home: () {
            if (!s.initialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (s.selectedYMKey != null && s.currentBudget != null) {
              return const MonthScreen();
            }
            return const LandingScreen();
          }(),
        ),
      ),
    );
  }
}
