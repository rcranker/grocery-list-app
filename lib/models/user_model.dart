class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? householdId;
  final bool isPremium;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.householdId,
    this.isPremium = false,
    required this.createdAt,
  });

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      householdId: map['householdId'] as String?,
      isPremium: map['isPremium'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'householdId': householdId,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? householdId,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      householdId: householdId ?? this.householdId,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}