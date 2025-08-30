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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'TrulyBudget',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        home: Consumer<BudgetStore>(
          builder: (_, s, __) {
            if (!s.initialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (s.selectedYMKey != null && s.currentBudget != null) {
              return const MonthScreen();
            }
            return const LandingScreen();
          },
        ),
      ),
    );
  }
}