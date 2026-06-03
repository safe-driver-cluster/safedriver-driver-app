import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safe_driver_driver_app/main.dart';
import 'package:safe_driver_driver_app/state/app_controller.dart';

void main() {
  testWidgets('driver app boots to splash', (WidgetTester tester) async {
    final controller = AppController();

    await tester.pumpWidget(
      AppScope(controller: controller, child: const DriverApp()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
