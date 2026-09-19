abstract class OcrRepository {
  Future<String> processImage(String imagePath);

  Future<List<double>> extractNumbers(String text);
}
