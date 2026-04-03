import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_navigation/main.dart';

void main() {
  testWidgets('Splash screen shows map icon', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CampusNavigationApp());

    // Verify that our Splash Screen is displayed initially.
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    expect(find.text('Campus Navigation'), findsOneWidget);
  });
}
