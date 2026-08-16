// Regression tests for the app's routing and the committed placeholder
// Firebase options.
//
// (This file used to be the Flutter template counter test, which referenced
// a MyApp class that was never in this codebase — it has never compiled,
// so `flutter test` always failed on a fresh clone. See the PR that
// replaces it.)

import 'package:awesomenotes/constants/routes.dart';
import 'package:awesomenotes/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routes', () {
    test('every route is a distinct, absolute path', () {
      final all = {loginRoute, registerRoute, notesRoute, verifyEmailRoute};
      expect(all.length, 4, reason: 'routes must be distinct');
      for (final route in all) {
        expect(route, startsWith('/'), reason: 'route $route must be absolute');
      }
    });
  });

  group('DefaultFirebaseOptions (placeholder)', () {
    test('resolves to well-formed, clearly-placeholder options', () {
      final options = DefaultFirebaseOptions.currentPlatform;
      // Non-empty so the app at least links against a valid shape.
      expect(options.projectId, isNotEmpty);
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      // The committed placeholders must stay recognizably fake so nobody
      // ships them by accident.
      expect(options.projectId, contains('placeholder'));
      expect(options.apiKey, contains('PLACEHOLDER'));
    });
  });
}
