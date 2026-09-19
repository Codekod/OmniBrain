import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:omnibrain_ai/data/models/reminder_model.dart';
import 'package:omnibrain_ai/core/services/notification_service.dart';

class LocalRemindersService {
  static const String _remindersKey = 'saved_reminders';
  static const _uuid = Uuid();
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();

  LocalRemindersService(this._prefs) {
    _initSampleRemindersIfNeeded();
  }

  void _initSampleRemindersIfNeeded() {
    final remindersString = _prefs.getString(_remindersKey);
    if (remindersString == null || remindersString.isEmpty) {
      final sampleReminder = ReminderModel(
        id: 'rem_${_uuid.v4().substring(0, 8)}',
        title: 'OmniBrain PRO\'yu İncele',
        description: 'Uygulamanın premium özelliklerine göz atmayı unutma.',
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        isCompleted: false,
      );
      
      _saveAllReminders([sampleReminder]);
      // Schedule the notification for sample
      _scheduleNotification(sampleReminder);
    }
  }

  List<ReminderModel> _getAllRemindersSync() {
    final remindersString = _prefs.getString(_remindersKey);
    if (remindersString == null || remindersString.isEmpty) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(remindersString);
      return decodedList.map((e) => ReminderModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveAllReminders(List<ReminderModel> reminders) async {
    final encodedList = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await _prefs.setString(_remindersKey, encodedList);
  }

  void _scheduleNotification(ReminderModel reminder) {
    if (reminder.isCompleted || reminder.dueDate.isBefore(DateTime.now())) return;
    
    // Hash ID to int for flutter_local_notifications ID
    final int notifId = reminder.id.hashCode;
    
    _notificationService.scheduleNotification(
      id: notifId,
      title: 'Hatırlatıcı: ${reminder.title}',
      body: reminder.description.isNotEmpty ? reminder.description : 'Görev zamanı geldi!',
      scheduledDate: reminder.dueDate,
    );
  }

  Future<List<ReminderModel>> getReminders() async {
    return _getAllRemindersSync();
  }

  Future<ReminderModel> getReminderById(String id) async {
    final reminders = _getAllRemindersSync();
    return reminders.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Hatırlatıcı bulunamadı: $id'),
    );
  }

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    final reminders = _getAllRemindersSync();
    
    final newReminder = ReminderModel(
      id: 'rem_${_uuid.v4().substring(0, 8)}',
      title: reminder.title,
      description: reminder.description,
      dueDate: reminder.dueDate,
      isCompleted: reminder.isCompleted,
    );
    
    reminders.insert(0, newReminder);
    await _saveAllReminders(reminders);
    _scheduleNotification(newReminder);
    
    return newReminder;
  }

  Future<ReminderModel> updateReminder(ReminderModel reminder) async {
    final reminders = _getAllRemindersSync();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    
    if (index == -1) {
      throw Exception('Hatırlatıcı bulunamadı: ${reminder.id}');
    }
    
    reminders[index] = reminder;
    await _saveAllReminders(reminders);
    
    if (reminder.isCompleted) {
      await _notificationService.cancelNotification(reminder.id.hashCode);
    } else {
      _scheduleNotification(reminder);
    }
    
    return reminder;
  }

  Future<void> deleteReminder(String id) async {
    final reminders = _getAllRemindersSync();
    final index = reminders.indexWhere((r) => r.id == id);
    
    if (index == -1) {
      throw Exception('Hatırlatıcı bulunamadı: $id');
    }
    
    reminders.removeAt(index);
    await _saveAllReminders(reminders);
    await _notificationService.cancelNotification(id.hashCode);
  }

  Future<List<ReminderModel>> getUpcomingReminders() async {
    final reminders = _getAllRemindersSync();
    final now = DateTime.now();
    return reminders
        .where((r) => !r.isCompleted && r.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<ReminderModel> completeReminder(String id) async {
    final reminders = _getAllRemindersSync();
    final index = reminders.indexWhere((r) => r.id == id);
    
    if (index == -1) {
      throw Exception('Hatırlatıcı bulunamadı: $id');
    }
    
    final current = reminders[index];
    final updated = ReminderModel(
      id: current.id,
      title: current.title,
      description: current.description,
      dueDate: current.dueDate,
      sourceDocumentId: current.sourceDocumentId,
      isCompleted: true,
    );
    
    reminders[index] = updated;
    await _saveAllReminders(reminders);
    await _notificationService.cancelNotification(updated.id.hashCode);
    
    return updated;
  }
}
