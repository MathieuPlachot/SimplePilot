// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_pilot/services/udp_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pilot/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    UDPHandler handler = UDPHandler();
    handler.setForeground(false);

    await tester.pumpWidget(
      ChangeNotifierProvider<UDPHandler>(
        create: (_) => handler,
        child: MaterialApp(home: SimplePilot()),
      ),
    );

    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('toto'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('toto'), findsNothing);
  });
}
