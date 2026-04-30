import 'package:flutter_test/flutter_test.dart';

import 'package:vibe_coding_companion/app/app.dart';

void main() {
  testWidgets('App boots and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const VibeCodingCompanionApp());
    await tester.pumpAndSettle();

    expect(find.text('Vibe Coding Companion'), findsWidgets);
  });
}
