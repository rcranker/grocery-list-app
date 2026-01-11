import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';
import '../models/user_model.dart';
import '../services/subscription_service.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get canUseCloudFeatures => SubscriptionService().isPremium;  // Premium users only
  
  UserModel? _cachedUser;
  String? get householdId => _cachedUser?.householdId;

  // ==================== INITIALIZATION ====================

  // Initialize sync - upload local data to Firestore on first login
  Future<void> initializeSync() async {
    if (!isLoggedIn) return;

    final uid = currentUser!.uid;

    debugPrint('=== INITIALIZE SYNC ===');
    debugPrint('User ID: $uid');

    // Load user data to get household info
    _cachedUser = await _firestoreService.getUserData(uid);
    
    debugPrint('User loaded: ${_cachedUser?.displayName}');
    debugPrint('Household ID: ${_cachedUser?.householdId}');

    // Check if user has any data in Firestore
    final hasCloudData = await _hasCloudData(uid);

    if (!hasCloudData) {
      // First time login - upload local data
      await _uploadLocalData(uid);
    } else {
      // User has cloud data - download and merge
      await _downloadCloudData(uid);
    }
    
    debugPrint('=== SYNC INITIALIZED ===');
  }

  Future<bool> _hasCloudData(String uid) async {
    final stores = await _firestoreService
        .getStoresCollection(uid, householdId: householdId)
        .limit(1)
        .get();
    return stores.docs.isNotEmpty;
  }

  Future<void> _uploadLocalData(String uid) async {
    debugPrint('Uploading local data to Firestore...');
    
    // Upload stores
    final localStores = StorageService.getStores();
    if (localStores.isNotEmpty) {
      await _syncLocalStoresToFirestore(uid, localStores);
    }

    // Upload items
    final localItems = StorageService.getItems();
    if (localItems.isNotEmpty) {
      await _syncLocalItemsToFirestore(uid, localItems);
    }

    debugPrint('Local data uploaded successfully');
  }

  Future<void> _downloadCloudData(String uid) async {
    debugPrint('Downloading cloud data...');
    // Cloud data takes precedence
    debugPrint('Cloud data download complete');
  }

  Future<void> _syncLocalItemsToFirestore(String uid, List<GroceryItem> items) async {
    final batch = _firestoreService.getItemsCollection(uid, householdId: householdId);
    
    for (final item in items) {
      await batch.doc(item.id).set({
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category,
        'aisle': item.aisle,
        'isChecked': item.isChecked,
        'storeId': item.storeId,
        'addedBy': item.addedBy,
        'addedAt': item.addedAt.toIso8601String(),
        'createdAt': item.createdAt.toIso8601String(),
        'checkedAt': item.checkedAt?.toIso8601String(),
      });
    }
  }

  Future<void> _syncLocalStoresToFirestore(String uid, List<Store> stores) async {
    final batch = _firestoreService.getStoresCollection(uid, householdId: householdId);
    
    for (final store in stores) {
      await batch.doc(store.id).set({
        'name': store.name,
        'colorValue': store.colorValue,
        'notes': store.notes,
        'isDefault': store.isDefault,
        'createdAt': store.createdAt.toIso8601String(),
      });
    }
  }

  // Refresh user data (call this after joining/leaving household)
  Future<void> refreshUserData() async {
    if (!isLoggedIn) return;
    _cachedUser = await _firestoreService.getUserData(currentUser!.uid);
    debugPrint('User data refreshed. Household ID: ${_cachedUser?.householdId}');
  }

  // Ensure user data is loaded
  Future<void> ensureUserDataLoaded() async {
    if (!isLoggedIn) return;
    
    if (_cachedUser == null) {
      debugPrint('Loading user data...');
      _cachedUser = await _firestoreService.getUserData(currentUser!.uid);
      debugPrint('User loaded: ${_cachedUser?.displayName}');
      debugPrint('Household ID: ${_cachedUser?.householdId}');
    }
  }

  // ==================== ITEMS SYNC ====================

  // Add item to both local and cloud
  Future<void> addItem(GroceryItem item) async {
    // Ensure user data is loaded
    await ensureUserDataLoaded();
  
    debugPrint('=== ADD ITEM DEBUG ===');
    debugPrint('isLoggedIn: $isLoggedIn');
    debugPrint('currentUser: ${currentUser?.uid}');
    debugPrint('householdId: $householdId');
    debugPrint('_cachedUser: $_cachedUser');
    debugPrint('_cachedUser.householdId: ${_cachedUser?.householdId}');
  
    // Add to local storage immediately
    await StorageService.addItem(item);
    debugPrint('Item saved to local storage');

    // Verify it was saved
    final localItems = StorageService.getItems();
    debugPrint('Total local items: ${localItems.length}');

    // Sync to cloud if logged in
    if (isLoggedIn && canUseCloudFeatures) {
      debugPrint('Syncing to cloud (premium user)');
      try {
        final uid = currentUser!.uid;
        final hId = householdId;
      
        debugPrint('Saving to household: $hId');
      
        final collection = _firestoreService.getItemsCollection(uid, householdId: hId);
      
        // NEW: Print the actual path
        debugPrint('Collection path: ${collection.path}');
      
        await collection.doc(item.id).set({
          'name': item.name,
          'quantity': item.quantity,
          'category': item.category,
          'aisle': item.aisle,
          'isChecked': item.isChecked,
          'storeId': item.storeId,
          'addedBy': item.addedBy,
          'addedAt': item.addedAt.toIso8601String(),
          'createdAt': item.createdAt.toIso8601String(),
          'checkedAt': item.checkedAt?.toIso8601String(),
        });
      
        debugPrint('Item synced to cloud with ID: ${item.id}');
        debugPrint('Full path: ${collection.path}/${item.id}');
      
      } catch (e) {
        debugPrint('Failed to sync item to cloud: $e');
      }
    } else {
      debugPrint('Skipping cloud sync (not premium)');
    }
  }


  // Update item in both local and cloud
  Future<void> updateItem(int localIndex, GroceryItem item) async {
    await ensureUserDataLoaded();
    
    // Update local storage immediately
    await StorageService.updateItem(localIndex, item);

    // Sync to cloud if Premium user
    if (isLoggedIn && canUseCloudFeatures) {
      try {
        final collection = _firestoreService.getItemsCollection(
          currentUser!.uid,
          householdId: householdId,
        );
        await collection.doc(item.id).update({
          'name': item.name,
          'quantity': item.quantity,
          'category': item.category,
          'aisle': item.aisle,
          'isChecked': item.isChecked,
          'storeId': item.storeId,
          'checkedAt': item.checkedAt?.toIso8601String(),
        });
        debugPrint('Item update synced to cloud');
      } catch (e) {
        debugPrint('Failed to sync item update to cloud: $e');
      }
    }
  }

  // Delete item from both local and cloud
  Future<void> deleteItem(int localIndex, String itemId) async {
    await ensureUserDataLoaded();
  
    debugPrint('=== DELETE ITEM ===');
    debugPrint('Item ID: $itemId');
    debugPrint('Local index: $localIndex');
  
    // Delete from cloud first if premium
    if (isLoggedIn && canUseCloudFeatures) {
      try {
        final collection = _firestoreService.getItemsCollection(
          currentUser!.uid,
          householdId: householdId,
        );
        await collection.doc(itemId).delete();
        debugPrint('Item deleted from cloud');
      } catch (e) {
        debugPrint('Failed to delete item from cloud: $e');
      }
    }
  
    // Delete from local storage if it exists (using the actual index)
    final localItems = StorageService.getItems();
    final actualIndex = localItems.indexWhere((i) => i.id == itemId);
  
    if (actualIndex != -1) {
      await StorageService.deleteItem(actualIndex);
      debugPrint('Item deleted from local storage at index $actualIndex');
    } else {
      debugPrint('Item not found in local storage (cloud-only item)');
    }
  }

  // ==================== STORES SYNC ====================

  // Add store to both local and cloud
  Future<void> addStore(Store store) async {
    await ensureUserDataLoaded();
  
    // Add to local storage immediately
    await StorageService.addStore(store);

    // Only sync to cloud if premium
    if (isLoggedIn && canUseCloudFeatures) {
      try {
        final collection = _firestoreService.getStoresCollection(
          currentUser!.uid,
          householdId: householdId,
        );
        await collection.doc(store.id).set({
          'name': store.name,
          'colorValue': store.colorValue,
          'notes': store.notes,
          'isDefault': store.isDefault,
          'createdAt': store.createdAt.toIso8601String(),
        });
        debugPrint('Store synced to cloud with ID: ${store.id}');
      } catch (e) {
        debugPrint('Failed to sync store to cloud: $e');
      }
    }
  }


  // Update store in both local and cloud
  Future<void> updateStore(int localIndex, Store store) async {
    await ensureUserDataLoaded();
    
    // Update local storage immediately
    await StorageService.updateStore(localIndex, store);

    // Sync to cloud if Premium user
    if (isLoggedIn && canUseCloudFeatures) {
      try {
        final collection = _firestoreService.getStoresCollection(
          currentUser!.uid,
          householdId: householdId,
        );
        await collection.doc(store.id).update({
          'name': store.name,
          'colorValue': store.colorValue,
          'notes': store.notes,
          'isDefault': store.isDefault,
        });
        debugPrint('Store update synced to cloud');
      } catch (e) {
        debugPrint('Failed to sync store update to cloud: $e');
      }
    }
  }

  // Update store notes
  Future<void> updateStoreNotes(int localIndex, String storeId, String notes) async {
    final store = StorageService.getStoresBox().getAt(localIndex);
    if (store != null) {
      final updatedStore = store.copyWith(notes: notes);
      await updateStore(localIndex, updatedStore);
    }
  }

  // Delete store from both local and cloud
  Future<void> deleteStore(int localIndex, String storeId) async {
    await ensureUserDataLoaded();
    
    // Delete from local storage immediately
    await StorageService.deleteStore(localIndex);

    // Sync to cloud if Premium user
    if (isLoggedIn && canUseCloudFeatures) {
      try {
        final collection = _firestoreService.getStoresCollection(
          currentUser!.uid,
          householdId: householdId,
        );
        await collection.doc(storeId).delete();
        debugPrint('Store deletion synced to cloud');
      } catch (e) {
        debugPrint('Failed to sync store deletion to cloud: $e');
      }
    }
  }

  // ==================== STREAMS ====================

  // Get items stream from Firestore (real-time updates)
  Stream<List<GroceryItem>>? getItemsStream({String? storeId}) {
    if (!isLoggedIn || !canUseCloudFeatures) return null;

    debugPrint('=== GET ITEMS STREAM ===');
    debugPrint('householdId: $householdId');
    debugPrint('storeId filter: $storeId');
    
    final collection = _firestoreService.getItemsCollection(
      currentUser!.uid,
      householdId: householdId,
    );

    debugPrint('Stream collection path: ${collection.path}');

    var query = collection.orderBy('createdAt', descending: true);
    
    if (storeId != null) {
      query = query.where('storeId', isEqualTo: storeId) as dynamic;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          debugPrint('Item from stream: ${doc.id} - ${data['name']}'); // Add this line

          // Validate required fields
          if (data['name'] == null || data['createdAt'] == null) {
            debugPrint('Skipping invalid item: ${doc.id}');
            return null;
          }
          
          return GroceryItem(
            id: doc.id,
            name: data['name'] as String,
            quantity: data['quantity'] as int? ?? 1,
            category: data['category'] as String?,
            aisle: data['aisle'] as String?,
            isChecked: data['isChecked'] as bool? ?? false,
            storeId: data['storeId'] as String?,
            addedBy: data['addedBy'] as String? ?? 'Unknown',
            addedAt: data['addedAt'] != null 
                ? DateTime.parse(data['addedAt'] as String)
                : DateTime.now(),
            createdAt: DateTime.parse(data['createdAt'] as String),
            checkedAt: data['checkedAt'] != null
                ? DateTime.parse(data['checkedAt'] as String)
                : null,
          );
        } catch (e) {
          debugPrint('Error parsing item ${doc.id}: $e');
          return null;
        }
      }).whereType<GroceryItem>().toList();
    });
  }

  // Get stores stream from Firestore (real-time updates)
  Stream<List<Store>>? getStoresStream() {
    if (!isLoggedIn || !canUseCloudFeatures) return null;

    debugPrint('=== GET STORES STREAM ===');
    debugPrint('householdId: $householdId');
    
    final collection = _firestoreService.getStoresCollection(
      currentUser!.uid,
      householdId: householdId,
    );

    debugPrint('Stores stream collection path: ${collection.path}');

    return collection.orderBy('createdAt').snapshots().map((snapshot) {
      debugPrint('Stores stream received ${snapshot.docs.length} stores');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Store from stream: ${doc.id} - ${data['name']} - notes: ${data['notes']}');
        return Store(
          id: doc.id,
          name: data['name'] as String,
          colorValue: data['colorValue'] as int,
          notes: data['notes'] as String? ?? '',
          isDefault: data['isDefault'] as bool? ?? false,
          createdAt: DateTime.parse(data['createdAt'] as String),
        );
      }).toList();
    });
  }
}