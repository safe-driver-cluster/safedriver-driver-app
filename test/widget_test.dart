// This is a basic Flutter widget test for SafeDriver Driver App.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_driver_driver_app/main.dart';

void main() {
  testWidgets('Driver app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DriverApp()));

    // Verify that the app loads
    await tester.pumpAndSettle();

    // The app should show the login page initially
    expect(find.text('SafeDriver'), findsWidgets);
  });
}
