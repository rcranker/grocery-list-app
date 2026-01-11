import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';

class StorageService {
  static Box<GroceryItem>? _itemsBox;
  static Box<Store>? _storesBox;

  // Initialize with already-opened boxes
  static void initialize(Box<GroceryItem> itemsBox, Box<Store> storesBox) {
    _itemsBox = itemsBox;
    _storesBox = storesBox;
  }

  // Items operations
  static Future<void> addItem(GroceryItem item) async {
    if (_itemsBox == null) {
      debugPrint('ERROR: Items box not initialized!');
      return;
    }
    await _itemsBox!.add(item);
  }

  static Future<void> updateItem(int index, GroceryItem item) async {
    if (_itemsBox == null) return;
    await _itemsBox!.putAt(index, item);
  }

  static Future<void> deleteItem(int index) async {
    if (_itemsBox == null) return;
    await _itemsBox!.deleteAt(index);
  }

  static List<GroceryItem> getItems() {
    if (_itemsBox == null) return [];
    return _itemsBox!.values.toList();
  }

  static Box<GroceryItem> getItemsBox() {
    if (_itemsBox == null) {
      throw Exception('Items box not initialized');
    }
    return _itemsBox!;
  }

  // Stores operations
  static Future<void> addStore(Store store) async {
    if (_storesBox == null) {
      debugPrint('ERROR: Stores box not initialized!');
      return;
    }
    await _storesBox!.add(store);
  }

  static Future<void> updateStore(int index, Store store) async {
    if (_storesBox == null) return;
    await _storesBox!.putAt(index, store);
  }

  static Future<void> deleteStore(int index) async {
    if (_storesBox == null) return;
    await _storesBox!.deleteAt(index);
  }

  static List<Store> getStores() {
    if (_storesBox == null) return [];
    return _storesBox!.values.toList();
  }

  static Store? getDefaultStore() {
    if (_storesBox == null) return null;
  
    final stores = getStores();
    if (stores.isEmpty) {
      return null;
    }
  
    // Try to find default store
    try {
      return stores.firstWhere((store) => store.isDefault);
    } catch (e) {
      return stores.isNotEmpty ? stores.first : null;
    }
  }

  static Future<void> updateStoreNotes(int index, String notes) async {
    if (_storesBox == null) return;
    final store = _storesBox!.getAt(index);
    if (store != null) {
      final updatedStore = store.copyWith(notes: notes);
      await _storesBox!.putAt(index, updatedStore);
    }
  }

  static Box<Store> getStoresBox() {
    if (_storesBox == null) {
      throw Exception('Stores box not initialized');
    }
    return _storesBox!;
  }
}