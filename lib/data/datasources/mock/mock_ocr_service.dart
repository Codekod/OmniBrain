class MockOcrService {
  Future<String> processImage(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate OCR processing - returns a Turkish expense list
    return 'HARCAMA LİSTESİ\n'
        'Tarih: 30.05.2026\n'
        '================================\n'
        'Market alışverişi     :   580 TL\n'
        'Elektrik faturası     : 1.250 TL\n'
        'İnternet faturası     :   190 TL\n'
        '================================\n'
        'TOPLAM                : 2.020 TL\n'
        '\n'
        'Not: Tüm ödemeler banka kartı ile yapılmıştır.\n'
        'Dosya: $imagePath';
  }

  Future<List<double>> extractNumbers(String text) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Returns mock extracted numbers
    return [580, 1250, 190];
  }
}
