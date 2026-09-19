import 'package:omnibrain_ai/data/datasources/mock/mock_documents_service.dart';
import 'package:omnibrain_ai/data/models/document_model.dart';
import 'package:omnibrain_ai/domain/entities/document_entity.dart';
import 'package:omnibrain_ai/domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final MockDocumentsService _documentsService;

  DocumentsRepositoryImpl(this._documentsService);

  @override
  Future<List<DocumentEntity>> getDocuments() async {
    final models = await _documentsService.getDocuments();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DocumentEntity> getDocumentById(String id) async {
    final model = await _documentsService.getDocumentById(id);
    return model.toEntity();
  }

  @override
  Future<DocumentEntity> saveDocument(DocumentEntity document) async {
    final model = DocumentModel.fromEntity(document);
    final saved = await _documentsService.saveDocument(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteDocument(String id) {
    return _documentsService.deleteDocument(id);
  }
}
