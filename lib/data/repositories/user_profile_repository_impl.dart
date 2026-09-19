import 'package:omnibrain_ai/data/datasources/mock/mock_user_profile_service.dart';
import 'package:omnibrain_ai/data/models/user_model.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';
import 'package:omnibrain_ai/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final MockUserProfileService _userProfileService;

  UserProfileRepositoryImpl(this._userProfileService);

  @override
  Future<UserEntity> getProfile() async {
    final model = await _userProfileService.getProfile();
    return model.toEntity();
  }

  @override
  Future<UserEntity> updateProfile(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    final updated = await _userProfileService.updateProfile(model);
    return updated.toEntity();
  }
}
