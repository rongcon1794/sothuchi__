import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/firebase_options.dart';

/// Describes whether Firebase was initialized with valid platform configuration.
class FirebaseBootstrapState {
  const FirebaseBootstrapState({
    required this.isConfigured,
    this.reason,
  });

  const FirebaseBootstrapState.configured()
    : isConfigured = true,
      reason = null;

  const FirebaseBootstrapState.unconfigured([this.reason])
    : isConfigured = false;

  final bool isConfigured;
  final String? reason;
}

/// Initializes Firebase safely and enables Firestore offline persistence.
Future<FirebaseBootstrapState> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // 100 MB cache limit to prevent unbounded SQLite bloat & freeze
    );
    return const FirebaseBootstrapState.configured();
  } catch (error) {
    return FirebaseBootstrapState.unconfigured(error.toString());
  }
}

final firebaseBootstrapStateProvider = Provider<FirebaseBootstrapState>((ref) {
  return const FirebaseBootstrapState.unconfigured('Not initialized');
});

final firebaseAppProvider = Provider<FirebaseApp?>((ref) {
  final state = ref.watch(firebaseBootstrapStateProvider);
  if (!state.isConfigured || Firebase.apps.isEmpty) return null;
  return Firebase.app();
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  final app = ref.watch(firebaseAppProvider);
  if (app == null) return null;
  return FirebaseAuth.instanceFor(app: app);
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  final app = ref.watch(firebaseAppProvider);
  if (app == null) return null;
  return FirebaseFirestore.instanceFor(app: app);
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  );
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

