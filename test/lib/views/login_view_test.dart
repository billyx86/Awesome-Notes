import 'package:awesomenotes/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('submitting empty login fields shows a validation dialog',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    // Both fields are empty. (The AppBar title is also "Login", so target
    // the submit button specifically.)
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    // The validation dialog is shown instead of a Firebase round-trip.
    expect(find.text('An error occurred'), findsOneWidget);
    // The dialog content mentions the email; the field's hint does too, so
    // assert the exact dialog copy rather than a substring search.
    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('login form renders email and password fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginView()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      find.text('Enter your email here'),
      findsOneWidget,
    );
    expect(
      find.text('Enter your password here'),
      findsOneWidget,
    );
    expect(find.text('Not registered yet? Create an account'), findsOneWidget);
  });
}
