import 'package:omnibrain_ai/data/models/note_model.dart';
import 'package:uuid/uuid.dart';

class MockNotesService {
  static const _uuid = Uuid();

  final List<NoteModel> _notes = [
    NoteModel(
      id: 'note_001',
      title: 'Haftalık Toplantı Notları',
      content:
          'Pazartesi günü yapılan haftalık toplantıda şu konular ele alındı:\n'
          '1. Proje ilerleme durumu gözden geçirildi\n'
          '2. Yeni sprint hedefleri belirlendi\n'
          '3. Müşteri geri bildirimleri değerlendirildi\n'
          '4. Teknik borç azaltma planı oluşturuldu\n'
          '5. Bir sonraki toplantı Cuma günü saat 14:00\'te yapılacak',
      tags: ['toplantı', 'iş', 'haftalık'],
      createdAt: DateTime(2026, 5, 26, 14, 0),
      updatedAt: DateTime(2026, 5, 26, 15, 30),
    ),
    NoteModel(
      id: 'note_002',
      title: 'Alışveriş Listesi',
      content: '- Süt (1 litre)\n'
          '- Yumurta (30\'lu)\n'
          '- Tam buğday ekmeği\n'
          '- Domates (1 kg)\n'
          '- Salatalık (500 gr)\n'
          '- Zeytinyağı\n'
          '- Peynir (kaşar)\n'
          '- Makarna\n'
          '- Pirinç (2 kg)',
      tags: ['alışveriş', 'kişisel'],
      createdAt: DateTime(2026, 5, 28, 9, 0),
      updatedAt: DateTime(2026, 5, 28, 9, 0),
    ),
    NoteModel(
      id: 'note_003',
      title: 'Proje Fikirleri',
      content: 'Yeni uygulama fikirleri:\n\n'
          '• AI destekli not alma uygulaması ✅\n'
          '• Sesli komut ile belge tarama\n'
          '• Otomatik hatırlatma oluşturucu\n'
          '• Akıllı belge sınıflandırıcı\n'
          '• OCR ile fatura analizi\n\n'
          'Öncelik: OmniBrain AI uygulamasını tamamla',
      tags: ['proje', 'fikir', 'yazılım'],
      createdAt: DateTime(2026, 5, 20, 11, 0),
      updatedAt: DateTime(2026, 5, 29, 16, 45),
    ),
    NoteModel(
      id: 'note_004',
      title: 'Kitap Özetleri',
      content: '📚 "Atomic Habits" - James Clear\n\n'
          'Ana fikirler:\n'
          '- Küçük alışkanlıklar büyük değişimler yaratır\n'
          '- %1 günlük iyileşme, yılda %37 gelişme demek\n'
          '- Alışkanlık döngüsü: İşaret → İstek → Tepki → Ödül\n'
          '- Ortamını değiştir, alışkanlıklarını değiştir\n'
          '- Kimlik temelli alışkanlıklar daha kalıcıdır',
      tags: ['kitap', 'özet', 'kişisel gelişim'],
      createdAt: DateTime(2026, 5, 15, 20, 0),
      updatedAt: DateTime(2026, 5, 15, 21, 30),
    ),
    NoteModel(
      id: 'note_005',
      title: 'Günlük Plan',
      content: '🌅 Sabah Rutini:\n'
          '06:30 - Uyanış ve meditasyon\n'
          '07:00 - Egzersiz (30 dk)\n'
          '07:30 - Kahvaltı\n'
          '08:00 - Günlük hedefleri belirle\n\n'
          '💼 İş:\n'
          '09:00-12:00 - Derin çalışma bloku\n'
          '12:00-13:00 - Öğle arası\n'
          '13:00-17:00 - Toplantılar ve iletişim\n\n'
          '🌙 Akşam:\n'
          '18:00 - Spor\n'
          '19:30 - Akşam yemeği\n'
          '20:00 - Okuma\n'
          '22:00 - Uyku',
      tags: ['plan', 'günlük', 'rutin'],
      createdAt: DateTime(2026, 5, 30, 6, 30),
      updatedAt: DateTime(2026, 5, 30, 6, 30),
    ),
  ];

  Future<List<NoteModel>> getNotes() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_notes);
  }

  Future<NoteModel> getNoteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _notes.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Not bulunamadı: $id'),
    );
  }

  Future<NoteModel> createNote(NoteModel note) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final newNote = NoteModel(
      id: 'note_${_uuid.v4().substring(0, 8)}',
      title: note.title,
      content: note.content,
      tags: note.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, newNote);
    return newNote;
  }

  Future<NoteModel> updateNote(NoteModel note) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      throw Exception('Not bulunamadı: ${note.id}');
    }
    final updated = NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      tags: note.tags,
      createdAt: _notes[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _notes[index] = updated;
    return updated;
  }

  Future<void> deleteNote(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw Exception('Not bulunamadı: $id');
    }
    _notes.removeAt(index);
  }
}
