import 'package:cloud_firestore/cloud_firestore.dart';

/// A single user note, mirrored to a document in the owner's private
/// `users/{uid}/notes` collection in Cloud Firestore.
///
/// [fromMap]/[toMap] are the only places that touch the Firestore wire
/// shape (the `updatedAt` field is a [Timestamp] on the server, a
/// [DateTime] here), so the rest of the app and the test suite can build
/// and compare notes without initializing the Firebase SDK.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  /// The Firestore document id. Notes being created have an empty [id]
  /// until the repository assigns one.
  final String id;

  /// Short summary line, always shown in the list.
  final String title;

  /// Full note text. May be empty for a title-only note.
  final String body;

  /// Last save time. The list is sorted by this, newest first.
  final DateTime updatedAt;

  /// Rebuild a [Note] from a Firestore document map.
  ///
  /// Throws [FormatException] when a required field is missing or has the
  /// wrong type, so a corrupted document fails loudly instead of rendering
  /// garbage in the UI.
  factory Note.fromMap(String id, Map<String, dynamic> map) {
    final title = map['title'];
    final body = map['body'];
    final updatedAt = map['updatedAt'];
    if (title is! String || title.isEmpty) {
      throw FormatException('note $id is missing a non-empty "title"');
    }
    if (body is! String) {
      throw FormatException('note $id is missing a "body" string');
    }
    if (updatedAt is! Timestamp) {
      throw FormatException(
        'note $id is missing an "updatedAt" Timestamp',
      );
    }
    return Note(
      id: id,
      title: title,
      body: body,
      updatedAt: updatedAt.toDate(),
    );
  }

  /// The Firestore document map for this note. The document id is not
  /// part of the map — it is the key the repository writes under.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Return a copy of this note with the given fields replaced.
  Note copyWith({String? title, String? body, DateTime? updatedAt}) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note($id, "$title", "${body.isEmpty ? 'no body' : 'has body'}", '
        '$updatedAt)';
  }
}
