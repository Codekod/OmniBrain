import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import 'package:omnibrain_ai/core/models/chat_message.dart';
import 'package:omnibrain_ai/core/providers/revenuecat_provider.dart';
import 'package:omnibrain_ai/core/providers/usage_limit_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GeminiChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  ChatSession? _chatSession;
  final _uuid = const Uuid();

  GeminiChatNotifier(this.ref) : super(const ChatState()) {
    _initChat();
  }

  void _initChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('GEMINI_API_KEY is not defined in .env');
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "Sen OmniBrain adında akıllı, premium ve çok yetenekli bir yapay zeka asistanısın. Kullanıcılara yardımcı, net ve Türkçe yanıtlar verirsin. Yanıtlarını Markdown formatında güzelce düzenle.",
      ),
    );

    _chatSession = model.startChat(history: []);
  }

  void clearChat() {
    _initChat();
    state = const ChatState();
  }

  Future<bool> _canSendMessage() async {
    final isPro = ref.read(revenueCatProvider).isPro;
    if (isPro) return true;

    return await ref.read(usageLimitProvider.notifier).consumeCredit(isPro);
  }

  int get remainingFreeMessages {
    final isPro = ref.read(revenueCatProvider).isPro;
    if (isPro) return 999;
    return ref.read(usageLimitProvider).remainingCredits;
  }

  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) return false;
    
    // Check Limits
    final canSend = await _canSendMessage();
    if (!canSend) {
      return false; // Let the UI handle paywall redirection
    }

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      role: MessageRole.user,
    );
    
    // Add loading AI message
    final aiLoadingMsgId = _uuid.v4();
    final loadingMsg = ChatMessage(
      id: aiLoadingMsgId,
      text: '',
      role: MessageRole.ai,
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
    );

    try {
      if (_chatSession == null) {
        throw Exception("API Key bulunamadı veya sohbet başlatılamadı.");
      }

      final response = await _chatSession!.sendMessage(Content.text(text));
      final responseText = response.text ?? "Yanıt alınamadı.";

      // Replace loading message with actual response
      final finalMsg = ChatMessage(
        id: aiLoadingMsgId,
        text: responseText,
        role: MessageRole.ai,
      );

      state = state.copyWith(
        messages: state.messages.map((m) => m.id == aiLoadingMsgId ? finalMsg : m).toList(),
        isLoading: false,
      );
      return true;

    } catch (e) {
      // Show error in the AI message bubble
      final errorMsg = ChatMessage(
        id: aiLoadingMsgId,
        text: 'Bir hata oluştu: $e',
        role: MessageRole.ai,
        isError: true,
      );
      state = state.copyWith(
        messages: state.messages.map((m) => m.id == aiLoadingMsgId ? errorMsg : m).toList(),
        isLoading: false,
      );
      return true; // The message was processed, albeit with an error
    }
  }
}

final geminiChatProvider = StateNotifierProvider<GeminiChatNotifier, ChatState>((ref) {
  return GeminiChatNotifier(ref);
});
