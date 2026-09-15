import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';

/// Data access for one signed-in user's notes.
///
/// The Firestore-backed [FirestoreNotesRepository] scopes every document
/// under `users/{uid}/notes`, matching the security rules in
/// `firestore.rules`: the uid comes from the signed-in user, never from a
/// client-supplied path segment, and the rules deny access to any document
/// whose uid does not match the auth identity.
///
/// The [NotesRepository] interface exists so the UI (and its tests) can be
/// exercised with an in-memory fake — no Firebase SDK, no network.
abstract class NotesRepository {
  /// A live view of the user's notes, sorted by `updatedAt` newest first.
  Stream<List<Note>> watchNotes(String uid);

  /// Create a note and return it with its assigned id.
  Future<Note> createNote(
    String uid, {
    required String title,
    required String body,
  });

  /// Overwrite a note's title and body, bumping its `updatedAt` so the
  /// edited note rises to the top of the list.
  Future<void> updateNote(
    String uid,
    String noteId, {
    required String title,
    required String body,
  });

  /// Delete a note by id.
  Future<void> deleteNote(String uid, String noteId);
}

/// The production [NotesRepository], backed by Cloud Firestore.
///
/// Document layout (one document per note):
///
/// ```
/// users/{uid}/notes/{noteId}
///   title:     string   (non-empty)
///   body:      string   (may be empty)
///   updatedAt: Timestamp (set by the client; bumped on every edit)
/// ```
///
/// A single-field `orderBy('updatedAt')` needs no composite index.
class FirestoreNotesRepository implements NotesRepository {
  FirestoreNotesRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  @override
  Stream<List<Note>> watchNotes(String uid) {
    return _collection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromMap(doc.id, doc.data()))
            .toList(growable: false));
  }

  @override
  Future<Note> createNote(
    String uid, {
    required String title,
    required String body,
  }) async {
    final updatedAt = DateTime.now().toUtc();
    final ref = await _collection(uid).add(
      Note(id: '', title: title, body: body, updatedAt: updatedAt).toMap(),
    );
    return Note(id: ref.id, title: title, body: body, updatedAt: updatedAt);
  }

  @override
  Future<void> updateNote(
    String uid,
    String noteId, {
    required String title,
    required String body,
  }) {
    final updatedAt = DateTime.now().toUtc();
    return _collection(uid).doc(noteId).set({
      'title': title,
      'body': body,
      'updatedAt': Timestamp.fromDate(updatedAt),
    });
  }

  @override
  Future<void> deleteNote(String uid, String noteId) {
    return _collection(uid).doc(noteId).delete();
  }
}
