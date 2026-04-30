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

  // Let async bootstrap + first frames settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _activeBottomSheet() {
  // There should only be one modal sheet at a time in these tests.
  return find.byType(BottomSheet);
}

Finder _sheetTextFieldByHint(Finder sheet, String hintText) {
  // Target the TextField via its InputDecoration.hintText rather than icons or
  // raw Text, which can be ambiguous.
  return find.descendant(
    of: sheet,
    matching: find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration != null &&
          w.decoration!.hintText == hintText,
      description: 'TextField(hintText: "$hintText")',
    ),
  );
}

Finder _sheetSaveButton(Finder sheet) {
  // Scope Save to the active bottom sheet; the label text can appear elsewhere.
  return find.descendant(
    of: sheet,
    matching: find.widgetWithText(FilledButton, 'Save'),
  );
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterTextVisible(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
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
    await _tapAndSettle(tester, find.text('Notes'));

    // Open add note sheet.
    await _tapAndSettle(tester, find.text('Add'));

    // Enter quote + note body and save.
    const String quoteText = 'A quote snippet';
    const String noteText = 'Test note body';

    final Finder sheet = _activeBottomSheet();
    expect(sheet, findsOneWidget);

    final Finder quoteField =
        _sheetTextFieldByHint(sheet, 'Optional quote (paste a snippet)…');
    final Finder bodyField = _sheetTextFieldByHint(sheet, 'Write your note…');

    expect(quoteField, findsOneWidget);
    expect(bodyField, findsOneWidget);

    await _enterTextVisible(tester, quoteField, quoteText);
    await _enterTextVisible(tester, bodyField, noteText);

    final Finder saveButton = _sheetSaveButton(sheet);
    expect(saveButton, findsOneWidget);
    await _tapAndSettle(tester, saveButton);

    // Verify note appears.
    expect(find.text(noteText), findsOneWidget);
  });

  testWidgets('Search: open search sheet, search term yields results, jump navigates',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Reader toolbar search icon (avoid ambiguous Icons.search in drawer filter field).
    await _tapAndSettle(tester, find.byTooltip('Search'));

    // Type search term.
    final Finder sheet = _activeBottomSheet();
    expect(sheet, findsOneWidget);

    final Finder searchField = _sheetTextFieldByHint(sheet, 'Search chapters and content…');
    expect(searchField, findsOneWidget);

    await _enterTextVisible(tester, searchField, 'guardrails');

    // Expect at least one result list tile.
    final Finder resultTile = find.descendant(of: sheet, matching: find.byType(ListTile));
    expect(resultTile, findsWidgets);

    // Tap first result to jump.
    await _tapAndSettle(tester, resultTile.first);

    // Search sheet closed; still in reader view.
    expect(find.byTooltip('Search'), findsOneWidget);
  });

  testWidgets('Bookmarks: bookmark current section and see it in Bookmarks tab',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Bookmark current section.
    await _tapAndSettle(tester, find.byTooltip('Bookmark section'));

    // Go to Bookmarks tab.
    await _tapAndSettle(tester, find.text('Bookmarks'));

    // Should show at least one bookmark list tile.
    expect(find.byType(ListTile), findsWidgets);

    // "Bookmarks" can exist both as a bottom nav label and as the pane title.
    expect(find.text('Bookmarks'), findsWidgets);
  });

  testWidgets('Settings: open settings sheet and change a slider', (WidgetTester tester) async {
    await _pumpApp(tester);

    await _tapAndSettle(tester, find.byTooltip('Settings'));
    expect(find.text('Settings'), findsOneWidget);

    // Change the first slider in a hit-test-safe way by tapping on its track.
    final Finder slider = find.byType(Slider).first;
    expect(slider, findsOneWidget);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();

    final Rect r = tester.getRect(slider);

    // Tap around 70% along the track (should be in-bounds and not depend on drag).
    await tester.tapAt(Offset(r.left + r.width * 0.7, r.center.dy));
    await tester.pumpAndSettle();

    // Close.
    await _tapAndSettle(tester, find.text('Done'));
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Edit note: create note then edit it', (WidgetTester tester) async {
    await _pumpApp(tester);

    await _tapAndSettle(tester, find.text('Notes'));

    // Add a note.
    await _tapAndSettle(tester, find.text('Add'));

    const String noteText = 'Original note';
    final Finder addSheet = _activeBottomSheet();
    expect(addSheet, findsOneWidget);

    final Finder bodyField = _sheetTextFieldByHint(addSheet, 'Write your note…');
    expect(bodyField, findsOneWidget);

    await _enterTextVisible(tester, bodyField, noteText);

    final Finder saveButton = _sheetSaveButton(addSheet);
    expect(saveButton, findsOneWidget);
    await _tapAndSettle(tester, saveButton);

    expect(find.text(noteText), findsOneWidget);

    // Tap edit icon on the note card.
    final Finder editButton = find.byTooltip('Edit note').first;
    expect(editButton, findsOneWidget);
    await _tapAndSettle(tester, editButton);

    const String updated = 'Updated note';
    final Finder editSheet = _activeBottomSheet();
    expect(editSheet, findsOneWidget);

    final Finder editBodyField = _sheetTextFieldByHint(editSheet, 'Write your note…');
    expect(editBodyField, findsOneWidget);

    await _enterTextVisible(tester, editBodyField, updated);

    final Finder editSaveButton = _sheetSaveButton(editSheet);
    expect(editSaveButton, findsOneWidget);
    await _tapAndSettle(tester, editSaveButton);

    expect(find.text(updated), findsOneWidget);
  });
}
