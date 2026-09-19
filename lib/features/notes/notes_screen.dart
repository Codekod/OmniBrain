import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:omnibrain_ai/core/constants/app_colors.dart';
import 'package:omnibrain_ai/core/theme/text_styles.dart';
import 'package:omnibrain_ai/core/widgets/gradient_background.dart';
import 'package:omnibrain_ai/features/notes/providers/notes_providers.dart';
import 'package:omnibrain_ai/presentation/providers/app_providers.dart';
import 'package:omnibrain_ai/l10n/app_localizations.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  List<Map<String, String>> _chatHistory = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      if (_textController.text.isNotEmpty) {
        _processMessage(_textController.text);
      }
    } else {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni gerekli')),
        );
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setState(() => _isListening = false);
            if (_textController.text.isNotEmpty) {
              _processMessage(_textController.text);
            }
          }
        },
        onError: (val) => print('onError: $val'),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
          localeId: 'tr_TR',
        );
      }
    }
  }

  Future<void> _processMessage(String message) async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    final query = message.trim();
    if (query.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _chatHistory.add({'type': 'user', 'text': query});
      _isLoading = true;
    });
    _scrollToBottom();

    final notesState = ref.read(notesProvider);
    final notes = notesState.value ?? [];
    
    final contextLines = notes.map((n) {
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt);
      return "Tarih: $dateStr\nNot: ${n.content}";
    }).toList();

    try {
      final aiRepo = ref.read(aiCommandRepositoryProvider);
      final responseStr = await aiRepo.askMemory(query, contextLines);
      
      final cleanJson = responseStr.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanJson);

      final action = data['action'];
      final msg = data['message'] ?? 'Anlaşılmadı.';
      
      if (action == 'save') {
        final noteToSave = data['note'] ?? query;
        ref.read(notesProvider.notifier).addNote(noteToSave);
      }

      setState(() {
        _chatHistory.add({'type': 'ai', 'text': msg});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add({'type': 'ai', 'text': 'Sistemsel bir hata oluştu: $e'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              Text(l10n.notesTitle),
              Text('$memoryCount ${l10n.notesEmpty}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt, color: AppColors.iceBlue),
              onPressed: () {
                _showMemoryListDialog(context, notesState);
              },
            )
          ],
        ),
        body: Column(
          children: [
            if (_chatHistory.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text(
                        "Bana her şeyi sorabilir\nveya yeni bir hatıra kaydedebilirsin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Örn: 'Markete 500 tl harcadım'\nveya 'Geçen ay markete ne harcadım?'",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
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

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.iceBlue, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text("Hafıza taranıyor...", style: TextStyle(color: AppColors.iceBlue.withOpacity(0.8))),
                  ],
                ),
              ).animate().fadeIn(),

            _buildInputArea(),
          ],
        ),
      ),
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
          border: Border.all(color: AppColors.neonPurple.withOpacity(0.5), width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    ).animate().slideX(begin: 0.2, end: 0).fadeIn();
  }

  Widget _buildAiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.iceBlue.withOpacity(0.1),
          border: Border.all(color: AppColors.iceBlue.withOpacity(0.3)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.iceBlue, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.2, end: 0).fadeIn();
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNightBlue.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Mikrofon Butonu
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.coralRed.withOpacity(0.2) : Colors.transparent,
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
          if (_isListening) const SizedBox(width: 8) else const SizedBox(width: 12),
          
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isListening ? "Dinliyorum..." : "Yaz veya konuş...",
                hintStyle: TextStyle(color: _isListening ? AppColors.coralRed : Colors.white38),
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
                  borderSide: BorderSide(color: AppColors.neonPurple.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _processMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_textController.text.isNotEmpty) {
                _processMessage(_textController.text);
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
                    color: AppColors.neonPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemoryListDialog(BuildContext context, AsyncValue notesState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNightBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final notes = notesState.value ?? [];
            if (notes.isEmpty) {
              return const Center(child: Text("Hafıza boş.", style: TextStyle(color: Colors.white)));
            }
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Text("Tüm Kayıtlar", style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.coralRed.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(notesProvider.notifier).deleteNote(note.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(note.content, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
