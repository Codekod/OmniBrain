import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/routing/app_router.dart';
import 'package:omnibrain_ai/core/services/meeting_export_service.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/domain/entities/note.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';
import 'package:omnibrain_ai/features/notes/widgets/voice_meeting_sheet.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI Chat controllers
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isAiLoading = false;
  final List<Map<String, String>> _chatHistory = [];

  // Notes list search & filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';

  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<String> _categories = [
    'Tümü',
    'Toplantı',
    'Ders & Eğitim',
    'İş',
    'Finans',
    'Fikirler',
    'Kişisel',
    'Genel',
  ];

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Toplantı':
        return AppColors.iceBlue;
      case 'Ders & Eğitim':
        return AppColors.amber;
      case 'İş':
        return const Color(0xFF38BDF8);
      case 'Finans':
        return AppColors.softGreen;
      case 'Fikirler':
        return const Color(0xFFA855F7);
      case 'Kişisel':
        return const Color(0xFFF43F5E);
      default:
        return AppColors.neonPurple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Toplantı':
        return Icons.groups_rounded;
      case 'Ders & Eğitim':
        return Icons.school_rounded;
      case 'İş':
        return Icons.business_center_rounded;
      case 'Finans':
        return Icons.account_balance_wallet_rounded;
      case 'Fikirler':
        return Icons.lightbulb_rounded;
      case 'Kişisel':
        return Icons.person_rounded;
      default:
        return Icons.sticky_note_2_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_chatInputController.text.isNotEmpty) {
        _processAiMessage(_chatInputController.text);
      }
    } else {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mikrofon izni gerekli')),
          );
        }
        return;
      }

      final available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_chatInputController.text.isNotEmpty) {
              _processAiMessage(_chatInputController.text);
            }
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            localeId: 'tr_TR',
          ),
          onResult: (val) {
            setState(() {
              _chatInputController.text = val.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _processAiMessage(String message) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    final query = message.trim();
    if (query.isEmpty) return;

    _chatInputController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _chatHistory.add({'type': 'user', 'text': query});
      _isAiLoading = true;
    });
    _scrollChatToBottom();

    final notesState = ref.read(notesProvider);
    final notes = notesState.value ?? [];

    final contextLines = notes.map((n) {
      final dateStr = DateFormat('yyyy-MM-dd').format(n.createdAt);
      return "[$dateStr] [${n.category}] ${n.content}";
    }).toList();

    try {
      final repo = ref.read(aiCommandRepositoryProvider);
      final responseText = await repo.askMemory(query, contextLines);

      if (responseText.startsWith("KAYDEDILDI:")) {
        final contentToSave = responseText.replaceFirst("KAYDEDILDI:", "").trim();
        // Determine category by query keywords
        String cat = 'Genel';
        final lowerQuery = query.toLowerCase();
        if (lowerQuery.contains('harca') || lowerQuery.contains('tl') || lowerQuery.contains('fiyat') || lowerQuery.contains('öde')) {
          cat = 'Finans';
        } else if (lowerQuery.contains('iş') || lowerQuery.contains('toplantı') || lowerQuery.contains('proje')) {
          cat = 'İş';
        } else if (lowerQuery.contains('fikir') || lowerQuery.contains('aklıma')) {
          cat = 'Fikirler';
        }

        await ref.read(notesProvider.notifier).addNote(contentToSave, category: cat);

        if (mounted) {
          setState(() {
            _chatHistory.add({
              'type': 'ai',
              'text': "Anlaşıldı! Bunu [$cat] kategorisine kaydettim:\n\"$contentToSave\"",
            });
            _isAiLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _chatHistory.add({'type': 'ai', 'text': responseText});
            _isAiLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'type': 'ai',
            'text': "Üzgünüm, hafıza sorgulanırken bir hata oluştu.",
          });
          _isAiLoading = false;
        });
      }
    }
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  void _openNoteEditor({Note? existingNote}) {
    HapticFeedback.lightImpact();
    context.push(
      RoutePaths.noteDetailPath(existingNote?.id ?? 'new'),
      extra: existingNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notesState = ref.watch(notesProvider);
    final memoryCount = notesState.value?.length ?? 0;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.notesTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$memoryCount kayıtlı not',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.iceBlue.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.mic_rounded, color: AppColors.iceBlue, size: 20),
              ),
              tooltip: 'Sesli Toplantı Kaydı (AI)',
              onPressed: () => VoiceMeetingSheet.show(context),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonPurple.withValues(alpha: 0.25),
                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
                tooltip: 'Yeni Not Ekle',
                onPressed: () => _openNoteEditor(),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.neonPurple,
            indicatorWeight: 3,
            labelColor: AppColors.neonPurple,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.sticky_note_2_rounded), text: 'Not Defterim'),
              Tab(icon: Icon(Icons.psychology_rounded), text: 'AI İkinci Beyin'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Rich Notes List
            _buildNotesListTab(notesState),

            // TAB 2: AI Second Brain Chat
            _buildAiChatTab(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _tabController.index == 0
            ? Padding(
                padding: const EdgeInsets.only(bottom: 84.0),
                child: FloatingActionButton.extended(
                  backgroundColor: AppColors.neonPurple,
                  elevation: 6,
                  onPressed: () => _openNoteEditor(),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  label: const Text('Yeni Not', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            : null,
      ),
    );
  }

  // --- TAB 1: NOTES LIST VIEW ---
  Widget _buildNotesListTab(AsyncValue<List<Note>> notesState) {
    return notesState.when(
      data: (allNotes) {
        // Filter by category and search query
        final filteredNotes = allNotes.where((note) {
          final matchesCategory = _selectedCategory == 'Tümü' || note.category == _selectedCategory;
          final matchesSearch = _searchQuery.isEmpty ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Notlarda ara...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Category Filter Horizontal Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  final color = cat == 'Tümü' ? AppColors.neonPurple : _getCategoryColor(cat);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 8),

            // Notes List
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.note_alt_outlined,
                            size: 56,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Aradığınız kriterde not bulunamadı"
                                : "Bu kategoride henüz not yok",
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        final catColor = _getCategoryColor(note.category);
                        final catIcon = _getCategoryIcon(note.category);
                        final dateStr = note.eventDate != null
                            ? DateFormat('dd MMM, HH:mm', 'tr').format(note.eventDate!)
                            : DateFormat('dd MMM, HH:mm', 'tr').format(note.createdAt);

                        return Dismissible(
                          key: Key(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.coralRed.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                          ),
                          onDismissed: (_) {
                            HapticFeedback.mediumImpact();
                            ref.read(notesProvider.notifier).deleteNote(note.id);
                          },
                          child: GestureDetector(
                            onTap: () => _openNoteEditor(existingNote: note),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: note.isPinned
                                      ? AppColors.amber.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: note.isPinned ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Metadata Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Category Pill & Event Date Pill
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: catColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: catColor.withValues(alpha: 0.35), width: 0.8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(catIcon, size: 13, color: catColor),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    note.category,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: catColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (note.eventDate != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.iceBlue.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.3), width: 0.8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.event_rounded, size: 12, color: AppColors.iceBlue),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      dateStr,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.iceBlue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Actions: Pin & Copy
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (note.eventDate == null)
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withValues(alpha: 0.4),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              ref.read(notesProvider.notifier).togglePinNote(note.id);
                                            },
                                            child: Icon(
                                              note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                              size: 18,
                                              color: note.isPinned ? AppColors.amber : Colors.white30,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              Clipboard.setData(ClipboardData(text: '${note.displayTitle}\n\n${note.displayBody}'));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Not panoya kopyalandı!'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            child: const Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                              color: Colors.white30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Title
                                  Text(
                                    note.displayTitle,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),

                                  if (note.displayBody.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      note.displayBody,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],

                                  // Photos preview strip
                                  if (note.imagePaths.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 48,
                                      child: Row(
                                        children: [
                                          ...note.imagePaths.take(3).map((path) {
                                            return Container(
                                              width: 48,
                                              height: 48,
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white24),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(9),
                                                child: Image.file(
                                                  File(path),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: Colors.white10,
                                                    child: const Icon(Icons.broken_image, size: 16, color: Colors.white30),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                          if (note.imagePaths.length > 3)
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white24),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '+${note.imagePaths.length - 3}',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 14),

                                  // Footer: Media chips & Share Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Badges: Photos, Audio
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (note.imagePaths.isNotEmpty) ...[
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white54),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${note.imagePaths.length}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                            ),
                                          ],
                                          if (note.audioPath != null) ...[
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.mic_none_rounded, size: 14, color: AppColors.coralRed),
                                                SizedBox(width: 4),
                                                Text('Ses', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Share Button (AirDrop, WhatsApp, Mail, PDF, Word)
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          MeetingExportService.showComprehensiveShareSheet(
                                            context: context,
                                            ref: ref,
                                            note: note,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.iceBlue.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.35), width: 0.8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.ios_share_rounded, size: 13, color: AppColors.iceBlue),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Paylaş & Aktar',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.iceBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.neonPurple),
      ),
      error: (err, _) => Center(
        child: Text('Notlar yüklenirken hata oluştu: $err', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- TAB 2: AI SECOND BRAIN CHAT ---
  Widget _buildAiChatTab() {
    return Column(
      children: [
        if (_chatHistory.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.psychology, size: 48, color: AppColors.iceBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "İkinci Beynine Sor veya Not Bırak",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Kaydettiğin tüm notlar hafızamda tutulur.\nİster konuşarak yeni not ekle, ister geçmişi sor.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        "💡 Örnek: 'Market için 350 TL harcadım' veya\n'Geçen ayki harcamalarım ne kadar tuttu?'",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ).animate().fadeIn(),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final item = _chatHistory[index];
                if (item['type'] == 'user') {
                  return _buildUserBubble(item['text']!);
                } else {
                  return _buildAiBubble(item['text']!);
                }
              },
            ),
          ),

        if (_isAiLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  "Hafıza taranıyor...",
                  style: TextStyle(color: AppColors.iceBlue.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ).animate().fadeIn(),

        _buildChatInputArea(),
      ],
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkNavy,
          border: Border.all(color: AppColors.iceBlue.withValues(alpha: 0.3), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.iceBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputArea() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final bottomPad = isKeyboardOpen ? 12.0 : (MediaQuery.of(context).padding.bottom + 84.0);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
      decoration: BoxDecoration(
        color: AppColors.deepNightBlue,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.coralRed.withValues(alpha: 0.2) : Colors.transparent,
                border: Border.all(
                  color: _isListening ? AppColors.coralRed : Colors.white24,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? AppColors.coralRed : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _chatInputController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Hafızaya sor veya not yaz...",
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.coralRed : Colors.white38,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.darkNavy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _processAiMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_chatInputController.text.isNotEmpty) {
                _processAiMessage(_chatInputController.text);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.neonPurple, AppColors.iceBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
