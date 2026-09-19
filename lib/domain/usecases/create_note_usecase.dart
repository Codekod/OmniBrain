import 'package:omnibrain_ai/domain/entities/note_entity.dart';
import 'package:omnibrain_ai/domain/repositories/notes_repository.dart';

class CreateNoteUseCase {
  final NotesRepository _notesRepository;

  const CreateNoteUseCase(this._notesRepository);

  Future<NoteEntity> call(NoteEntity note) {
    return _notesRepository.createNote(note);
  }
}
