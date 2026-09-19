import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:omnibrain_ai/domain/repositories/ai_command_repository.dart';

class AiCommandRepositoryImpl implements AiCommandRepository {
  AiCommandRepositoryImpl();

  @override
  Future<String> processCommand(String command) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'buraya_api_keyini_yapisitir') {
      return "Hata: Lütfen geçerli bir Gemini API anahtarını .env dosyasına ekleyin.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final content = [Content.text(command)];
      final response = await model.generateContent(content);
      return response.text ?? "Yapay zekadan yanıt alınamadı.";
    } catch (e) {
      if (e.toString().contains('not found')) {
        try {
          // Model bulunamadıysa mevcut modelleri listelemeyi deneyelim
          // Ancak google_generative_ai dart paketinde listModels doğrudan model instance'ından gelmeyebilir, 
          // bunun için http isteği yapabiliriz veya sadece genel bir hata dönebiliriz.
          return "AI İşlem Hatası: Kullanmaya çalıştığımız yapay zeka modeli (gemini-pro) Google API hesabınızda aktif değil. Lütfen Google AI Studio'da projenizin faturalandırma veya model erişim ayarlarını kontrol edin. Hata detayı: $e";
        } catch (_) {}
      }
      return "AI İşlem Hatası: $e";
    }
  }

  @override
  Future<List<String>> getSuggestions() async {
    return [
      "Bugünkü harcamalarımı hesapla",
      "Bu makaleyi 3 cümlede özetle",
      "İspanyolca bir çeviri yap",
      "Bir pomodoro seansı başlat",
      "Kamerayı açarak fiş tara"
    ];
  }

  Future<String> processTextCalculation(String text) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Anahtarı bulunamadı.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Sen akıllı bir problem çözücü, matematikçi ve finansal asistan (OCR Okuyucu)sın.
Kullanıcının yazdığı veya kameradan tarattığı ham metni analiz et. Tarama esnasında çevre kağıtlardan veya ekrandan sızan alakasız metinler (gürültüler, kenarlık yazıları, ilgisiz notlar) olabilir. Öncelikle bu gürültüleri ayıkla ve yok say.

İki ana senaryoya göre odaklan:

1. Fiş, Fatura veya Finansal Tablo: 
Metnin ana odağı harcamalar, gelirler, market ürünleri ve fiyatlar ise; sadece bu verileri çıkar ve sonucu SADECE geçerli bir JSON objesi olarak döndür. Başka hiçbir açıklama ekleme.
JSON formatı:
{
  "type": "finance",
  "items": [
    {
      "label": "İşlem adı (ör. Market, Maaş)",
      "amount": 150.5,
      "type": "expense" veya "income"
    }
  ],
  "totalExpense": 150.5,
  "totalIncome": 0,
  "balance": -150.5
}

2. Matematik Problemi, Mantık Sorusu veya Genel Soru:
Metin bir finans dökümü değilse, gürültüleri eledikten sonra kalan ana denklemi, problemi veya soruyu detaylı ve anlaşılır bir şekilde ÇÖZ.
Yanıtını JSON olarak DEĞİL, doğrudan Markdown formatında düz metin olarak ver. (Örn: "Bu denklemin çözümü şöyledir: ...")

Kullanıcının Metni/Taradığı Görsel (Ham OCR Çıktısı):
$text
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "{}";
    } catch (e) {
      return '{"error": "$e"}';
    }
  }

  Future<String> getPomodoroSuggestion(String task) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Anahtarı bulunamadı.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Sen bir kişisel verimlilik ve odaklanma (Pomodoro) koçusun.
Kullanıcı ne üzerinde çalışacağını veya nasıl hissettiğini yazacak.
Senin görevin, bu işin bilişsel zorluğuna göre en optimum odaklanma (çalışma) ve mola süresini dakika cinsinden belirlemek.
Ayrıca kullanıcıya kısa ve motive edici bir açıklama yap.

Örnekler:
- Zor/Derin işler (Yazılım, Matematik): 45dk odak, 10dk mola
- Rutin/Hafif işler (E-posta, temizlik): 25dk odak, 5dk mola
- Aşırı yoğun/yorgun hissedenler: 15dk odak, 5dk mola

Lütfen sonucu SADECE geçerli bir JSON objesi olarak döndür. Başka hiçbir metin veya markdown (```json) KULLANMA.
JSON formatı şu şekilde olmalı:
{
  "focusMinutes": 30,
  "breakMinutes": 5,
  "message": "Kısa ve motive edici bir tavsiye cümlesi."
}

Kullanıcının görevi veya durumu:
$task
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "{}";
    } catch (e) {
      return '{"error": "$e"}';
    }
  }

  Future<String> askMemory(String query, List<String> notesContext) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Anahtarı bulunamadı.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Sen kullanıcının kişisel asistanı ve akıllı hafızasısın.
Aşağıda kullanıcının uygulamaya daha önce kaydettiği tüm notların/hatıraların bir listesi (bağlam) bulunuyor.

Kullanıcının Notları (Bağlam):
${notesContext.isEmpty ? "Henüz kayıtlı not yok." : notesContext.join('\n---\n')}

Kullanıcının Yeni Mesajı:
$query

GÖREVİN:
Kullanıcının yeni mesajını analiz et. İki ihtimal var:
1. Kullanıcı sana YENİ BİR BİLGİ veriyor veya bir şey kaydetmeni istiyor. (Örn: "50 tl ye ıspanak aldım", "Yarın toplantım var")
   Bu durumda bu bilgiyi özetle ve kaydetmek üzere dön.
2. Kullanıcı sana geçmişi veya hafızanı SORUYOR. (Örn: "Geçen ay markete ne harcadım?", "Ispanağı kaça aldım?")
   Bu durumda bağlamdaki notlara bakarak cevap ver.

SADECE geçerli bir JSON formatında cevap ver. Başka hiçbir açıklama veya markdown (```json) KULLANMA.
Format şu olmalı:
- Eğer yeni bir bilgi kaydedilecekse:
{
  "action": "save",
  "note": "50 TL'ye 1 kg ıspanak alındı.",
  "message": "Bu harcamayı/bilgiyi hafızama kaydettim! ✨"
}
- Eğer bir soruya cevap verilecekse:
{
  "action": "answer",
  "note": "",
  "message": "Kayıtlarıma göre..."
}
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? '{"action": "answer", "message": "Üzgünüm, cevap üretemedim."}';
    } catch (e) {
      return '{"action": "answer", "message": "Hata: $e"}';
    }
  }

  Future<String> processConversion(String query) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Anahtarı bulunamadı.');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Sen "Evrensel Çevirici" (Universal Converter) adlı akıllı bir asistansın.
Kullanıcı sana doğal bir dille bir dönüştürme isteğinde bulunacak (Örn: "300 Fahrenheit kaç derece yapar?", "50 mil kaç km", "120 euro kaç lira").
Senin görevin bu dönüştürmeyi yapmak ve sonucu SADECE geçerli bir JSON objesi olarak döndürmek. Başka hiçbir metin veya markdown (```json) KULLANMA.

Eğer kullanıcı hedef birimi belirtmemişse (Örn: Sadece "300 fahrenheit" dediyse), mantıklı bir varsayım yap (Örn: Santigrat'a çevir).

JSON formatı şu şekilde olmalı:
{
  "originalValue": "300",
  "originalUnit": "Fahrenheit",
  "convertedValue": "148.89",
  "convertedUnit": "Santigrat",
  "message": "Kısa bir açıklama (Örn: Türkiye konumuna göre Santigrat olarak çevrildi.)"
}

Kullanıcının isteği:
$query
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "{}";
    } catch (e) {
      return '{"error": "$e"}';
    }
  }
}
