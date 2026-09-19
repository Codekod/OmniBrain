import 'package:omnibrain_ai/data/datasources/local/local_reminders_service.dart';
import 'package:omnibrain_ai/data/models/reminder_model.dart';
import 'package:omnibrain_ai/domain/entities/reminder_entity.dart';
import 'package:omnibrain_ai/domain/repositories/reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  final LocalRemindersService _remindersService;

  RemindersRepositoryImpl(this._remindersService);

  @override
  Future<List<ReminderEntity>> getReminders() async {
    final models = await _remindersService.getReminders();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ReminderEntity>> getUpcomingReminders() async {
    final models = await _remindersService.getUpcomingReminders();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ReminderEntity> createReminder(ReminderEntity reminder) async {
    final model = ReminderModel.fromEntity(reminder);
    final created = await _remindersService.createReminder(model);
    return created.toEntity();
  }

  @override
  Future<ReminderEntity> completeReminder(String id) async {
    final model = await _remindersService.completeReminder(id);
    return model.toEntity();
  }

  @override
  Future<void> deleteReminder(String id) {
    return _remindersService.deleteReminder(id);
  }
}
