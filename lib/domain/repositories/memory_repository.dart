import 'package:omnibrain_ai/domain/entities/note.dart';

abstract class MemoryRepository {
  Future<void> saveNote(Note note);
  Future<List<Note>> getAllNotes();
  Future<void> deleteNote(String id);
  Future<void> clearAll();
}
