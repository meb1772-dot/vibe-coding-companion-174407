import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vibe_coding_companion/app/app.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // SharedPreferences is used during app bootstrap (LocalPersistenceService).
  // In widget tests, we must provide a mock store or the plugin init path can
  // hang/fail and the UI stays stuck on the loading spinner.
  SharedPreferences.setMockInitialValues(<String, Object?>{});
  await tester.pumpWidget(const VibeCodingCompanionApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('App boots and shows title', (WidgetTester tester) async {
    await _pumpApp(tester);
    expect(find.text('Vibe Coding Companion'), findsWidgets);
  });

  testWidgets('Notes flow: open Notes tab, add note, see it in list', (WidgetTester tester) async {
    await _pumpApp(tester);

    // Switch to Notes tab (narrow layout shows bottom nav in tests).
    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 200));

    // Open add note sheet.
    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 200));

    // Enter quote + note body and save.
    const String quoteText = 'A quote snippet';
    const String noteText = 'Test note body';
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    await tester.enterText(find.byType(TextField).first, quoteText);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextField).last, noteText);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify note appears.
    expect(find.text(noteText), findsOneWidget);
  });

  testWidgets('Search: open search sheet, search term yields results, jump navigates',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Reader toolbar search icon.
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump(const Duration(milliseconds: 200));

    // Type search term.
    await tester.enterText(find.byType(TextField), 'guardrails');
    await tester.pump(const Duration(milliseconds: 200));

    // Expect at least one result list tile.
    expect(find.byType(ListTile), findsWidgets);

    // Tap first result to jump.
    await tester.tap(find.byType(ListTile).first);
    await tester.pump(const Duration(milliseconds: 250));

    // Search sheet closed; still in reader view.
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Bookmarks: bookmark current section and see it in Bookmarks tab',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Bookmark current section.
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump(const Duration(milliseconds: 200));

    // Go to Bookmarks tab.
    await tester.tap(find.text('Bookmarks'));
    await tester.pump(const Duration(milliseconds: 250));

    // Should show at least one bookmark list tile.
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Bookmarks'), findsOneWidget);
  });

  testWidgets('Settings: open settings sheet and change a slider', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Settings'), findsOneWidget);

    // Drag the first slider slightly.
    final Finder slider = find.byType(Slider).first;
    await tester.drag(slider, const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 200));

    // Close.
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Edit note: create note then edit it', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 200));

    // Add a note.
    await tester.tap(find.text('Add'));
    await tester.pump(const Duration(milliseconds: 200));

    const String noteText = 'Original note';
    await tester.enterText(find.byType(TextField).last, noteText);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(noteText), findsOneWidget);

    // Tap edit icon on the note card.
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump(const Duration(milliseconds: 200));

    const String updated = 'Updated note';
    await tester.enterText(find.byType(TextField).last, updated);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(updated), findsOneWidget);
  });
}
