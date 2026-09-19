import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:omnibrain_ai/data/models/note_model.dart';

class LocalNotesService {
  static const String _notesKey = 'saved_notes';
  static const _uuid = Uuid();
  final SharedPreferences _prefs;

  LocalNotesService(this._prefs) {
    // İlk açılışta boşsa örnek bir not ekleyelim
    _initSampleNotesIfNeeded();
  }

  void _initSampleNotesIfNeeded() {
    final notesString = _prefs.getString(_notesKey);
    if (notesString == null || notesString.isEmpty) {
      final sampleNote = NoteModel(
        id: 'note_${_uuid.v4().substring(0, 8)}',
        title: 'OmniBrain\'e Hoşgeldin!',
        content: 'Buraya notlarını alabilirsin. Bu notlar telefonunun hafızasında kalıcı olarak saklanır.',
        tags: ['hoşgeldin', 'bilgi'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _saveAllNotes([sampleNote]);
    }
  }

  List<NoteModel> _getAllNotesSync() {
    final notesString = _prefs.getString(_notesKey);
    if (notesString == null || notesString.isEmpty) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(notesString);
      return decodedList.map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveAllNotes(List<NoteModel> notes) async {
    final encodedList = jsonEncode(notes.map((e) => e.toJson()).toList());
    await _prefs.setString(_notesKey, encodedList);
  }

  Future<List<NoteModel>> getNotes() async {
    // Senkron işlemi asenkron gibi sarıyoruz ki repository yapısı bozulmasın
    return _getAllNotesSync();
  }

  Future<NoteModel> getNoteById(String id) async {
    final notes = _getAllNotesSync();
    return notes.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Not bulunamadı: $id'),
    );
  }

  Future<NoteModel> createNote(NoteModel note) async {
    final notes = _getAllNotesSync();
    
    final newNote = NoteModel(
      id: 'note_${_uuid.v4().substring(0, 8)}',
      title: note.title,
      content: note.content,
      tags: note.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    notes.insert(0, newNote);
    await _saveAllNotes(notes);
    
    return newNote;
  }

  Future<NoteModel> updateNote(NoteModel note) async {
    final notes = _getAllNotesSync();
    final index = notes.indexWhere((n) => n.id == note.id);
    
    if (index == -1) {
      throw Exception('Not bulunamadı: ${note.id}');
    }
    
    final updated = NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      tags: note.tags,
      createdAt: notes[index].createdAt,
      updatedAt: DateTime.now(),
    );
    
    notes[index] = updated;
    await _saveAllNotes(notes);
    
    return updated;
  }

  Future<void> deleteNote(String id) async {
    final notes = _getAllNotesSync();
    final index = notes.indexWhere((n) => n.id == id);
    
    if (index == -1) {
      throw Exception('Not bulunamadı: $id');
    }
    
    notes.removeAt(index);
    await _saveAllNotes(notes);
  }
}
