import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/app.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/services/sync_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final firebaseState = await bootstrapFirebase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseBootstrapStateProvider.overrideWithValue(firebaseState),
        syncStatusServiceProvider.overrideWith(
          (ref) => ref.watch(firestoreSyncStatusServiceProvider),
        ),
      ],
      child: const SoThuChiApp(),
    ),
  );
}
