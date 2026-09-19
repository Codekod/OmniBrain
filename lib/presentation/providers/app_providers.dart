import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:omnibrain_ai/data/datasources/mock/mock_auth_service.dart';
import 'package:omnibrain_ai/core/providers/shared_prefs_provider.dart';
import 'package:omnibrain_ai/data/datasources/local/local_notes_service.dart';
import 'package:omnibrain_ai/data/datasources/local/local_reminders_service.dart';
import 'package:omnibrain_ai/data/datasources/mock/mock_documents_service.dart';
import 'package:omnibrain_ai/data/datasources/mock/mock_ai_actions_service.dart';
import 'package:omnibrain_ai/data/datasources/mock/mock_user_profile_service.dart';
import 'package:omnibrain_ai/data/datasources/mock/mock_subscription_service.dart';

import 'package:omnibrain_ai/data/repositories/auth_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/notes_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/documents_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/reminders_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/ai_actions_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/user_profile_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/ocr_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/ai_command_repository_impl.dart';
import 'package:omnibrain_ai/data/repositories/subscription_repository_impl.dart';

import 'package:omnibrain_ai/domain/repositories/ocr_repository.dart';
import 'package:omnibrain_ai/domain/repositories/ai_command_repository.dart';

// ─── Mock Service Providers ───────────────────────────────────────────────────

final mockAuthServiceProvider = Provider((ref) => MockAuthService());
final localNotesServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalNotesService(prefs);
});
final mockDocumentsServiceProvider = Provider((ref) => MockDocumentsService());
final localRemindersServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalRemindersService(prefs);
});
final mockAiActionsServiceProvider = Provider((ref) => MockAiActionsService());
final mockUserProfileServiceProvider =
    Provider((ref) => MockUserProfileService());
final mockSubscriptionServiceProvider =
    Provider((ref) => MockSubscriptionService());

// ─── Repository Providers ─────────────────────────────────────────────────────

final authRepositoryProvider = Provider(
  (ref) => AuthRepositoryImpl(ref.watch(mockAuthServiceProvider)),
);

final notesRepositoryProvider = Provider(
  (ref) => NotesRepositoryImpl(ref.watch(localNotesServiceProvider)),
);

final documentsRepositoryProvider = Provider(
  (ref) => DocumentsRepositoryImpl(ref.watch(mockDocumentsServiceProvider)),
);

final remindersRepositoryProvider = Provider(
  (ref) => RemindersRepositoryImpl(ref.watch(localRemindersServiceProvider)),
);

final aiActionsRepositoryProvider = Provider(
  (ref) => AiActionsRepositoryImpl(ref.watch(mockAiActionsServiceProvider)),
);

final userProfileRepositoryProvider = Provider(
  (ref) =>
      UserProfileRepositoryImpl(ref.watch(mockUserProfileServiceProvider)),
);

final ocrRepositoryProvider = Provider<OcrRepository>(
  (ref) => OcrRepositoryImpl(),
);

final aiCommandRepositoryProvider = Provider<AiCommandRepository>(
  (ref) => AiCommandRepositoryImpl(),
);

final subscriptionRepositoryProvider = Provider(
  (ref) =>
      SubscriptionRepositoryImpl(ref.watch(mockSubscriptionServiceProvider)),
);

// ─── Convenience Providers ────────────────────────────────────────────────────

final currentUserProvider = FutureProvider((ref) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getProfile();
});

final notesListProvider = FutureProvider((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.getNotes();
});

final remindersListProvider = FutureProvider((ref) async {
  final repo = ref.watch(remindersRepositoryProvider);
  return repo.getReminders();
});

final currentPlanProvider = FutureProvider((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getCurrentPlan();
});

final aiSuggestionsProvider = FutureProvider((ref) async {
  final repo = ref.watch(aiCommandRepositoryProvider);
  return repo.getSuggestions();
});
