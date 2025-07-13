// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_wheel_app/main.dart';

void main() {
  testWidgets('OneWheel app launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OneWheelApp());

    // Verify that our app loads
    await tester.pumpAndSettle();
    
    // Look for dashboard elements
    expect(find.text('Dashboard'), findsOneWidget);
    
    // Test navigation to other screens
    await tester.tap(find.text('Rides'));
    await tester.pumpAndSettle();
    
    // Verify navigation works
    expect(find.text('Rides'), findsOneWidget);
  });
}
