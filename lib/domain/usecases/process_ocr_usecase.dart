import 'package:omnibrain_ai/domain/repositories/ocr_repository.dart';

class ProcessOcrUseCase {
  final OcrRepository _ocrRepository;

  const ProcessOcrUseCase(this._ocrRepository);

  Future<String> call(String imagePath) {
    return _ocrRepository.processImage(imagePath);
  }
}
