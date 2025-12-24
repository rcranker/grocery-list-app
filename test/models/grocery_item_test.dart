import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_list_app/models/grocery_item.dart';

void main() {
  group('GroceryItem', () {
    test('creates item with required fields', () {
      final item = GroceryItem(
        id: '1',
        name: 'Milk',
        createdAt: DateTime.now(),
      );

      expect(item.name, 'Milk');
      expect(item.quantity, 1);
      expect(item.isChecked, false);
    });

    test('converts to and from JSON', () {
      final now = DateTime.now();
      final item = GroceryItem(
        id: '1',
        name: 'Eggs',
        quantity: 2,
        category: 'Dairy',
        createdAt: now,
      );

      final json = item.toJson();
      final restored = GroceryItem.fromJson(json);

      expect(restored.name, item.name);
      expect(restored.quantity, item.quantity);
      expect(restored.category, item.category);
    });

    test('copyWith creates modified copy', () {
      final item = GroceryItem(
        id: '1',
        name: 'Bread',
        createdAt: DateTime.now(),
      );

      final checked = item.copyWith(isChecked: true);

      expect(checked.isChecked, true);
      expect(checked.name, 'Bread'); // unchanged
      expect(item.isChecked, false); // original unchanged
    });
  });
}