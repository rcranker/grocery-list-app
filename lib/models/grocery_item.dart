import 'package:hive/hive.dart';

part 'grocery_item.g.dart';

@HiveType(typeId: 0)
class GroceryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final String? category;

  @HiveField(4)
  final String? aisle;

  @HiveField(5)
  final bool isChecked;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? checkedAt;

  @HiveField(8)
  String? storeId;

  @HiveField(9)
  String addedBy; // Who added this item

  @HiveField(10)
  DateTime addedAt; // When it was added

  GroceryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.category,
    this.aisle,
    this.isChecked = false,
    required this.createdAt,
    this.checkedAt,
    this.storeId,
    this.addedBy = 'Unknown',
    DateTime? addedAt,
  }) : addedAt = addedAt ?? createdAt;

  // Factory constructor for creating from JSON (for Firebase later)
  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      category: json['category'] as String?,
      aisle: json['aisle'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      checkedAt: json['checkedAt'] != null 
          ? DateTime.parse(json['checkedAt'] as String)
          : null,
      storeId: json['storeId'] as String?,
      addedBy: json['addedBy'] as String? ?? 'Unknown',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  // Convert to JSON (for Firebase later)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'aisle': aisle,
      'isChecked': isChecked,
      'createdAt': createdAt.toIso8601String(),
      'checkedAt': checkedAt?.toIso8601String(),
      'storeId': storeId,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create a copy with modifications
  GroceryItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? category,
    String? aisle,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? checkedAt,
    String? storeId,
    String? addedBy,
    DateTime? addedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      aisle: aisle ?? this.aisle,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      checkedAt: checkedAt ?? this.checkedAt,
      storeId: storeId ?? this.storeId,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, quantity: $quantity, '
           'category: $category, isChecked: $isChecked, storeId: $storeId, '
           'addedBy: $addedBy)';
  }
}