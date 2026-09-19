import 'package:omnibrain_ai/domain/entities/user_entity.dart';

abstract class UserProfileRepository {
  Future<UserEntity> getProfile();

  Future<UserEntity> updateProfile(UserEntity user);
}
