import 'package:hive/hive.dart';

part 'store.g.dart';

@HiveType(typeId: 1)
class Store extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  bool isDefault;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  String notes; // Notes/comments for this store

  Store({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
    this.colorValue = 0xFF4CAF50,
    this.notes = '',
  });

  Store copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isDefault,
    int? colorValue,
    String? notes,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      colorValue: colorValue ?? this.colorValue,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Store(id: $id, name: $name, isDefault: $isDefault, colorValue: $colorValue)';
  }
}