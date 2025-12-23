import 'package:flutter_test/flutter_test.dart';
import 'package:devx_diary_flutter/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Build app and pump a frame.
    await tester.pumpWidget(const DevXDiaryApp());

    // Verify root renders a home or login.
    expect(find.text('Diary'), findsOneWidget);
  });
}
