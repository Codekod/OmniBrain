import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock user profile data.
class MockUserProfile {
  final String name;
  final String email;
  final String plan;
  final String avatarInitials;

  const MockUserProfile({
    required this.name,
    required this.email,
    required this.plan,
    required this.avatarInitials,
  });
}

/// Provides the current user profile.
final userProfileProvider = FutureProvider<MockUserProfile>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return const MockUserProfile(
    name: 'Melih Eken',
    email: 'melih@omnibrain.ai',
    plan: 'Free',
    avatarInitials: 'ME',
  );
});

/// Provides the current plan name.
final currentPlanProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(userProfileProvider.future);
  return user.plan;
});
