import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/app_ads_controller.dart';
import 'state/budget_store.dart';
import 'screens/landing_screen.dart';
import 'screens/month_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = BudgetStore();
  final adsController = AppAdsController();
  await store.load();
  unawaited(adsController.initialize());
  runApp(TrulyBudgetApp(store: store, adsController: adsController));
}

class TrulyBudgetApp extends StatelessWidget {
  final BudgetStore store;
  final AppAdsController adsController;
  const TrulyBudgetApp({
    super.key,
    required this.store,
    required this.adsController,
  });

  ThemeData _buildTheme(Brightness brightness) {
    final overlayStyle = _systemOverlayStyleFor(brightness);

    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
      brightness: brightness,
      appBarTheme: AppBarTheme(systemOverlayStyle: overlayStyle),
    );
  }

  SystemUiOverlayStyle _systemOverlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: adsController),
      ],
      child: Consumer<BudgetStore>(
        builder: (_, s, __) => MaterialApp(
          title: 'TrulyBudget',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: s.themeMode,
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _systemOverlayStyleFor(Theme.of(context).brightness),
              child: child ?? const SizedBox.shrink(),
            );
          },
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
