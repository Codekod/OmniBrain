enum UserPlan {
  free,
  lifetime,
  aiPremium;

  String get displayName {
    switch (this) {
      case UserPlan.free:
        return 'Ücretsiz';
      case UserPlan.lifetime:
        return 'Ömür Boyu';
      case UserPlan.aiPremium:
        return 'AI Premium';
    }
  }

  static UserPlan fromString(String value) {
    switch (value) {
      case 'lifetime':
        return UserPlan.lifetime;
      case 'ai_premium':
      case 'aiPremium':
        return UserPlan.aiPremium;
      default:
        return UserPlan.free;
    }
  }

  String toJsonString() {
    switch (this) {
      case UserPlan.free:
        return 'free';
      case UserPlan.lifetime:
        return 'lifetime';
      case UserPlan.aiPremium:
        return 'ai_premium';
    }
  }
}

class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String language;
  final UserPlan plan;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.language = 'tr',
    this.plan = UserPlan.free,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? language,
    UserPlan? plan,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      language: language ?? this.language,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          language == other.language &&
          plan == other.plan &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      language.hashCode ^
      plan.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, fullName: $fullName, email: $email, language: $language, plan: $plan)';
}
