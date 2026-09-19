import 'package:omnibrain_ai/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signOut();

  Future<UserEntity?> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}
