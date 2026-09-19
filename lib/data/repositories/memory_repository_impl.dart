import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnibrain_ai/domain/entities/note.dart';
import 'package:omnibrain_ai/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  static const String _storageKey = 'omnibrain_memory_notes';

  @override
  Future<void> saveNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(_storageKey) ?? [];
    
    // Aynı ID varsa güncelle, yoksa ekle
    final existingIndex = notesJson.indexWhere((jsonStr) {
      final existingNote = Note.fromJson(jsonStr);
      return existingNote.id == note.id;
    });

    if (existingIndex >= 0) {
      notesJson[existingIndex] = note.toJson();
    } else {
      notesJson.add(note.toJson());
    }

    await prefs.setStringList(_storageKey, notesJson);
  }

  @override
  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(_storageKey) ?? [];
    
    final notes = notesJson.map((jsonStr) => Note.fromJson(jsonStr)).toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // En yeni en üstte
    return notes;
  }

  @override
  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = prefs.getStringList(_storageKey) ?? [];
    
    notesJson.removeWhere((jsonStr) {
      final note = Note.fromJson(jsonStr);
      return note.id == id;
    });

    await prefs.setStringList(_storageKey, notesJson);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
