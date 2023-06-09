import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/utilities/show_error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'dart:developer' as devtools show log;

import '../firebase_options.dart';

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
            decoration: const InputDecoration(
              hintText: 'Enter your email here',
            ),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'Enter your password here',
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
    
              try {
                final userCredential = 
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email, 
                  password: password
                );
                devtools.log(userCredential.toString());
              } on FirebaseAuthException catch (e) {
                if (e.code == 'weak-password') {
                  await showErrorDialog(context, 'Your password must be 6 or more characters.');
                } else if (e.code == 'email-already-in-use') {
                  await showErrorDialog(context, 'Specified email is already in use.');
                } else if (e.code == 'invalid-email') {
                  await showErrorDialog(context, 'Invalid email has been specified.');
                } else {
                  await showErrorDialog(
                    context, 
                    'Unexpected error: ${e.code}'
                  );
                }
              } catch (e) {
                await showErrorDialog(context, e.toString());
              }
            }, 
            child: const Text('Register'),
          ),
          TextButton(
            onPressed:() {
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false);
            }, 
            child: const Text('Already have an account? Log in')),
        ],
      ),
    );
  }
}
