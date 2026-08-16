const loginRoute = '/login/';
const registerRoute = '/register/';
const notesRoute = '/notes/';

/// The email-verification screen. It has no route in the original app —
/// HomePage only ever renders VerifyEmailView directly — which is why the
/// register flow had nowhere to send a freshly-created (unverified) user.
/// This constant + its entry in the routes map fix that.
const verifyEmailRoute = '/verify-email/';
