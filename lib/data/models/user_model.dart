import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String language;
  final UserPlan plan;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.language = 'tr',
    this.plan = UserPlan.free,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      language: json['language'] as String? ?? 'tr',
      plan: UserPlan.fromString(json['plan'] as String? ?? 'free'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'language': language,
      'plan': plan.toJsonString(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email,
      language: language,
      plan: plan,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      language: entity.language,
      plan: entity.plan,
      createdAt: entity.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, fullName: $fullName, email: $email, plan: $plan)';
}
