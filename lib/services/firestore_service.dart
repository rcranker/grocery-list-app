import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_item.dart';
import '../models/store.dart';
import '../models/user_model.dart';
import 'dart:math';
import '../models/household.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 // ==================== USERS ====================

// Get user document reference
DocumentReference<Map<String, dynamic>> getUserDoc(String uid) {
  return _firestore.collection('users').doc(uid);
}

// Get user data from Firestore (ADD THIS METHOD)
Future<UserModel?> getUserData(String uid) async {
  try {
    final doc = await getUserDoc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  } catch (e) {
    debugPrint('Error getting user data: $e');
    return null;
  }
}

// Update user data
Future<void> updateUser(String uid, UserModel user) async {
  await getUserDoc(uid).set(user.toMap(), SetOptions(merge: true));
}

// Get user stream
Stream<UserModel?> getUserStream(String uid) {
  return getUserDoc(uid).snapshots().map((snapshot) {
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, uid);
    }
    return null;
  });
}
  // ==================== HOUSEHOLDS ====================

  // Get households collection
  CollectionReference<Map<String, dynamic>> getHouseholdsCollection() {
    return _firestore.collection('households');
  }

  // Create household
  Future<String> createHousehold({
    required String name,
    required String ownerId,
  }) async {
    final inviteCode = _generateInviteCode();
  
    final household = Household(
      id: '',
      name: name,
      ownerId: ownerId,
      memberIds: [ownerId],
      createdAt: DateTime.now(),
      inviteCode: inviteCode,
    );
    final docRef = await getHouseholdsCollection().add(household.toMap());
  
    // Update user's householdId - use set with merge to create if doesn't exist
    await getUserDoc(ownerId).set({
      'householdId': docRef.id,
    }, SetOptions(merge: true));
  
    return docRef.id;
  }

    // Join household by invite code
    Future<String?> joinHousehold({
      required String inviteCode,
      required String userId,
    }) async {
    // Find household with invite code
    final querySnapshot = await getHouseholdsCollection()
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw 'Invalid invite code';
    }

    final householdDoc = querySnapshot.docs.first;
    final household = Household.fromMap(householdDoc.data(), householdDoc.id);

    // Check if user is already a member
    if (household.memberIds.contains(userId)) {
      throw 'You are already a member of this household';
    }

    // Add user to household
    await householdDoc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
  });

    // Update user's householdId
    await getUserDoc(userId).update({'householdId': householdDoc.id});
    return householdDoc.id;
    }

    // Leave household
    Future<void> leaveHousehold({
      required String householdId,
      required String userId,
    }) async {
      final householdDoc = getHouseholdsCollection().doc(householdId);
      final householdSnapshot = await householdDoc.get();
  
    if (!householdSnapshot.exists) return;
  
    final household = Household.fromMap(householdSnapshot.data()!, householdId);

    // If owner is leaving, delete household
    if (household.ownerId == userId) {
      // Remove householdId from all members
      for (final memberId in household.memberIds) {
        await getUserDoc(memberId).update({'householdId': null});
      }
    // Delete household
    await householdDoc.delete();
    } else {
    // Remove user from household
    await householdDoc.update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
    // Remove householdId from user
    await getUserDoc(userId).update({'householdId': null});
  }
}

    // Get household by ID
    Future<Household?> getHousehold(String householdId) async {
      final doc = await getHouseholdsCollection().doc(householdId).get();
      if (doc.exists) {
        return Household.fromMap(doc.data()!, doc.id);
      }
      return null;
    }

    // Get household stream
    Stream<Household?> getHouseholdStream(String householdId) {
      return getHouseholdsCollection().doc(householdId).snapshots().map((snapshot) {
        if (snapshot.exists) {
        return Household.fromMap(snapshot.data()!, snapshot.id);
        }
        return null;
      });
    }
    // Get household members info
    Future<List<UserModel>> getHouseholdMembers(String householdId) async {
      final household = await getHousehold(householdId);
      if (household == null) return [];

      final members = <UserModel>[];
      for (final memberId in household.memberIds) {
        final user = await getUserData(memberId);
        if (user != null) {
          members.add(user);
        }
      }
      return members;
    }

    // Generate random invite code
    String _generateInviteCode() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars
      final random = Random();
      return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    }

    // Regenerate invite code
    Future<void> regenerateInviteCode(String householdId) async {
      final newCode = _generateInviteCode();
      await getHouseholdsCollection().doc(householdId).update({
        'inviteCode': newCode,
      });
    }

  // ==================== STORES ====================

  // Get stores collection for user
  CollectionReference<Map<String, dynamic>> getStoresCollection(String uid, {String? householdId}) {
    if (householdId != null) {
      // Household stores are shared
      return _firestore.collection('households').doc(householdId).collection('stores');
    } else {
      // Personal stores for users without household
      return getUserDoc(uid).collection('stores');
    }
  }


  // Add store
  Future<String> addStore(String uid, Store store) async {
    final docRef = await getStoresCollection(uid).add({
      'name': store.name,
      'colorValue': store.colorValue,
      'notes': store.notes,
      'isDefault': store.isDefault,
      'createdAt': store.createdAt.toIso8601String(),
    });
    return docRef.id;
  }

  // Update store
  Future<void> updateStore(String uid, String storeId, Store store) async {
    await getStoresCollection(uid).doc(storeId).update({
      'name': store.name,
      'colorValue': store.colorValue,
      'notes': store.notes,
      'isDefault': store.isDefault,
    });
  }

  // Delete store
  Future<void> deleteStore(String uid, String storeId) async {
    await getStoresCollection(uid).doc(storeId).delete();
  }

  // Get stores stream
  Stream<List<Store>> getStoresStream(String uid) {
    return getStoresCollection(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
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

  // ==================== GROCERY ITEMS ====================

  // Get items collection for user
  CollectionReference<Map<String, dynamic>> getItemsCollection(String uid, {String? householdId}) {
    if (householdId != null) {
      // Household items are shared
      return _firestore.collection('households').doc(householdId).collection('items');
    } else {
      // Personal items for users without household
      return getUserDoc(uid).collection('items');
    }
  }

  // Add item
  Future<String> addItem(String uid, GroceryItem item) async {
    final docRef = await getItemsCollection(uid).add({
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
    return docRef.id;
  }

  // Update item
  Future<void> updateItem(String uid, String itemId, GroceryItem item) async {
    await getItemsCollection(uid).doc(itemId).update({
      'name': item.name,
      'quantity': item.quantity,
      'category': item.category,
      'aisle': item.aisle,
      'isChecked': item.isChecked,
      'storeId': item.storeId,
      'checkedAt': item.checkedAt?.toIso8601String(),
    });
  }

  // Delete item
  Future<void> deleteItem(String uid, String itemId) async {
    await getItemsCollection(uid).doc(itemId).delete();
  }

  // Get items stream for a specific store
  Stream<List<GroceryItem>> getItemsStream(String uid, {String? storeId}) {
    Query<Map<String, dynamic>> query = getItemsCollection(uid);
    
    if (storeId != null) {
      query = query.where('storeId', isEqualTo: storeId);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GroceryItem(
          id: doc.id,
          name: data['name'] as String,
          quantity: data['quantity'] as int? ?? 1,
          category: data['category'] as String?,
          aisle: data['aisle'] as String?,
          isChecked: data['isChecked'] as bool? ?? false,
          storeId: data['storeId'] as String?,
          addedBy: data['addedBy'] as String? ?? 'Unknown',
          addedAt: DateTime.parse(data['addedAt'] as String),
          createdAt: DateTime.parse(data['createdAt'] as String),
          checkedAt: data['checkedAt'] != null
              ? DateTime.parse(data['checkedAt'] as String)
              : null,
        );
      }).toList();
    });
  }

  // Get all items stream (for all stores)
  Stream<List<GroceryItem>> getAllItemsStream(String uid) {
    return getItemsCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GroceryItem(
          id: doc.id,
          name: data['name'] as String,
          quantity: data['quantity'] as int? ?? 1,
          category: data['category'] as String?,
          aisle: data['aisle'] as String?,
          isChecked: data['isChecked'] as bool? ?? false,
          storeId: data['storeId'] as String?,
          addedBy: data['addedBy'] as String? ?? 'Unknown',
          addedAt: DateTime.parse(data['addedAt'] as String),
          createdAt: DateTime.parse(data['createdAt'] as String),
          checkedAt: data['checkedAt'] != null
              ? DateTime.parse(data['checkedAt'] as String)
              : null,
        );
      }).toList();
    });
  }

  // ==================== BATCH OPERATIONS ====================

  // Sync local items to Firestore (for initial upload)
  Future<void> syncLocalItemsToFirestore(String uid, List<GroceryItem> items) async {
    final batch = _firestore.batch();
    
    for (final item in items) {
      final docRef = getItemsCollection(uid).doc(item.id);
      batch.set(docRef, {
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
    
    await batch.commit();
  }

  // Sync local stores to Firestore
  Future<void> syncLocalStoresToFirestore(String uid, List<Store> stores) async {
    final batch = _firestore.batch();
    
    for (final store in stores) {
      final docRef = getStoresCollection(uid).doc(store.id);
      batch.set(docRef, {
        'name': store.name,
        'colorValue': store.colorValue,
        'notes': store.notes,
        'isDefault': store.isDefault,
        'createdAt': store.createdAt.toIso8601String(),
      });
    }
    
    await batch.commit();
  }
}