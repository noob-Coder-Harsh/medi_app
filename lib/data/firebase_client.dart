import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/env.dart';

/// Firebase for customer phone OTP only. Staff stays on Supabase.
abstract final class AppFirebase {
  static bool _initialized = false;

  static bool get isReady => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    if (!Env.hasFirebase) {
      debugPrint(
        'Firebase skipped: set FIREBASE_API_KEY, FIREBASE_APP_ID, '
        'FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID.',
      );
      return;
    }
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: Env.firebaseApiKey,
        appId: Env.firebaseAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        authDomain: Env.firebaseAuthDomain.isEmpty
            ? null
            : Env.firebaseAuthDomain,
        storageBucket: Env.firebaseStorageBucket.isEmpty
            ? null
            : Env.firebaseStorageBucket,
      ),
    );
    _initialized = true;
  }
}
