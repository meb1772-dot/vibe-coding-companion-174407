import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibe_coding_companion/app/app.dart';

void main() {
  testWidgets('App boots and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeCodingCompanionApp());
    // Avoid pumpAndSettle(): plugins/animations can keep the frame scheduler busy.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Vibe Coding Companion'), findsWidgets);
  });

  testWidgets('Notes flow: open Notes tab, add note, see it in list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VibeCodingCompanionApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Switch to Notes tab (narrow layout shows bottom nav in tests).
    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 200));

    // Open add note sheet.
    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 200));

    // Enter note body and save.
    const String noteText = 'Test note body';
    await tester.enterText(find.byType(TextField), noteText);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify note appears.
    expect(find.text(noteText), findsOneWidget);
  });
}
