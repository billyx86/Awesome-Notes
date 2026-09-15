import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/models/note.dart';
import 'package:awesomenotes/repositories/notes_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// The app's home screen for signed-in, verified users.
///
/// Lists the user's notes (newest first) with an "Add note" button and
/// per-note edit / swipe-to-delete actions.
///
/// Both [repository] and [authUid] are injectable so widget tests can pump
/// the view with an in-memory fake and a fixed uid — no Firebase SDK and
/// no auth state required. Production builds use the defaults: the
/// [FirestoreNotesRepository] and the signed-in user's uid.
class NotesView extends StatefulWidget {
  /// Not `const` because the default [repository] is a non-const
  /// expression. Tests construct it plainly with an in-memory fake.
  NotesView({
    super.key,
    NotesRepository? repository,
    this.authUid,
  }) : repository = repository ?? FirestoreNotesRepository();

  final NotesRepository repository;

  /// The uid the notes are scoped to. Null = resolve from the signed-in
  /// user (production path).
  final String? authUid;

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  _NotesMode _mode = _NotesMode.view;

  String _editingId = '';
  String _editTitle = '';
  String _editBody = '';

  /// A failed CRUD operation. Null while everything is working; rendered as
  /// an error state in the body (view mode only).
  Object? _error;

  /// Bumped after a cancelled delete so the swiped-off [Dismissible] is
  /// recreated (its key changes) and the row snaps back into view. Without
  /// this, cancelling leaves the note hidden until the next snapshot.
  int _generation = 0;

  bool get _busy => _mode == _NotesMode.editing;

  String get _uid =>
      widget.authUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    // The user is signed out; send them straight to login,
                    // discarding the whole stack so the back button can't
                    // re-enter the app.
                    //
                    // Uses the loginRoute constant instead of the literal
                    // '/login/' so the string lives in one place.
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (_) => false,
                    );
                  }
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Log out'),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-note'),
        tooltip: 'Add note',
        onPressed: _busy
            ? null
            : () => setState(() {
                _mode = _NotesMode.editing;
                _editingId = '';
                _editTitle = '';
                _editBody = '';
              }),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_mode == _NotesMode.editing) {
      return _EditorSheet(
        initialTitle: _editTitle,
        initialBody: _editBody,
        isNew: _editingId.isEmpty,
        onSave: _save,
        onCancel: () => setState(() => _mode = _NotesMode.view),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message: _error.toString(),
        onDismiss: () => setState(() => _error = null),
      );
    }

    return StreamBuilder<List<Note>>(
      stream: widget.repository.watchNotes(_uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onDismiss: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = snapshot.data ?? const <Note>[];
        if (notes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No notes yet. Tap + to add one.'),
            ),
          );
        }
        return ListView.builder(
          key: const Key('notes-list'),
          itemCount: notes.length,
          itemBuilder: (context, index) => _buildTile(notes[index]),
        );
      },
    );
  }

  Widget _buildTile(Note note) {
    return Dismissible(
      key: Key('dismissible-$_generation-${note.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _confirmDelete(note),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete),
      ),
      child: ListTile(
        key: Key('note-${note.id}'),
        title: Text(note.title),
        subtitle: note.body.isEmpty ? null : Text(note.body),
        trailing: IconButton(
          key: Key('edit-${note.id}'),
          tooltip: 'Edit',
          icon: const Icon(Icons.edit),
          onPressed: _busy
              ? null
              : () => setState(() {
                  _mode = _NotesMode.editing;
                  _editingId = note.id;
                  _editTitle = note.title;
                  _editBody = note.body;
                }),
        ),
      ),
    );
  }

  /// Swipe-to-delete is easy to do by accident, so a dialog backs it up.
  Future<void> _confirmDelete(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note'),
        content: Text('"${note.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            key: const Key('cancel-delete'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      // Cancelled: the row is still swiped off-screen. Changing the
      // Dismissible key forces it to rebuild at its home position.
      setState(() {
        _generation++;
      });
      return;
    }
    try {
      await widget.repository.deleteNote(_uid, note.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    }
  }

  Future<void> _save(String title, String body) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      setState(() {
        _mode = _NotesMode.view;
        _error = 'Please give the note a title.';
      });
      return;
    }
    try {
      if (_editingId.isEmpty) {
        await widget.repository.createNote(
          _uid,
          title: trimmedTitle,
          body: body,
        );
      } else {
        await widget.repository.updateNote(
          _uid,
          _editingId,
          title: trimmedTitle,
          body: body,
        );
      }
      if (!mounted) return;
      setState(() {
        _mode = _NotesMode.view;
        _editingId = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mode = _NotesMode.view;
        _error = e;
      });
    }
  }
}

enum _NotesMode { view, editing }

enum MenuAction { logout }

Future<bool> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Log out'),
          ),
        ],
      );
    }
  ).then((value) => value ?? false);
}

class _EditorSheet extends StatefulWidget {
  const _EditorSheet({
    required this.initialTitle,
    required this.initialBody,
    required this.isNew,
    required this.onSave,
    required this.onCancel,
  });

  final String initialTitle;
  final String initialBody;
  final bool isNew;
  final Future<void> Function(String title, String body) onSave;
  final void Function() onCancel;

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _body = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isNew ? 'New note' : 'Edit note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('note-title'),
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Note title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                key: const Key('note-body'),
                controller: _body,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  hintText: 'Write something…',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('cancel-note'),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('save-note'),
                  onPressed: () => widget.onSave(_title.text, _body.text),
                  child: Text(
                    widget.isNew ? 'Add note' : 'Save changes',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onDismiss});

  final String message;
  final void Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Something went wrong.\n$message'),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('dismiss-error'),
              onPressed: onDismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
