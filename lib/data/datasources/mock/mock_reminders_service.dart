import 'package:omnibrain_ai/data/models/reminder_model.dart';
import 'package:uuid/uuid.dart';

class MockRemindersService {
  static const _uuid = Uuid();

  final List<ReminderModel> _reminders = [
    ReminderModel(
      id: 'rem_001',
      title: 'Kira Ödemesi',
      description: 'Haziran ayı kira ödemesi - 22.000 TL, ev sahibi Ahmet Bey hesabına',
      dueDate: DateTime(2026, 6, 1, 9, 0),
      sourceDocumentId: 'doc_002',
      isCompleted: false,
    ),
    ReminderModel(
      id: 'rem_002',
      title: 'Diş Hekimi Randevusu',
      description: 'Dr. Ayşe Kara, Kadıköy Dental Klinik, saat 15:00. Kontrol muayenesi.',
      dueDate: DateTime(2026, 6, 5, 15, 0),
      isCompleted: false,
    ),
    ReminderModel(
      id: 'rem_003',
      title: 'Proje Toplantısı',
      description: 'OmniBrain AI projesi ilerleme toplantısı. Sprint retrospektif ve planlama.',
      dueDate: DateTime(2026, 6, 5, 10, 0),
      sourceDocumentId: 'doc_003',
      isCompleted: false,
    ),
    ReminderModel(
      id: 'rem_004',
      title: 'Elektrik Faturası Son Ödeme',
      description: 'Elektrik faturası son ödeme tarihi. Online bankacılık üzerinden ödenecek.',
      dueDate: DateTime(2026, 6, 10, 18, 0),
      isCompleted: false,
    ),
  ];

  Future<List<ReminderModel>> getReminders() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_reminders);
  }

  Future<List<ReminderModel>> getUpcomingReminders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return _reminders
        .where((r) => !r.isCompleted && r.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final newReminder = ReminderModel(
      id: 'rem_${_uuid.v4().substring(0, 8)}',
      title: reminder.title,
      description: reminder.description,
      dueDate: reminder.dueDate,
      sourceDocumentId: reminder.sourceDocumentId,
      isCompleted: false,
    );
    _reminders.add(newReminder);
    return newReminder;
  }

  Future<ReminderModel> completeReminder(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Hatırlatma bulunamadı: $id');
    }
    final completed = ReminderModel(
      id: _reminders[index].id,
      title: _reminders[index].title,
      description: _reminders[index].description,
      dueDate: _reminders[index].dueDate,
      sourceDocumentId: _reminders[index].sourceDocumentId,
      isCompleted: true,
    );
    _reminders[index] = completed;
    return completed;
  }

  Future<void> deleteReminder(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Exception('Hatırlatma bulunamadı: $id');
    }
    _reminders.removeAt(index);
  }
}
