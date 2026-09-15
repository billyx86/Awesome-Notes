import 'dart:async';

import 'package:awesomenotes/models/note.dart';
import 'package:awesomenotes/repositories/notes_repository.dart';

/// A synchronous, in-memory [NotesRepository] for widget tests.
///
/// Stream controllers are sync, so a `pumpAndSettle` after a mutation sees
/// the updated list without any timers.
class InMemoryNotesRepository implements NotesRepository {
  final Map<String, StreamController<List<Note>>> _streams = {};
  final Map<String, List<Note>> _notes = {};

  List<Note> _all(String uid) => _notes[uid] ?? const [];

  List<Note> _sorted(String uid) {
    final notes = List<Note>.from(_all(uid));
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  void _emit(String uid) {
    _streams[uid]?.add(_sorted(uid));
  }

  /// Seed notes for a uid without going through [createNote], so tests can
  /// control `updatedAt` exactly (createNote stamps DateTime.now()).
  void seed(String uid, List<Note> notes) {
    _notes[uid] = List<Note>.from(notes);
    _emit(uid);
  }

  /// The notes stored for [uid], sorted newest first — for assertions.
  List<Note> notesFor(String uid) => List<Note>.unmodifiable(_sorted(uid));

  @override
  Stream<List<Note>> watchNotes(String uid) {
    final controller = _streams.putIfAbsent(
      uid,
      () => StreamController<List<Note>>(sync: true),
    );
    controller.onListen = () => controller.add(_sorted(uid));
    return controller.stream;
  }

  @override
  Future<Note> createNote(
    String uid, {
    required String title,
    required String body,
  }) async {
    final now = DateTime.now().toUtc();
    final id = 'note-${_all(uid).length + 1}';
    final note = Note(id: id, title: title, body: body, updatedAt: now);
    _notes[uid] = [..._all(uid), note];
    _emit(uid);
    return note;
  }

  @override
  Future<void> updateNote(
    String uid,
    String noteId, {
    required String title,
    required String body,
  }) async {
    final now = DateTime.now().toUtc();
    _notes[uid] = _all(uid)
        .map((n) =>
            n.id == noteId ? n.copyWith(title: title, body: body, updatedAt: now) : n)
        .toList();
    _emit(uid);
  }

  @override
  Future<void> deleteNote(String uid, String noteId) async {
    _notes[uid] = _all(uid).where((n) => n.id != noteId).toList();
    _emit(uid);
  }
}

/// A [NotesRepository] whose every call fails — drives the NotesView error
/// state.
class ThrowingNotesRepository implements NotesRepository {
  @override
  Stream<List<Note>> watchNotes(String uid) {
    return Stream.error(StateError('permission-denied'));
  }

  @override
  Future<Note> createNote(
    String uid, {
    required String title,
    required String body,
  }) {
    return Future.error(StateError('permission-denied'));
  }

  @override
  Future<void> updateNote(
    String uid,
    String noteId, {
    required String title,
    required String body,
  }) {
    return Future.error(StateError('permission-denied'));
  }

  @override
  Future<void> deleteNote(String uid, String noteId) {
    return Future.error(StateError('permission-denied'));
  }
}
