class MockAiCommandService {
  Future<String> processCommand(String command) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('özetle') || lowerCommand.contains('özet')) {
      return '📝 Metin özetlendi:\n\n'
          'Verilen içerik analiz edildi ve ana noktalar çıkarıldı. '
          'Metin 3 ana tema etrafında şekillenmektedir: planlama, uygulama ve değerlendirme. '
          'Detaylı analiz için belge görüntüleyicisini kullanabilirsiniz.';
    }

    if (lowerCommand.contains('hatırlat') || lowerCommand.contains('reminder')) {
      return '⏰ Hatırlatma oluşturuldu:\n\n'
          'Komutunuz analiz edildi ve ilgili hatırlatma sisteme eklendi. '
          'Bildirim zamanı geldiğinde size haber verilecektir.';
    }

    if (lowerCommand.contains('çevir') || lowerCommand.contains('translate')) {
      return '🌍 Çeviri tamamlandı:\n\n'
          'Metin başarıyla hedef dile çevrildi. '
          'Çeviri doğruluğu: %95. Bağlama göre bazı ifadeler uyarlanmıştır.';
    }

    if (lowerCommand.contains('analiz') || lowerCommand.contains('analyze')) {
      return '📊 Analiz tamamlandı:\n\n'
          'İçerik detaylı olarak analiz edildi.\n'
          '- Duygu analizi: Pozitif (%72)\n'
          '- Okunabilirlik: Orta\n'
          '- Anahtar kelimeler: proje, geliştirme, plan\n'
          '- Önerilen aksiyon: Planlama aşamasına geçiş';
    }

    return '🤖 Komut işlendi:\n\n'
        '"$command" komutu başarıyla analiz edildi. '
        'Sonuçlar hazırlandı. Daha detaylı bir işlem için '
        'lütfen komutu daha spesifik hale getirin.';
  }

  Future<List<String>> getSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      'Son belgeyi özetle',
      'Bu haftaki hatırlatmalarımı göster',
      'Fotoğraftaki metni tara ve kaydet',
      'Toplantı notlarından görevleri çıkar',
      'Harcama raporumu analiz et',
    ];
  }
}
