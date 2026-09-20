import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/domain/entities/reminder_entity.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';

final remindersListProvider = FutureProvider<List<ReminderEntity>>((ref) async {
  final repo = ref.watch(remindersRepositoryProvider);
  final all = await repo.getReminders();
  return all;
});

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _selectedPriority = 'medium'; // 'high', 'medium', 'low'
  String _selectedCategory = 'Genel';   // 'İş', 'Kişisel', 'Ödeme', 'Sağlık', 'Genel'
  String _selectedRepeat = 'none';      // 'none', 'daily', 'weekdays', 'monthly'

  String _filterCategory = 'Tümü';

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<String> _categories = [
    'Tümü',
    'Genel',
    'İş',
    'Kişisel',
    'Ödeme',
    'Sağlık',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _speech.stop();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.coralRed;
      case 'low':
        return AppColors.softGreen;
      default:
        return AppColors.amber;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'İş':
        return AppColors.iceBlue;
      case 'Kişisel':
        return AppColors.softGreen;
      case 'Ödeme':
        return AppColors.amber;
      case 'Sağlık':
        return AppColors.coralRed;
      default:
        return AppColors.neonPurple;
    }
  }

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

  void _applyQuickTime(int hoursToAdd) {
    HapticFeedback.lightImpact();
    final target = DateTime.now().add(Duration(hours: hoursToAdd));
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _selectedTime = TimeOfDay(hour: target.hour, minute: target.minute);
    });
  }

  Future<void> _toggleVoiceInput(StateSetter setModalState) async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setModalState(() => _isListening = false);
      setState(() => _isListening = false);
      _speech.stop();
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setModalState(() => _isListening = false);
            setState(() => _isListening = false);
          }
        },
        onError: (_) {
          setModalState(() => _isListening = false);
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setModalState(() => _isListening = true);
        setState(() => _isListening = true);

        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
          ),
          localeId: 'tr_TR',
          onResult: (result) {
            setModalState(() {
              _titleController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _showAddReminderDialog() {
    _titleController.clear();
    _descController.clear();
    // Default to 1 hour later
    final defaultTime = DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(defaultTime.year, defaultTime.month, defaultTime.day);
    _selectedTime = TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
    _selectedPriority = 'medium';
    _selectedCategory = 'Genel';
    _selectedRepeat = 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.deepNightBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yeni Hatırlatıcı',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Voice mic button
                        GestureDetector(
                          onTap: () => _toggleVoiceInput(setModalState),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? AppColors.coralRed.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isListening ? AppColors.coralRed : Colors.white24,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening ? AppColors.coralRed : AppColors.iceBlue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isListening ? 'Dinleniyor' : 'Sesle Yaz',
                                  style: TextStyle(
                                    color: _isListening ? AppColors.coralRed : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Görev veya hatırlatıcı başlığı...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                        filled: true,
                        fillColor: AppColors.darkNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Not veya açıklama ekle (İsteğe bağlı)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: AppColors.darkNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority Selector
                    Text(
                      'Öncelik Seviyesi',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityOption('low', 'Düşük', AppColors.softGreen, setModalState),
                        const SizedBox(width: 8),
                        _buildPriorityOption('medium', 'Orta', AppColors.amber, setModalState),
                        const SizedBox(width: 8),
                        _buildPriorityOption('high', 'Yüksek', AppColors.coralRed, setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Text(
                      'Kategori',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: ['Genel', 'İş', 'Kişisel', 'Ödeme', 'Sağlık'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final color = _getCategoryColor(cat);
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: color.withValues(alpha: 0.25),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          labelStyle: TextStyle(
                            color: isSelected ? color : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          side: BorderSide(color: isSelected ? color : Colors.white10),
                          onSelected: (val) {
                            if (val) setModalState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Quick Schedule Buttons
                    Text(
                      'Hızlı Zamanlama',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuickTimeChip('+1 Saat', 1, setModalState),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip('+3 Saat', 3, setModalState),
                        const SizedBox(width: 8),
                        _buildQuickTimeChip('Yarın', 24, setModalState),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date & Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await _selectDate();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.iceBlue),
                            label: Text(
                              _selectedDate == null
                                  ? 'Tarih Seç'
                                  : DateFormat('dd MMM yyyy', 'tr').format(_selectedDate!),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await _selectTime();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.amber),
                            label: Text(
                              _selectedTime == null ? 'Saat Seç' : _selectedTime!.format(context),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (_titleController.text.trim().isEmpty ||
                              _selectedDate == null ||
                              _selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen bir başlık, tarih ve saat belirleyin.')),
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
                            id: '',
                            title: _titleController.text.trim(),
                            description: _descController.text.trim(),
                            dueDate: scheduledDateTime,
                            priority: _selectedPriority,
                            category: _selectedCategory,
                            repeat: _selectedRepeat,
                          );

                          await ref.read(remindersRepositoryProvider).createReminder(newEntity);
                          ref.invalidate(remindersListProvider);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          'Hatırlatıcıyı Kur',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityOption(String key, String label, Color color, StateSetter setModalState) {
    final isSelected = _selectedPriority == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => _selectedPriority = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, int hours, StateSetter setModalState) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _applyQuickTime(hours);
          setModalState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ),
        ),
      ),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Hatırlatıcılar & Görevler',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.neonPurple,
            indicatorWeight: 3,
            labelColor: AppColors.neonPurple,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.notifications_active_rounded), text: 'Aktif Görevler'),
              Tab(icon: Icon(Icons.task_alt_rounded), text: 'Tamamlananlar'),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12.0, right: 4.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddReminderDialog,
            backgroundColor: AppColors.neonPurple,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Yeni Hatırlatıcı',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: remindersAsync.when(
          data: (allReminders) {
            final activeReminders = allReminders.where((r) => !r.isCompleted).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

            final completedReminders = allReminders.where((r) => r.isCompleted).toList()
              ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Active Reminders with Category Filters
                _buildActiveTab(activeReminders),

                // TAB 2: Completed Reminders
                _buildCompletedTab(completedReminders),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonPurple),
          ),
          error: (error, _) => Center(
            child: Text('Hata: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(List<ReminderEntity> activeList) {
    final filteredList = activeList.where((r) {
      if (_filterCategory == 'Tümü') return true;
      return r.category == _filterCategory;
    }).toList();

    return Column(
      children: [
        // Category Horizontal Filter
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _filterCategory == cat;
              final color = cat == 'Tümü' ? AppColors.neonPurple : _getCategoryColor(cat);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filterCategory = cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.white24),
                      const SizedBox(height: 14),
                      Text(
                        _filterCategory == 'Tümü'
                            ? 'Planlanmış hatırlatıcı bulunmuyor.'
                            : 'Bu kategoride aktif görev yok.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final reminder = filteredList[index];
                    final isOverdue = reminder.isOverdue;
                    final priorityColor = _getPriorityColor(reminder.priority);
                    final catColor = _getCategoryColor(reminder.category);

                    return Dismissible(
                      key: Key(reminder.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.coralRed.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) async {
                        HapticFeedback.mediumImpact();
                        await ref.read(remindersRepositoryProvider).deleteReminder(reminder.id);
                        ref.invalidate(remindersListProvider);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isOverdue ? AppColors.coralRed.withValues(alpha: 0.5) : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left Priority Accent Bar
                            Container(
                              width: 5,
                              height: 64,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category and Priority badges
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            reminder.category,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getPriorityLabel(reminder.priority),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: priorityColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    Text(
                                      reminder.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (reminder.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        reminder.description,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),

                                    // Time
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: isOverdue ? AppColors.coralRed : AppColors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            DateFormat('dd MMM yyyy, HH:mm', 'tr').format(reminder.dueDate),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isOverdue ? AppColors.coralRed : AppColors.amber,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '(Gecikti)',
                                            style: TextStyle(
                                              color: AppColors.coralRed,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Complete Checkbox Button
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: AppColors.softGreen,
                                  size: 26,
                                ),
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  await ref.read(remindersRepositoryProvider).completeReminder(reminder.id);
                                  ref.invalidate(remindersListProvider);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCompletedTab(List<ReminderEntity> completedList) {
    if (completedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 14),
            Text(
              'Henüz tamamlanmış görev yok.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
      itemCount: completedList.length,
      itemBuilder: (context, index) {
        final reminder = completedList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM, HH:mm', 'tr').format(reminder.dueDate),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await ref.read(remindersRepositoryProvider).deleteReminder(reminder.id);
                  ref.invalidate(remindersListProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
