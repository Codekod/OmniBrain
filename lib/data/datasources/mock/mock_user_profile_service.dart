import 'package:omnibrain_ai/data/models/user_model.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class MockUserProfileService {
  UserModel _profile = UserModel(
    id: 'usr_a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    fullName: 'Melih',
    email: 'melih@omnibrain.ai',
    language: 'tr',
    plan: UserPlan.lifetime,
    createdAt: DateTime(2025, 1, 15, 10, 30),
  );

  Future<UserModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }

  Future<UserModel> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _profile = UserModel(
      id: _profile.id,
      fullName: user.fullName,
      email: user.email,
      language: user.language,
      plan: _profile.plan,
      createdAt: _profile.createdAt,
    );
    return _profile;
  }
}
