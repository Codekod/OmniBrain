import 'package:omnibrain_ai/data/datasources/local/local_notes_service.dart';
import 'package:omnibrain_ai/data/models/note_model.dart';
import 'package:omnibrain_ai/domain/entities/note_entity.dart';
import 'package:omnibrain_ai/domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  final LocalNotesService _notesService;

  NotesRepositoryImpl(this._notesService);

  @override
  Future<List<NoteEntity>> getNotes() async {
    final models = await _notesService.getNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<NoteEntity> getNoteById(String id) async {
    final model = await _notesService.getNoteById(id);
    return model.toEntity();
  }

  @override
  Future<NoteEntity> createNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    final created = await _notesService.createNote(model);
    return created.toEntity();
  }

  @override
  Future<NoteEntity> updateNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    final updated = await _notesService.updateNote(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteNote(String id) {
    return _notesService.deleteNote(id);
  }
}
