import 'package:omnibrain_ai/data/models/ai_action_model.dart';
import 'package:uuid/uuid.dart';

class MockAiActionsService {
  static const _uuid = Uuid();

  final List<AiActionModel> _history = [
    AiActionModel(
      id: 'ai_001',
      actionType: 'summarize',
      inputText: 'Uzun bir kira sözleşmesi metni...',
      outputText:
          'Bu kira sözleşmesi, Kadıköy\'deki bir daire için 1 yıllık süreyi kapsamaktadır. '
          'Aylık kira bedeli 22.000 TL olup, 44.000 TL depozito alınmıştır. '
          'Ödeme her ayın ilk 5 günü içinde yapılmalıdır.',
      tokenUsage: 245,
      createdAt: DateTime(2026, 5, 28, 14, 0),
    ),
    AiActionModel(
      id: 'ai_002',
      actionType: 'extract_tasks',
      inputText: 'Toplantı notlarından görevleri çıkar...',
      outputText: '📋 Çıkarılan Görevler:\n'
          '1. OCR modülü entegrasyonunu tamamla\n'
          '2. AI komut işleme performansını optimize et\n'
          '3. Push notification altyapısını kur\n'
          '4. App Store dağıtım hazırlığı yap\n'
          '5. Test coverage\'ı %80\'e çıkar',
      tokenUsage: 189,
      createdAt: DateTime(2026, 5, 29, 11, 0),
    ),
    AiActionModel(
      id: 'ai_003',
      actionType: 'translate',
      inputText: 'Flutter is a UI toolkit for building natively compiled applications.',
      outputText:
          'Flutter, doğal olarak derlenmiş uygulamalar oluşturmak için kullanılan bir UI araç takımıdır.',
      tokenUsage: 78,
      createdAt: DateTime(2026, 5, 30, 9, 15),
    ),
  ];

  Future<AiActionModel> processAction({
    required String actionType,
    required String inputText,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    String outputText;
    int tokenUsage;

    switch (actionType) {
      case 'summarize':
        outputText =
            'Metin özeti: Verilen içerik analiz edildi. Ana konular belirlenip '
            'kısa ve öz bir şekilde özetlendi. Toplam ${inputText.split(' ').length} '
            'kelimelik metin 3 ana başlık altında değerlendirildi.';
        tokenUsage = 156;
        break;
      case 'extract_tasks':
        outputText = '📋 Tespit Edilen Görevler:\n'
            '1. Verilen metindeki ilk görev\n'
            '2. İkinci öncelikli görev\n'
            '3. Takip edilmesi gereken konu';
        tokenUsage = 120;
        break;
      case 'translate':
        outputText = 'Çeviri sonucu: "$inputText" metni başarıyla çevrildi.';
        tokenUsage = 95;
        break;
      case 'analyze':
        outputText = '📊 Analiz Sonuçları:\n'
            '- Metin uzunluğu: ${inputText.length} karakter\n'
            '- Kelime sayısı: ${inputText.split(' ').length}\n'
            '- Duygu analizi: Nötr\n'
            '- Kategori: Genel';
        tokenUsage = 134;
        break;
      default:
        outputText =
            'İşlem tamamlandı. "$actionType" türünde AI analizi gerçekleştirildi.';
        tokenUsage = 80;
    }

    final action = AiActionModel(
      id: 'ai_${_uuid.v4().substring(0, 8)}',
      actionType: actionType,
      inputText: inputText,
      outputText: outputText,
      tokenUsage: tokenUsage,
      createdAt: DateTime.now(),
    );

    _history.insert(0, action);
    return action;
  }

  Future<List<AiActionModel>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_history);
  }
}
