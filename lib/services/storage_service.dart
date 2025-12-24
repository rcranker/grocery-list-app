import 'package:hive_flutter/hive_flutter.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';

class StorageService {
  static const String _itemsBoxName = 'grocery_items';
  static const String _storesBoxName = 'stores';
  
  static Box<GroceryItem>? _itemsBox;
  static Box<Store>? _storesBox;
  // Add this method to StorageService class
  static Future<void> clearAll() async {
    await _itemsBox?.clear();
    await _storesBox?.clear();
 }

  // Initialize Hive
static Future<void> init() async {
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(GroceryItemAdapter());
  Hive.registerAdapter(StoreAdapter());
  
  // Open boxes
  _itemsBox = await Hive.openBox<GroceryItem>(_itemsBoxName);
  _storesBox = await Hive.openBox<Store>(_storesBoxName);
  
  // Create default store if none exist
  if (_storesBox!.isEmpty) {
    final defaultStore = Store(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My Store',
      createdAt: DateTime.now(),
      isDefault: true,
      colorValue: 0xFF4CAF50, // Green
    );
    await _storesBox!.add(defaultStore);
  }
}

  // Items operations
  static Future<void> addItem(GroceryItem item) async {
    await _itemsBox!.add(item);
  }

  static Future<void> updateItem(int index, GroceryItem item) async {
    await _itemsBox!.putAt(index, item);
  }

  static Future<void> deleteItem(int index) async {
    await _itemsBox!.deleteAt(index);
  }

  static List<GroceryItem> getItems({String? storeId}) {
    if (storeId == null) {
      return _itemsBox!.values.toList();
    }
    return _itemsBox!.values
        .where((item) => item.storeId == storeId)
        .toList();
  }

  static Box<GroceryItem> getItemsBox() => _itemsBox!;

  // Stores operations
  static Future<void> addStore(Store store) async {
    await _storesBox!.add(store);
  }

  static Future<void> updateStore(int index, Store store) async {
    await _storesBox!.putAt(index, store);
  }

  static Future<void> deleteStore(int index) async {
    await _storesBox!.deleteAt(index);
  }

  static List<Store> getStores() {
    return _storesBox!.values.toList();
  }

  static Store? getDefaultStore() {
    try {
      return _storesBox!.values.firstWhere((store) => store.isDefault);
    } catch (e) {
      return _storesBox!.values.isNotEmpty ? _storesBox!.values.first : null;
    }
  }

  static Box<Store> getStoresBox() => _storesBox!;
}