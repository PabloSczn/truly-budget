import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/widgets/emoji_selector.dart';

void main() {
  testWidgets('emoji selector includes new searchable emojis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  pickEmoji(tester.element(find.byType(ElevatedButton))),
              child: const Text('Open emoji picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open emoji picker'));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.enterText(searchField, 'tooth');
    await tester.pumpAndSettle();
    expect(find.text('🦷'), findsOneWidget);

    await tester.enterText(searchField, 'phone');
    await tester.pumpAndSettle();
    expect(find.text('📱'), findsOneWidget);

    await tester.enterText(searchField, 'calendar');
    await tester.pumpAndSettle();
    expect(find.text('📅'), findsOneWidget);

    await tester.enterText(searchField, 'love letter');
    await tester.pumpAndSettle();
    expect(find.text('💌'), findsOneWidget);
  });
}
