import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/utilities/auth_validation.dart';
import 'package:awesomenotes/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // The user may have left this view (e.g. tapped "Log in") while the
      // registration was in flight; don't use a dead context.
      if (!mounted) return;
      // A newly-created user is unverified; land on the verify-email screen.
      Navigator.of(context)
          .pushNamedAndRemoveUntil(verifyEmailRoute, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'weak-password') {
        await showErrorDialog(
          context,
          'Your password must be 6 or more characters.',
        );
      } else if (e.code == 'email-already-in-use') {
        await showErrorDialog(context, 'Specified email is already in use.');
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
      appBar: AppBar(title: const Text('Register')),
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
              helperText: 'Must be 6 or more characters',
            ),
          ),
          TextButton(
            onPressed: _submit,
            child: const Text('Register'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false);
            },
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
