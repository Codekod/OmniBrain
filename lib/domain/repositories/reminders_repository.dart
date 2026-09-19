import 'package:omnibrain_ai/domain/entities/reminder_entity.dart';

abstract class RemindersRepository {
  Future<List<ReminderEntity>> getReminders();

  Future<List<ReminderEntity>> getUpcomingReminders();

  Future<ReminderEntity> createReminder(ReminderEntity reminder);

  Future<ReminderEntity> completeReminder(String id);

  Future<void> deleteReminder(String id);
}
