import 'package:omnibrain_ai/data/datasources/mock/mock_auth_service.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';
import 'package:omnibrain_ai/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MockAuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final userModel = await _authService.signIn(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final userModel = await _authService.signUp(
      email: email,
      password: password,
      name: name,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userModel = await _authService.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _authService.authStateChanges.map(
      (userModel) => userModel?.toEntity(),
    );
  }
}
