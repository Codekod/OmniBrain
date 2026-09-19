import 'package:omnibrain_ai/data/models/document_model.dart';
import 'package:omnibrain_ai/domain/entities/document_entity.dart';
import 'package:uuid/uuid.dart';

class MockDocumentsService {
  static const _uuid = Uuid();

  final List<DocumentModel> _documents = [
    DocumentModel(
      id: 'doc_001',
      title: 'Market Fişi - Migros',
      rawText: 'MİGROS SATIŞ FİŞİ\n'
          'Tarih: 28.05.2026\n'
          'Saat: 14:32\n'
          '----------------------------\n'
          'Süt 1L          : 45,90 TL\n'
          'Yumurta 30lu    : 89,90 TL\n'
          'Ekmek           : 12,50 TL\n'
          'Domates 1kg     : 34,90 TL\n'
          'Peynir Kaşar    : 129,90 TL\n'
          'Zeytinyağı 1L   : 249,90 TL\n'
          '----------------------------\n'
          'TOPLAM          : 562,00 TL\n'
          'Nakit           : 600,00 TL\n'
          'Para Üstü       : 38,00 TL',
      summary: 'Migros market alışverişi, toplam 562 TL. Temel gıda ürünleri.',
      sourceType: DocumentSourceType.camera,
      createdAt: DateTime(2026, 5, 28, 14, 35),
    ),
    DocumentModel(
      id: 'doc_002',
      title: 'Kira Sözleşmesi Özeti',
      rawText: 'KİRA SÖZLEŞMESİ\n\n'
          'Kiraya Veren: Ahmet Yılmaz\n'
          'Kiracı: Melih Eken\n'
          'Adres: Kadıköy, İstanbul\n\n'
          'Kira Bedeli: 22.000 TL/ay\n'
          'Depozito: 44.000 TL (2 aylık)\n'
          'Sözleşme Başlangıç: 01.01.2026\n'
          'Sözleşme Bitiş: 31.12.2026\n\n'
          'Özel Şartlar:\n'
          '- Evcil hayvan beslenemez\n'
          '- Aidat kiracıya aittir\n'
          '- Ödeme her ayın 1-5 arası yapılacak\n'
          '- Erken tahliye durumunda 1 ay önceden bildirim gereklidir',
      summary:
          'Kadıköy\'deki daire için yıllık kira sözleşmesi. Aylık 22.000 TL, depozito 44.000 TL.',
      sourceType: DocumentSourceType.file,
      createdAt: DateTime(2026, 1, 2, 10, 0),
    ),
    DocumentModel(
      id: 'doc_003',
      title: 'El Yazısı Not - Toplantı',
      rawText: 'Proje Durumu:\n'
          '- Backend API %80 tamamlandı\n'
          '- Flutter UI tasarım aşamasında\n'
          '- Test coverage %65\n\n'
          'Yapılacaklar:\n'
          '→ OCR modülü entegrasyonu\n'
          '→ AI komut işleme optimize edilecek\n'
          '→ Push notification altyapısı kurulacak\n'
          '→ App Store / Play Store dağıtım hazırlığı\n\n'
          'Sonraki toplantı: 5 Haziran 2026, 10:00',
      summary:
          'Proje ilerleme toplantısı notları. Backend %80, UI tasarım aşamasında.',
      sourceType: DocumentSourceType.camera,
      createdAt: DateTime(2026, 5, 29, 10, 30),
    ),
  ];

  Future<List<DocumentModel>> getDocuments() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_documents);
  }

  Future<DocumentModel> getDocumentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _documents.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Belge bulunamadı: $id'),
    );
  }

  Future<DocumentModel> saveDocument(DocumentModel document) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final existingIndex = _documents.indexWhere((d) => d.id == document.id);
    final doc = DocumentModel(
      id: existingIndex >= 0
          ? document.id
          : 'doc_${_uuid.v4().substring(0, 8)}',
      title: document.title,
      rawText: document.rawText,
      summary: document.summary,
      sourceType: document.sourceType,
      createdAt: existingIndex >= 0
          ? _documents[existingIndex].createdAt
          : DateTime.now(),
    );

    if (existingIndex >= 0) {
      _documents[existingIndex] = doc;
    } else {
      _documents.insert(0, doc);
    }
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw Exception('Belge bulunamadı: $id');
    }
    _documents.removeAt(index);
  }
}
