import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grocery_list_app/main.dart';

void main() {
  testWidgets('App loads with grocery list', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GroceryListApp());

    // Verify that the app title appears
    expect(find.text('My Grocery List'), findsOneWidget);

    // Verify the empty state message appears
    expect(find.text('No items yet.\nTap + to add your first item!'), findsOneWidget);

    // Verify the add button exists
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Can add an item', (WidgetTester tester) async {
    await tester.pumpWidget(const GroceryListApp());

    // Tap the add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify dialog appears
    expect(find.text('Add Item'), findsOneWidget);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Milk');
    
    // Tap Add button
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Verify item appears in list
    expect(find.text('Milk'), findsOneWidget);
  });
}