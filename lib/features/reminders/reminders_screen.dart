import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/domain/entities/reminder_entity.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

final remindersListProvider = FutureProvider<List<ReminderEntity>>((ref) async {
  final repo = ref.watch(remindersRepositoryProvider);
  final all = await repo.getReminders();
  
  // Sadece tamamlanmamış ve gelecek hatırlatıcıları göster veya tümünü göster
  return all.where((r) => !r.isCompleted).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonPurple,
              onPrimary: Colors.white,
              surface: AppColors.deepNightBlue,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonPurple,
              surface: AppColors.deepNightBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _showAddReminderDialog() {
    _titleController.clear();
    _descController.clear();
    _selectedDate = null;
    _selectedTime = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.deepNightBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Hatırlatıcı Ekle',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Başlık',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Açıklama (Opsiyonel)',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _selectDate();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.calendar_today, size: 18, color: AppColors.iceBlue),
                            label: Text(
                              _selectedDate == null ? 'Tarih Seç' : DateFormat('dd MMM').format(_selectedDate!),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _selectTime();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.access_time, size: 18, color: AppColors.amber),
                            label: Text(
                              _selectedTime == null ? 'Saat Seç' : _selectedTime!.format(context),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (_titleController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen başlık, tarih ve saat seçin!')),
                            );
                            return;
                          }

                          final scheduledDateTime = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );
                          
                          if (scheduledDateTime.isBefore(DateTime.now())) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Geçmiş bir zamana hatırlatıcı kurulamaz!')),
                            );
                            return;
                          }

                          final newEntity = ReminderEntity(
                            id: '', // repo creates id
                            title: _titleController.text,
                            description: _descController.text,
                            dueDate: scheduledDateTime,
                          );

                          await ref.read(remindersRepositoryProvider).createReminder(newEntity);
                          ref.invalidate(remindersListProvider);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Kaydet ve Kur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersListProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Hatırlatıcılar',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddReminderDialog,
          backgroundColor: AppColors.neonPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Yeni Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'Hiç hatırlatıcınız yok.',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final isOverdue = reminder.dueDate.isBefore(DateTime.now());

                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isOverdue ? AppColors.coralRed.withValues(alpha: 0.5) : Colors.white12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      reminder.title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reminder.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(reminder.description, style: const TextStyle(color: Colors.white70)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isOverdue ? AppColors.coralRed : AppColors.amber),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(reminder.dueDate),
                              style: TextStyle(
                                color: isOverdue ? AppColors.coralRed : AppColors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.softGreen),
                      onPressed: () async {
                        await ref.read(remindersRepositoryProvider).completeReminder(reminder.id);
                        ref.invalidate(remindersListProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hatırlatıcı tamamlandı!')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonPurple)),
          error: (error, stack) => Center(child: Text('Hata: $error', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}
