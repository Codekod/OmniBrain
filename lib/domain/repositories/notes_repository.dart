import 'package:omnibrain_ai/domain/entities/note_entity.dart';

abstract class NotesRepository {
  Future<List<NoteEntity>> getNotes();

  Future<NoteEntity> getNoteById(String id);

  Future<NoteEntity> createNote(NoteEntity note);

  Future<NoteEntity> updateNote(NoteEntity note);

  Future<void> deleteNote(String id);
}
