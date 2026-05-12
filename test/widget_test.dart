import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Focus Blocker app smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences with default values for testing
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const FocusBlockerApp());
    await tester.pumpAndSettle();

    // Verify that the app builds and displays the home screen
    expect(find.text('Focus Blocker'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // Verify that we can see the blocked apps section
    expect(find.text('Blocked Apps'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('TikTok'), findsOneWidget);
  });
}
