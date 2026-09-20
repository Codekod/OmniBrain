import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/providers/gemini_provider.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/services/meeting_export_service.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/domain/entities/note.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? initialTitle;
  final String? initialContent;
  final String? noteId;

  const NoteDetailScreen({
    super.key,
    this.note,
    this.initialTitle,
    this.initialContent,
    this.noteId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _category = 'Genel';
  DateTime? _eventDate;
  bool _isPinned = false;
  List<String> _imagePaths = [];
  String? _audioPath;
  int? _audioDurationSeconds;
  bool _isAiBusy = false;
  String? _resolvedId;

  final List<Map<String, dynamic>> _categoryConfigs = [
    {'name': 'Toplantı', 'icon': Icons.groups_rounded, 'color': AppColors.iceBlue},
    {'name': 'Ders & Eğitim', 'icon': Icons.school_rounded, 'color': AppColors.amber},
    {'name': 'İş', 'icon': Icons.business_center_rounded, 'color': const Color(0xFF38BDF8)},
    {'name': 'Finans', 'icon': Icons.account_balance_wallet_rounded, 'color': AppColors.softGreen},
    {'name': 'Fikirler', 'icon': Icons.lightbulb_rounded, 'color': const Color(0xFFA855F7)},
    {'name': 'Kişisel', 'icon': Icons.person_rounded, 'color': const Color(0xFFF43F5E)},
    {'name': 'Genel', 'icon': Icons.sticky_note_2_rounded, 'color': AppColors.neonPurple},
  ];

  @override
  void initState() {
    super.initState();

    Note? note = widget.note;
    if (note == null && widget.noteId != null && widget.noteId != 'new') {
      final notes = ref.read(notesProvider).value ?? [];
      try {
        note = notes.firstWhere((n) => n.id == widget.noteId);
      } catch (_) {
        note = null;
      }
    }

    if (note != null) {
      _resolvedId = note.id;
      _titleController = TextEditingController(text: note.title.isNotEmpty ? note.title : note.displayTitle);
      _contentController = TextEditingController(text: note.content);
      _category = note.category;
      _eventDate = note.eventDate;
      _isPinned = note.isPinned;
      _imagePaths = List<String>.from(note.imagePaths);
      _audioPath = note.audioPath;
      _audioDurationSeconds = note.audioDurationSeconds;
    } else {
      _resolvedId = (widget.noteId != null && widget.noteId != 'new') ? widget.noteId : null;
      _titleController = TextEditingController(text: widget.initialTitle ?? '');
      _contentController = TextEditingController(text: widget.initialContent ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _speech.stop();
    super.dispose();
  }

  Color _getCategoryColor(String name) {
    for (final c in _categoryConfigs) {
      if (c['name'] == name) return c['color'] as Color;
    }
    return AppColors.neonPurple;
  }

  IconData _getCategoryIcon(String name) {
    for (final c in _categoryConfigs) {
      if (c['name'] == name) return c['icon'] as IconData;
    }
    return Icons.sticky_note_2_rounded;
  }

  Note _buildCurrentNote() {
    return Note(
      id: _resolvedId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      eventDate: _eventDate,
      category: _category,
      isPinned: _isPinned,
      imagePaths: _imagePaths,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
    );
  }

  Future<void> _saveNote({bool closeScreen = true}) async {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();

    if (title.isEmpty && body.isEmpty && _imagePaths.isEmpty) {
      if (closeScreen && mounted) Navigator.pop(context);
      return;
    }

    HapticFeedback.mediumImpact();

    if (_resolvedId != null) {
      final updated = _buildCurrentNote();
      await ref.read(notesProvider.notifier).updateNote(updated);
    } else {
      final newNote = await ref.read(notesProvider.notifier).addNote(
            body,
            title: title,
            eventDate: _eventDate,
            category: _category,
            isPinned: _isPinned,
            imagePaths: _imagePaths,
            audioPath: _audioPath,
            audioDurationSeconds: _audioDurationSeconds,
          );
      _resolvedId = newNote.id;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.softGreen, size: 20),
              SizedBox(width: 8),
              Text('Not kaydedildi'),
            ],
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.darkNavy,
        ),
      );
      if (closeScreen) Navigator.pop(context);
    }
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.lightImpact();
    final initial = _eventDate ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonPurple,
              onPrimary: Colors.white,
              surface: AppColors.darkNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.iceBlue,
              onPrimary: AppColors.deepNightBlue,
              surface: AppColors.darkNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() {
        _eventDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  void _showCategoryPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Not Kategorisi Seçin',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categoryConfigs.map((cfg) {
                final name = cfg['name'] as String;
                final icon = cfg['icon'] as IconData;
                final color = cfg['color'] as Color;
                final isSelected = _category == name;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = name);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.white10,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: isSelected ? color : Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? color : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Görsel veya Belge Ekle',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Ders tahtası, sunum slaytları, toplantı şeması veya fiş fotoğrafları ekleyin',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.neonPurple, size: 22),
              ),
              title: Text('Kamera ile Çek', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Anında fotoğraf çekerek nota ekleyin', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (photo != null && mounted) {
                  setState(() => _imagePaths.add(photo.path));
                }
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.iceBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.iceBlue, size: 22),
              ),
              title: Text('Galeriden Seç', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Galeriden bir veya birden çok fotoğraf ekleyin', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
                if (picked.isNotEmpty && mounted) {
                  setState(() {
                    for (final f in picked) {
                      _imagePaths.add(f.path);
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreviewDialog(String imagePath, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
                title: Text(
                  'Görsel Önizleme (${index + 1}/${_imagePaths.length})',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralRed),
                    tooltip: 'Görseli Kaldır',
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _imagePaths.removeAt(index));
                    },
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceDictation() async {
    HapticFeedback.lightImpact();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni verilmedi.')),
        );
      }
      return;
    }

    final available = await _speech.initialize(
      onError: (_) {},
      onStatus: (val) {},
    );

    if (available && mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.deepNightBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.coralRed.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.coralRed, width: 2),
                    ),
                    child: const Icon(Icons.mic_rounded, color: AppColors.coralRed, size: 36),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: const Duration(milliseconds: 700),
                      ),
                  const SizedBox(height: 18),
                  Text(
                    'Konuşun, Nota Eklensin',
                    style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Söyledikleriniz anında yazıya çevrilip notunuza eklenecektir...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coralRed,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.stop_rounded, color: Colors.white),
                    label: const Text('Dinlemeyi Bitir & Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _speech.stop();
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );

      _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          localeId: 'tr_TR',
        ),
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final prev = _contentController.text.trim();
            final updated = prev.isEmpty
                ? result.recognizedWords
                : '$prev ${result.recognizedWords}';
            _contentController.text = updated;
          }
        },
      );
    }
  }

  void _showAiAssistantSheet() {
    HapticFeedback.lightImpact();

    // PRO gate check
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      context.push(RoutePaths.paywall);
      return;
    }

    final currentText = _contentController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI analizi için önce biraz not yazın veya ses kaydedin.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.iceBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'OmniBrain AI Asistanı',
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Notunuzu profesyonel bir çıktıya veya eylem planına dönüştürün',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 18),
            _buildAiActionTile(
              icon: Icons.assignment_turned_in_rounded,
              color: AppColors.softGreen,
              title: 'Toplantı Eylem Planına Dönüştür',
              subtitle: 'Kararlar, katılımcılar ve yapılacaklar listesi (- [ ])',
              onTap: () {
                Navigator.pop(ctx);
                _runAiCommand(
                  promptPrefix:
                      'Aşağıdaki toplantı notlarını analiz et. Katılımcılar, görüşülen ana konular, alınan kararlar ve kimin ne yapacağını belirten eylem maddeleri (- [ ] şeklinde) olacak şekilde profesyonel bir toplantı tutanağı formatına dönüştür. Türkçe ve Markdown formatında olsun.\n\nNotlar:\n',
                  titlePrefix: 'Toplantı Tutanağı & Eylem Planı',
                );
              },
            ),
            _buildAiActionTile(
              icon: Icons.school_rounded,
              color: AppColors.amber,
              title: 'Ders Özetine & Ana Fikirlere Çevir',
              subtitle: 'Formüller, anahtar kavramlar ve sınav odaklı özet',
              onTap: () {
                Navigator.pop(ctx);
                _runAiCommand(
                  promptPrefix:
                      'Aşağıdaki ders notlarını bir öğrencinin en yüksek verimi alacağı şekilde düzenle. Ana kavramlar, formüller ve kurallar, ve madde madde özet başlıkları altında yapılandır. Türkçe ve Markdown formatında olsun.\n\nNotlar:\n',
                  titlePrefix: 'Ders Notu Özeti',
                );
              },
            ),
            _buildAiActionTile(
              icon: Icons.edit_note_rounded,
              color: AppColors.iceBlue,
              title: 'Yazıyı Profesyonelleştir & Düzenle',
              subtitle: 'İmla, üslup ve kurumsal dil düzeltmesi',
              onTap: () {
                Navigator.pop(ctx);
                _runAiCommand(
                  promptPrefix:
                      'Aşağıdaki notu kurumsal ve akıcı bir Türkçe ile yeniden yaz, yazım ve noktalama hatalarını gider, cümleleri daha profesyonel hale getir ama anlamı bozma.\n\nNot:\n',
                  titlePrefix: null,
                );
              },
            ),
            _buildAiActionTile(
              icon: Icons.format_list_bulleted_rounded,
              color: const Color(0xFFA855F7),
              title: '3-5 Maddelik Net Özet Çıkar',
              subtitle: 'En can alıcı kilit noktaları çıkarır',
              onTap: () {
                Navigator.pop(ctx);
                _runAiCommand(
                  promptPrefix:
                      'Aşağıdaki notun en can alıcı noktalarını 3-5 maddelik net ve vurucu bir özet haline getir.\n\nNot:\n',
                  titlePrefix: null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
      onTap: onTap,
    );
  }

  Future<void> _runAiCommand({required String promptPrefix, String? titlePrefix}) async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAiBusy = true);

    try {
      final model = ref.read(geminiModelProvider);
      if (model == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI servisine şu anda ulaşılamıyor.')),
          );
        }
        return;
      }
      final response = await model.generateContent([
        Content.text('$promptPrefix$text'),
      ]);

      final generated = response.text?.trim() ?? '';
      if (generated.isNotEmpty && mounted) {
        _showAiResultDialog(generated, titlePrefix);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI yanıt oluşturamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiBusy = false);
    }
  }

  void _showAiResultDialog(String aiResult, String? titlePrefix) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.iceBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Tarafından Oluşturuldu',
                  style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    aiResult,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      _contentController.text = '${_contentController.text}\n\n---\n\n$aiResult';
                      Navigator.pop(ctx);
                    },
                    child: const Text('Notun Altına Ekle', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (titlePrefix != null && _titleController.text.trim().isEmpty) {
                        _titleController.text = titlePrefix;
                      }
                      _contentController.text = aiResult;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Notu Değiştir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(_category);
    final catIcon = _getCategoryIcon(_category);
    final formattedEventDate = _eventDate != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(_eventDate!)
        : null;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              await _saveNote(closeScreen: true);
            },
          ),
          title: GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: catColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(catIcon, color: catColor, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    _category,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: catColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: catColor, size: 16),
                ],
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            // Pin toggle
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? AppColors.amber : Colors.white60,
                size: 20,
              ),
              tooltip: _isPinned ? 'Sabitlemeyi Kaldır' : 'Başa Sabitle',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isPinned = !_isPinned);
              },
            ),
            // Share Sheet
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: AppColors.iceBlue, size: 20),
              tooltip: 'Dışa Aktar & Paylaş (PDF, Word, WhatsApp, Mail)',
              onPressed: () {
                final currentNote = _buildCurrentNote();
                MeetingExportService.showComprehensiveShareSheet(
                  context: context,
                  ref: ref,
                  note: currentNote,
                );
              },
            ),
            // Save Checkmark
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.softGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.softGreen, size: 18),
                ),
                tooltip: 'Kaydet',
                onPressed: () => _saveNote(closeScreen: true),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isAiBusy)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.iceBlue,
                  minHeight: 2,
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meeting / Lesson Date Picker Pill
                      GestureDetector(
                        onTap: _pickDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _eventDate != null
                                ? AppColors.iceBlue.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _eventDate != null
                                  ? AppColors.iceBlue.withValues(alpha: 0.35)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 16,
                                color: _eventDate != null ? AppColors.iceBlue : Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedEventDate ?? '📅 Toplantı / Ders Tarihi Belirle',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: _eventDate != null ? FontWeight.w600 : FontWeight.normal,
                                  color: _eventDate != null ? Colors.white : Colors.white60,
                                ),
                              ),
                              if (_eventDate != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _eventDate = null);
                                  },
                                  child: const Icon(Icons.close_rounded, size: 15, color: Colors.white54),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Large Title TextField
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Toplantı veya Ders Başlığı...',
                          hintStyle: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),

                      // Photos Gallery Strip if any attached
                      if (_imagePaths.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EKLİ FOTOĞRAFLAR (${_imagePaths.length})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.white54,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showAddPhotoSheet,
                              child: Text(
                                '+ Fotoğraf Ekle',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.iceBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 94,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePaths.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (ctx, index) {
                              if (index == _imagePaths.length) {
                                return GestureDetector(
                                  onTap: _showAddPhotoSheet,
                                  child: Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add_photo_alternate_rounded, color: Colors.white60, size: 28),
                                    ),
                                  ),
                                );
                              }

                              final imgPath = _imagePaths[index];
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showImagePreviewDialog(imgPath, index),
                                    child: Container(
                                      width: 90,
                                      height: 94,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.file(
                                          File(imgPath),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.broken_image, color: Colors.white38),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _imagePaths.removeAt(index));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),
                      ],

                      // Note Content Body Editor
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.55,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Toplantı gündemi, alınan kararlar, ders notları veya maddeleri buraya yazın...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.3),
                            height: 1.55,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Studio Floating Toolbar
              _buildBottomStudioToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStudioToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.deepNightBlue.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: Colors.white12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Camera Quick Button
          _buildToolbarButton(
            icon: Icons.camera_alt_rounded,
            label: 'Kamera',
            color: AppColors.neonPurple,
            onTap: () async {
              final photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
              if (photo != null && mounted) {
                setState(() => _imagePaths.add(photo.path));
              }
            },
          ),

          // 2. Gallery Quick Button
          _buildToolbarButton(
            icon: Icons.photo_library_rounded,
            label: 'Fotoğraf',
            color: const Color(0xFF38BDF8),
            onTap: _showAddPhotoSheet,
          ),

          // 3. Live Speech-to-Text Button
          _buildToolbarButton(
            icon: Icons.mic_rounded,
            label: 'Sesle Yaz',
            color: AppColors.coralRed,
            onTap: _startVoiceDictation,
          ),

          // 4. Gemini AI Assistant
          _buildToolbarButton(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Analiz',
            color: AppColors.iceBlue,
            onTap: _showAiAssistantSheet,
          ),

          // 5. Share & Export (AirDrop, WhatsApp, Mail, PDF, Word)
          _buildToolbarButton(
            icon: Icons.ios_share_rounded,
            label: 'Paylaş',
            color: AppColors.amber,
            onTap: () {
              final currentNote = _buildCurrentNote();
              MeetingExportService.showComprehensiveShareSheet(
                context: context,
                ref: ref,
                note: currentNote,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
