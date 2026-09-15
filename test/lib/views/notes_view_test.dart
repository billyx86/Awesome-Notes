import 'package:awesomenotes/models/note.dart';
import 'package:awesomenotes/repositories/notes_repository.dart';
import 'package:awesomenotes/views/notes_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/notes_repositories.dart';

Widget _app(NotesRepository repository) {
  return MaterialApp(
    home: NotesView(repository: repository, authUid: 'test-user'),
  );
}

Note _note(String id, String title, String body, DateTime updatedAt) =>
    Note(id: id, title: title, body: body, updatedAt: updatedAt);

void main() {
  group('NotesView', () {
    testWidgets('shows the empty state when the user has no notes',
        (tester) async {
      final repo = InMemoryNotesRepository();

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
      expect(find.byKey(const Key('notes-list')), findsNothing);
    });

    testWidgets('lists notes newest first', (tester) async {
      final repo = InMemoryNotesRepository();
      final older = DateTime.utc(2026, 1, 1);
      final newer = DateTime.utc(2026, 2, 1);
      // Seeded out of order to prove the sort, not insertion order.
      repo.seed('test-user', [
        _note('n-old', 'Old note', 'first', older),
        _note('n-new', 'New note', 'second', newer),
      ]);

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      final texts = find
          .descendant(
            of: find.byKey(const Key('notes-list')),
            matching: find.byType(Text),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .toList();
      expect(texts.indexOf('New note'), lessThan(texts.indexOf('Old note')));
    });

    testWidgets('adding a note from the FAB puts it in the list',
        (tester) async {
      final repo = InMemoryNotesRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note-title')), 'Groceries');
      await tester.enterText(
        find.byKey(const Key('note-body')),
        'milk, eggs, bread',
      );
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(repo.notesFor('test-user'), hasLength(1));
      expect(repo.notesFor('test-user').single.title, 'Groceries');
    });

    testWidgets('saving a blank title rejects the note and shows an error',
        (tester) async {
      final repo = InMemoryNotesRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note-body')), 'no title');
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();

      expect(repo.notesFor('test-user'), isEmpty);
      expect(find.textContaining('Please give the note a title.'),
          findsOneWidget);
      expect(find.byKey(const Key('dismiss-error')), findsOneWidget);
    });

    testWidgets('cancelling the editor discards the draft', (tester) async {
      final repo = InMemoryNotesRepository();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-note')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note-title')), 'Draft');
      await tester.tap(find.byKey(const Key('cancel-note')));
      await tester.pumpAndSettle();

      expect(repo.notesFor('test-user'), isEmpty);
      expect(find.text('No notes yet. Tap + to add one.'), findsOneWidget);
    });

    testWidgets('editing a note updates the list', (tester) async {
      final repo = InMemoryNotesRepository();
      repo.seed('test-user', [
        _note('n1', 'Old title', 'old body', DateTime.utc(2026, 1, 1)),
      ]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-n1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('note-title')), 'New title');
      await tester.enterText(find.byKey(const Key('note-body')), 'new body');
      await tester.tap(find.byKey(const Key('save-note')));
      await tester.pumpAndSettle();

      expect(find.text('New title'), findsOneWidget);
      expect(find.text('New title').last, findsOneWidget);
      expect(find.textContaining('old body'), findsNothing);
      final note = repo.notesFor('test-user').single;
      expect(note.title, 'New title');
      expect(note.body, 'new body');
    });

    testWidgets('swipe-to-delete confirms, then removes the note',
        (tester) async {
      final repo = InMemoryNotesRepository();
      repo.seed('test-user', [
        _note('n1', 'Keep me', '', DateTime.utc(2026, 1, 1)),
        _note('n2', 'Delete me', '', DateTime.utc(2026, 2, 1)),
      ]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester
          .drag(find.byKey(const Key('dismissible-0-n2')), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // The confirmation dialog appears — nothing is deleted yet.
      expect(find.text('Delete note'), findsOneWidget);
      expect(repo.notesFor('test-user'), hasLength(2));

      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete me'), findsNothing);
      expect(repo.notesFor('test-user'), hasLength(1));
      expect(repo.notesFor('test-user').single.id, 'n1');
    });

    testWidgets('cancelling the delete dialog keeps the note', (tester) async {
      final repo = InMemoryNotesRepository();
      repo.seed('test-user', [
        _note('n1', 'Keep me', '', DateTime.utc(2026, 1, 1)),
      ]);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      await tester
          .drag(find.byKey(const Key('dismissible-0-n1')), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel-delete')));
      await tester.pumpAndSettle();

      expect(repo.notesFor('test-user'), hasLength(1));
      expect(find.text('Keep me'), findsOneWidget);
    });

    testWidgets('a repository error renders the error state', (tester) async {
      await tester.pumpWidget(_app(ThrowingNotesRepository()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dismiss-error')), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsOneWidget);
    });
  });
}
