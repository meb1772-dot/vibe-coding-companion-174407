import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vibe_coding_companion/app/app.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // SharedPreferences is used during app bootstrap (LocalPersistenceService).
  // In widget tests, we must provide a mock store or the plugin init path can
  // hang/fail and the UI stays stuck on the loading spinner.
  // Note: SharedPreferences.setMockInitialValues expects Map<String, Object> (non-nullable values).
  SharedPreferences.setMockInitialValues(<String, Object>{});
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
    final Finder notesTab = find.text('Notes');
    await tester.ensureVisible(notesTab);
    await tester.tap(notesTab);
    await tester.pump(const Duration(milliseconds: 200));

    // Open add note sheet.
    final Finder addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump(const Duration(milliseconds: 200));

    // Enter quote + note body and save.
    const String quoteText = 'A quote snippet';
    const String noteText = 'Test note body';
    final Finder sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);

    final Finder sheetQuoteField = find.descendant(of: sheet, matching: find.byIcon(Icons.format_quote));
    expect(sheetQuoteField, findsOneWidget);

    final Finder sheetBodyField = find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Write your note…'));
    expect(sheetBodyField, findsOneWidget);

    await tester.enterText(sheetQuoteField, quoteText);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(sheetBodyField, noteText);
    await tester.pump(const Duration(milliseconds: 100));
    final Finder saveButton = find.text('Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify note appears.
    expect(find.text(noteText), findsOneWidget);
  });

  testWidgets('Search: open search sheet, search term yields results, jump navigates',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Reader toolbar search icon (avoid ambiguous Icons.search in drawer filter field).
    final Finder searchButton = find.byTooltip('Search');
    await tester.ensureVisible(searchButton);
    await tester.tap(searchButton);
    await tester.pump(const Duration(milliseconds: 200));

    // Type search term.
    final Finder sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);

    final Finder searchField = find.descendant(
      of: sheet,
      matching: find.widgetWithText(TextField, 'Search chapters and content…'),
    );
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'guardrails');
    await tester.pump(const Duration(milliseconds: 200));

    // Expect at least one result list tile.
    final Finder resultTile = find.descendant(of: sheet, matching: find.byType(ListTile));
    expect(resultTile, findsWidgets);

    // Tap first result to jump.
    await tester.tap(resultTile.first);
    await tester.pump(const Duration(milliseconds: 250));

    // Search sheet closed; still in reader view.
    expect(find.byTooltip('Search'), findsOneWidget);
  });

  testWidgets('Bookmarks: bookmark current section and see it in Bookmarks tab',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Bookmark current section.
    final Finder bookmarkButton = find.byTooltip('Bookmark section');
    await tester.ensureVisible(bookmarkButton);
    await tester.tap(bookmarkButton);
    await tester.pump(const Duration(milliseconds: 200));

    // Go to Bookmarks tab.
    final Finder bookmarksTab = find.text('Bookmarks');
    await tester.ensureVisible(bookmarksTab);
    await tester.tap(bookmarksTab);
    await tester.pump(const Duration(milliseconds: 250));

    // Should show at least one bookmark list tile.
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Bookmarks'), findsOneWidget);
  });

  testWidgets('Settings: open settings sheet and change a slider', (WidgetTester tester) async {
    await _pumpApp(tester);

    final Finder settingsButton = find.byTooltip('Settings');
    await tester.ensureVisible(settingsButton);
    await tester.tap(settingsButton);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Settings'), findsOneWidget);

    // Drag the first slider slightly.
    final Finder slider = find.byType(Slider).first;
    await tester.ensureVisible(slider);
    await tester.drag(slider, const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 200));

    // Close.
    final Finder doneButton = find.text('Done');
    await tester.ensureVisible(doneButton);
    await tester.tap(doneButton);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Edit note: create note then edit it', (WidgetTester tester) async {
    await _pumpApp(tester);

    final Finder notesTab = find.text('Notes');
    await tester.ensureVisible(notesTab);
    await tester.tap(notesTab);
    await tester.pump(const Duration(milliseconds: 200));

    // Add a note.
    final Finder addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump(const Duration(milliseconds: 200));

    const String noteText = 'Original note';
    final Finder sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);

    final Finder sheetBodyField = find.descendant(of: sheet, matching: find.widgetWithText(TextField, 'Write your note…'));
    expect(sheetBodyField, findsOneWidget);

    await tester.enterText(sheetBodyField, noteText);
    await tester.pump(const Duration(milliseconds: 100));
    final Finder saveButton = find.text('Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(noteText), findsOneWidget);

    // Tap edit icon on the note card.
    final Finder editButton = find.byTooltip('Edit note').first;
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pump(const Duration(milliseconds: 200));

    const String updated = 'Updated note';
    final Finder editSheet = find.byType(BottomSheet);
    expect(editSheet, findsOneWidget);

    final Finder editBodyField = find.descendant(
      of: editSheet,
      matching: find.widgetWithText(TextField, 'Write your note…'),
    );
    expect(editBodyField, findsOneWidget);

    await tester.enterText(editBodyField, updated);
    await tester.pump(const Duration(milliseconds: 100));
    final Finder editSaveButton = find.text('Save');
    await tester.ensureVisible(editSaveButton);
    await tester.tap(editSaveButton);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(updated), findsOneWidget);
  });
}
