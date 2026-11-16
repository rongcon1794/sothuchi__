import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/auth/data/datasources/google_sign_in_client.dart';
import 'package:so_thu_chi/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/login_screen.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class FakeGoogleSignInPlatform extends GoogleSignInPlatform
    with MockPlatformInterfaceMixin {
  int initCalls = 0;

  @override
  Future<void> init(InitParameters params) async {
    initCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoogleSignInClient implements GoogleSignInClient {
  int ensureInitializedCalls = 0;
  int authenticateCalls = 0;
  GoogleAuthTokens? tokensToReturn;
  Exception? exceptionToThrow;

  @override
  Future<void> ensureInitialized() async {
    ensureInitializedCalls++;
  }

  @override
  Future<GoogleAuthTokens> authenticateInteractive() async {
    authenticateCalls++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return tokensToReturn ??
        const GoogleAuthTokens(
          id: 'test_google_id',
          email: 'test@example.com',
          displayName: 'Test User',
          idToken: 'mock_jwt_id_token',
        );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> disconnect() async {}
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.cloudConfigured = true});

  final bool cloudConfigured;
  final StreamController<AppUser?> _ctrl = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  bool get isCloudAuthConfigured => cloudConfigured;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _user;
    yield* _ctrl.stream;
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    final now = DateTime(2026, 11, 16);
    final user = AppUser(
      uid: 'test_uid',
      email: 'test@example.com',
      createdAt: now,
      updatedAt: now,
    );
    _user = user;
    _ctrl.add(user);
    return Success(user);
  }

  @override
  Future<Result<AppUser>> signInOfflineDemo() => signInWithGoogle();

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _ctrl.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccountAndAllData() async => const Success(null);

  @override
  Future<Result<void>> updateProfilePreferences({
    String? defaultCurrency,
    String? locale,
    String? themeMode,
    int? accentColorIndex,
    String? defaultWalletId,
    bool? oledMode,
    bool? hideBalance,
    bool? initialSetupCompleted,
  }) async => const Success(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleSignInV7Client & Initialization Resilience', () {
    late FakeGoogleSignInPlatform fakePlatform;

    setUp(() {
      GoogleSignInV7Client.resetGlobalInitializationState();
      fakePlatform = FakeGoogleSignInPlatform();
      GoogleSignInPlatform.instance = fakePlatform;
    });

    test('ensureInitialized succeeds and skips redundant initialization on repeated calls', () async {
      final client1 = GoogleSignInV7Client();
      await client1.ensureInitialized();
      expect(fakePlatform.initCalls, equals(1));

      // Second client or second call should not re-run init because of global cache
      final client2 = GoogleSignInV7Client();
      await client2.ensureInitialized();
      expect(fakePlatform.initCalls, equals(1));
    });
  });

  group('FirebaseAuthRepository Bootstrap Resilience', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('signInOfflineDemo succeeds even if onUserSignedIn bootstrap throws error', () async {
      var bootstrapCalled = false;
      final repo = FirebaseAuthRepository(
        firebaseAuth: null,
        firestore: null,
        googleSignInClient: MockGoogleSignInClient(),
        prefs: prefs,
        onUserSignedIn: (user) async {
          bootstrapCalled = true;
          throw Exception('Simulated network timeout during category bootstrap');
        },
      );

      final result = await repo.signInOfflineDemo();

      expect(bootstrapCalled, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.isDemoUser, isTrue);
      expect(repo.currentUser?.isDemoUser, isTrue);
    });

    test('Multiple concurrent sign-in attempts are safely blocked by in-flight lock', () async {
      final mockGoogle = MockGoogleSignInClient();
      final repo = FirebaseAuthRepository(
        firebaseAuth: null,
        firestore: null,
        googleSignInClient: mockGoogle,
        prefs: prefs,
      );

      final future1 = repo.signInWithGoogle();
      final future2 = repo.signInWithGoogle();

      final results = await Future.wait([future1, future2]);

      expect(results.any((r) => r.isFailure), isTrue);
    });
  });

  group('LoginScreen Google Sign-In Warm-up', () {
    testWidgets('LoginScreen pre-warms GoogleSignInClient on initial mount', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const secureStorage = FlutterSecureStorage();
      final mockGoogle = MockGoogleSignInClient();
      final fakeAuth = FakeAuthRepository();
      final catRepo = InMemoryCategoryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageProvider.overrideWithValue(secureStorage),
            settingsRepositoryProvider.overrideWithValue(
              SettingsRepositoryImpl(prefs: prefs, secureStorage: secureStorage),
            ),
            authRepositoryProvider.overrideWithValue(fakeAuth),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            googleSignInClientProvider.overrideWithValue(mockGoogle),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(mockGoogle.ensureInitializedCalls, greaterThanOrEqualTo(1));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
