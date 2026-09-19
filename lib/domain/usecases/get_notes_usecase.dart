import 'package:omnibrain_ai/domain/entities/note_entity.dart';
import 'package:omnibrain_ai/domain/repositories/notes_repository.dart';

class GetNotesUseCase {
  final NotesRepository _notesRepository;

  const GetNotesUseCase(this._notesRepository);

  Future<List<NoteEntity>> call() {
    return _notesRepository.getNotes();
  }
}
