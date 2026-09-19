import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:omnibrain_ai/domain/repositories/ocr_repository.dart';

class OcrRepositoryImpl implements OcrRepository {
  OcrRepositoryImpl();

  @override
  Future<String> processImage(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();
      return recognizedText.text;
    } catch (e) {
      textRecognizer.close();
      return "Metin okunamadı: $e";
    }
  }

  @override
  Future<List<double>> extractNumbers(String text) async {
    final regex = RegExp(r'\d+([.,]\d+)?');
    final matches = regex.allMatches(text);
    return matches.map((m) {
      final numStr = m.group(0)?.replaceAll(',', '.') ?? '0';
      return double.tryParse(numStr) ?? 0.0;
    }).toList();
  }
}
