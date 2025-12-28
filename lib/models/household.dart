class Household {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final String? inviteCode;

  Household({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
    this.inviteCode,
  });

  factory Household.fromMap(Map<String, dynamic> map, String id) {
    return Household(
      id: id,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      memberIds: List<String>.from(map['memberIds'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      inviteCode: map['inviteCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'inviteCode': inviteCode,
    };
  }

  Household copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
    DateTime? createdAt,
    String? inviteCode,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}