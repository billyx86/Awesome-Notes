import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesomenotes/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    test('toMap/fromMap round-trips every field', () {
      final updatedAt = DateTime(2026, 9, 14, 9, 30);
      final original = Note(
        id: 'n1',
        title: 'Hello',
        body: 'World',
        updatedAt: updatedAt,
      );

      final restored = Note.fromMap('n1', original.toMap());

      // The id comes from the document key, not the map.
      expect(restored.id, 'n1');
      expect(restored.title, 'Hello');
      expect(restored.body, 'World');
      expect(restored.updatedAt, updatedAt);
    });

    test('an empty body round-trips (title-only notes are allowed)', () {
      final note = Note(
        id: 'n2',
        title: 'Just a title',
        body: '',
        updatedAt: DateTime(2026, 9, 14),
      );

      final restored = Note.fromMap('n2', note.toMap());

      expect(restored.body, isEmpty);
      expect(restored.title, 'Just a title');
    });

    test('toMap stores updatedAt as a Firestore Timestamp', () {
      final note = Note(
        id: 'n3',
        title: 't',
        body: 'b',
        updatedAt: DateTime(2026, 9, 14, 12),
      );

      final map = note.toMap();

      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['updatedAt'].toDate(), DateTime(2026, 9, 14, 12));
    });

    test('fromMap rejects a missing title', () {
      expect(
        () => Note.fromMap('n4', {'body': 'x', 'updatedAt': _ts()}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap rejects an empty title', () {
      expect(
        () => Note.fromMap(
          'n5',
          {'title': '', 'body': 'x', 'updatedAt': _ts()},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap rejects a missing body', () {
      expect(
        () => Note.fromMap(
          'n6',
          {'title': 't', 'updatedAt': _ts()},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromMap rejects a missing updatedAt', () {
      expect(
        () => Note.fromMap('n7', {'title': 't', 'body': 'b'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('copyWith replaces only the given fields', () {
      final note = Note(
        id: 'n8',
        title: 'old title',
        body: 'old body',
        updatedAt: DateTime(2026, 9, 1),
      );

      final updated = DateTime(2026, 9, 2);
      final edited = note.copyWith(body: 'new body', updatedAt: updated);

      expect(edited.id, 'n8');
      expect(edited.title, 'old title');
      expect(edited.body, 'new body');
      expect(edited.updatedAt, updated);
      // The original is unchanged.
      expect(note.body, 'old body');
      expect(note.updatedAt, DateTime(2026, 9, 1));
    });
  });
}

Timestamp _ts() => Timestamp.fromDate(DateTime(2026, 9, 14, 8, 0));
