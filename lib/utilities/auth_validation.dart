/// Returns a user-facing message if the given auth form fields are not yet
/// submittable, or `null` if they look sane enough to send to Firebase.
///
/// Firebase enforces the real rules server-side (email format, password
/// strength, account state); this only catches the obviously-empty cases
/// early and trims the email, so the user gets immediate feedback instead
/// of a round-trip to the backend and trailing whitespace from copy-paste
/// does not trigger a spurious `user-not-found`.
String? validateAuthFields(String email, String password) {
  if (email.trim().isEmpty) {
    return 'Please enter your email address.';
  }
  if (password.isEmpty) {
    return 'Please enter your password.';
  }
  return null;
}
