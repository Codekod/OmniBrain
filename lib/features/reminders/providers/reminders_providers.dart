import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock reminder data structure.
class MockReminder {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;

  const MockReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });
}

/// Provides all reminders.
final remindersListProvider = FutureProvider<List<MockReminder>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  final now = DateTime.now();
  return [
    MockReminder(
      id: '1',
      title: 'Fatura Ödeme',
      description: 'Elektrik ve doğalgaz faturaları ödenecek',
      dueDate: now.add(const Duration(hours: 2)),
      isCompleted: false,
    ),
    MockReminder(
      id: '2',
      title: 'Doktor Randevusu',
      description: 'Diş hekimi kontrolü - Ataşehir',
      dueDate: now.add(const Duration(days: 1, hours: 3)),
      isCompleted: false,
    ),
    MockReminder(
      id: '3',
      title: 'Proje Teslimi',
      description: 'OmniBrain AI v1.0 teslim edilecek',
      dueDate: now.add(const Duration(days: 3)),
      isCompleted: false,
    ),
    MockReminder(
      id: '4',
      title: 'Anne Doğum Günü',
      description: 'Hediye ve pasta hazırlanacak',
      dueDate: now.add(const Duration(days: 7)),
      isCompleted: false,
    ),
  ];
});

/// Provides only upcoming (not completed) reminders sorted by due date.
final upcomingRemindersProvider = FutureProvider<List<MockReminder>>((ref) async {
  final all = await ref.watch(remindersListProvider.future);
  return all.where((r) => !r.isCompleted).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});
