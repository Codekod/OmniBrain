import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/services/meeting_export_service.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? noteId;

  const NoteDetailScreen({
    super.key,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showExportSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Not Raporu';
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarmak için not metni boş olamaz.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepNightBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notu Dışa Aktar',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Kurumsal PDF veya düzenlenebilir Word belgesi oluşturun',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48)),
              ),
              title: Text('PDF Raporu Olarak Paylaş', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Kurumsal antetli, profesyonel dizgi', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                Navigator.pop(ctx);
                MeetingExportService.exportToPdf(
                  context: context,
                  ref: ref,
                  title: title,
                  content: content,
                );
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB)),
              ),
              title: Text('Word (.doc) Olarak Paylaş', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Düzenlenebilir Microsoft Word formatı', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                Navigator.pop(ctx);
                MeetingExportService.exportToWord(
                  context: context,
                  ref: ref,
                  title: title,
                  content: content,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final body = _contentController.text.trim();
    if (body.isEmpty) return;

    final fullContent = title.isNotEmpty ? '# $title\n\n$body' : body;
    ref.read(notesProvider.notifier).addNote(fullContent, category: 'Genel');
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Not Düzenle',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
              tooltip: 'Dışa Aktar (PDF / Word)',
              onPressed: () => _showExportSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.softGreen),
              tooltip: 'Kaydet',
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Başlık (İsteğe bağlı)',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTextStyles.bodyText.copyWith(color: Colors.white, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Notunuzu yazın...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
