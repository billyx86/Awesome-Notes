import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/utilities/auth_validation.dart';
import 'package:awesomenotes/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    // Catch empty fields client-side before paying for a Firebase round-trip.
    final invalid = validateAuthFields(email, password);
    if (invalid != null) {
      await showErrorDialog(context, invalid);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // The user may have left this view (e.g. tapped "Create an account")
      // while the sign-in was in flight; don't use a dead context.
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(notesRoute, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        await showErrorDialog(context, 'Incorrect email or password');
      } else if (e.code == 'wrong-password') {
        await showErrorDialog(context, 'Incorrect credentials');
      } else if (e.code == 'invalid-email') {
        await showErrorDialog(context, 'Invalid email address');
      } else {
        await showErrorDialog(context, 'Unexpected error: ${e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter your email here',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Enter your password here',
            ),
          ),
          TextButton(
            onPressed: _submit,
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false);
            },
            child: const Text('Not registered yet? Create an account'),
          ),
        ],
      ),
    );
  }
}
