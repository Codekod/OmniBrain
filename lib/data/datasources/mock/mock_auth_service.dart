import 'dart:async';

import 'package:omnibrain_ai/data/models/user_model.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class MockAuthService {
  final _authStateController = StreamController<UserModel?>.broadcast();

  UserModel? _currentUser;

  static final UserModel _mockUser = UserModel(
    id: 'usr_a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    fullName: 'Melih',
    email: 'melih@omnibrain.ai',
    language: 'tr',
    plan: UserPlan.lifetime,
    createdAt: DateTime(2025, 1, 15, 10, 30),
  );

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('E-posta ve şifre boş bırakılamaz.');
    }

    _currentUser = _mockUser.copyWith(email: email);
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Tüm alanlar doldurulmalıdır.');
    }

    _currentUser = UserModel(
      id: 'usr_new_${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      email: email,
      language: 'tr',
      plan: UserPlan.free,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }

  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser ??= _mockUser;
    return _currentUser;
  }

  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  void dispose() {
    _authStateController.close();
  }
}

extension _UserModelCopy on UserModel {
  UserModel copyWith({String? email}) {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email ?? this.email,
      language: language,
      plan: plan,
      createdAt: createdAt,
    );
  }
}
