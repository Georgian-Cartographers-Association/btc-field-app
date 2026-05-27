// ════════════════════════════════════════════════════════════════════════════
// Generated / updated manually.
// Android section will be filled after running:
//   flutterfire configure --project=gca-btk-field-app
// ════════════════════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for this platform. '
            'Run: flutterfire configure --project=gca-btk-field-app');
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCmHZpaB60kGcMRqEzT6fqD4GxGpO01UJo',
    appId: '1:699141416460:web:274e0c5e564e8a4890f029',
    messagingSenderId: '699141416460',
    projectId: 'gca-btk-field-app',
    authDomain: 'gca-btk-field-app.firebaseapp.com',
    storageBucket: 'gca-btk-field-app.firebasestorage.app',
    measurementId: 'G-G15W816JJ5',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  // TODO: Add Android app in Firebase Console (package: ge.cartographers.btk_field_app)
  //       then run:  flutterfire configure --project=gca-btk-field-app
  //       OR download google-services.json → android/app/ and fill values below.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '699141416460',
    projectId: 'gca-btk-field-app',
    storageBucket: 'gca-btk-field-app.firebasestorage.app',
  );
}
