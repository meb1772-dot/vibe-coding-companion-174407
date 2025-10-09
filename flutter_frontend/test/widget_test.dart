import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('App renders AppRoot and reader route', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppRoot());

    // The ReaderScreen app bar title should exist.
    expect(find.text('Vibe Coding Companion'), findsOneWidget);
    // Bottom navigation exists.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
