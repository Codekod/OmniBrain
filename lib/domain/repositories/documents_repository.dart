import 'package:omnibrain_ai/domain/entities/document_entity.dart';

abstract class DocumentsRepository {
  Future<List<DocumentEntity>> getDocuments();

  Future<DocumentEntity> getDocumentById(String id);

  Future<DocumentEntity> saveDocument(DocumentEntity document);

  Future<void> deleteDocument(String id);
}
