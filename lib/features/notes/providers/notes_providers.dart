import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnibrain_ai/domain/entities/note.dart';
import 'package:omnibrain_ai/data/repositories/memory_repository_impl.dart';
import 'package:omnibrain_ai/domain/repositories/memory_repository.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepositoryImpl();
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final MemoryRepository _repository;

  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      // Pinned notes come first, then latest by date
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNote(String content, {String category = 'Genel'}) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      category: category,
      isPinned: false,
    );
    await _repository.saveNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note updatedNote) async {
    await _repository.saveNote(updatedNote);
    await loadNotes();
  }

  Future<void> togglePinNote(String id) async {
    final currentNotes = state.value ?? [];
    final target = currentNotes.firstWhere((n) => n.id == id, orElse: () => currentNotes.first);
    final modified = target.copyWith(isPinned: !target.isPinned);
    await _repository.saveNote(modified);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadNotes();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return NotesNotifier(repo);
});
