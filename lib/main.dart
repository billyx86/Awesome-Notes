import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/views/login_view.dart';
import 'package:awesomenotes/views/register_view.dart';
import 'package:awesomenotes/views/verify_email_view.dart';
import 'package:awesomenotes/firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase exactly once, before the app is built. Doing this
  // in HomePage.build() (the previous behavior) re-ran on every rebuild of
  // the FutureBuilder and threw once Firebase had already been initialized.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        notesRoute: (context) => const NotesView(),
        // VerifyEmailView was reachable only via HomePage; the register
        // flow had no named route to send a freshly-created (unverified)
        // user to, so they were left stranded on the register screen.
        verifyEmailRoute: (context) => const VerifyEmailView(),
      },
    )
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase is initialized in main() before runApp(), so we can read the
    // persisted auth state synchronously — no more FutureBuilder wrapping
    // the app entry point (and no more re-initialization on rebuild).
    //
    // The auth views handle their own navigation on sign-in / sign-out, so
    // this deliberately reads the state once per build rather than
    // subscribing to authStateChanges (a stream here would double-navigate
    // with the views).
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginView();
    }
    return user.emailVerified ? const NotesView() : const VerifyEmailView();
  }
}

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
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
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login/', 
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
          )
        ],
      ),
      body: const Text('Hello World'),
    );
  }
}

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