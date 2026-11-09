import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/auth/data/datasources/google_sign_in_client.dart';
import 'package:so_thu_chi/features/auth/data/models/user_profile_dto.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/auth/domain/repositories/auth_repository.dart';

/// Optional hook invoked right after a user signs in so default categories
/// and initial wallet can be seeded idempotently.
typedef UserBootstrapCallback = Future<void> Function(AppUser user);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignInClient,
    required this.prefs,
    this.onUserSignedIn,
    this.onDemoDataCleared,
  }) {
    _initSession();
  }

  static const String _demoSessionKey = 'auth.demo_session_active';

  final FirebaseAuth? firebaseAuth;
  final FirebaseFirestore? firestore;
  final GoogleSignInClient googleSignInClient;
  final SharedPreferences prefs;
  final UserBootstrapCallback? onUserSignedIn;
  final Future<void> Function()? onDemoDataCleared;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  StreamSubscription<User?>? _firebaseSub;
  AppUser? _currentUser;

  void _initSession() {
    final auth = firebaseAuth;
    if (auth != null) {
      final existing = auth.currentUser;
      if (existing != null) {
        _currentUser = _mapFirebaseUser(existing);
      }
      _firebaseSub = auth.authStateChanges().listen((fbUser) async {
        if (fbUser == null) {
          if (!(_currentUser?.isDemoUser ?? false)) {
            _emit(null);
          }
          return;
        }

        // Fast-path: When resuming after idle/sleep, Firebase Auth triggers a token refresh
        // for the active user. If the UID is identical, do NOT re-emit or re-run user bootstrapping
        // (which causes massive UI freeze from redundant full collection scans).
        final isSameUser = _currentUser != null &&
            !_currentUser!.isDemoUser &&
            _currentUser!.uid == fbUser.uid;

        if (isSameUser) {
          unawaited(_ensureUserProfileDocument(fbUser));
          return;
        }

        // Fast initial emission so UI doesn't freeze waiting for network
        final initialUser = _mapFirebaseUser(fbUser);
        _emit(initialUser);

        final synced = await _ensureUserProfileDocument(fbUser);
        if (_currentUser?.uid == synced.uid) {
          _emit(synced);
        }
        if (onUserSignedIn != null) {
          unawaited(onUserSignedIn!(synced));
        }
      });
    } else if (prefs.getBool(_demoSessionKey) ?? false) {
      final demo = _buildDemoUser();
      _currentUser = demo;
      if (onUserSignedIn != null) {
        unawaited(onUserSignedIn!(demo));
      }
    }
  }

  void _emit(AppUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  @override
  bool get isCloudAuthConfigured => firebaseAuth != null;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    final auth = firebaseAuth;
    if (auth == null) {
      return const Failure(
        AuthFailedException(
          'Firebase is not configured yet. Run flutterfire configure first.',
        ),
      );
    }

    try {
      UserCredential credential;
      if (kIsWeb) {
        credential = await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final tokens = await googleSignInClient.authenticateInteractive();
        if (tokens.idToken == null || tokens.idToken!.isEmpty) {
          return const Failure(
            AuthFailedException('Missing Google ID token from credential.'),
          );
        }
        final oauthCred = GoogleAuthProvider.credential(
          idToken: tokens.idToken,
        );
        credential = await auth.signInWithCredential(oauthCred);
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        return const Failure(
          AuthFailedException('Firebase returned null user after Google auth.'),
        );
      }

      final appUser = await _ensureUserProfileDocument(fbUser);
      await prefs.setBool(_demoSessionKey, false);
      _emit(appUser);
      if (onUserSignedIn != null) {
        await onUserSignedIn!(appUser);
      }
      return Success(appUser);
    } on AppException catch (e) {
      return Failure(e);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        return Failure(NetworkException(e.message ?? e.code));
      }
      return Failure(AuthFailedException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(AuthFailedException(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signInOfflineDemo() async {
    try {
      await prefs.setBool(_demoSessionKey, true);
      final demo = _buildDemoUser();
      _emit(demo);
      if (onUserSignedIn != null) {
        await onUserSignedIn!(demo);
      }
      return Success(demo);
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await prefs.setBool(_demoSessionKey, false);
      await googleSignInClient.signOut();
      if (firebaseAuth != null) {
        await firebaseAuth!.signOut();
      }
      _emit(null);
      return const Success(null);
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteAccountAndAllData() async {
    final active = _currentUser;
    if (active == null) {
      return const Success(null);
    }

    try {
      if (active.isDemoUser) {
        await prefs.setBool(_demoSessionKey, false);
        if (onDemoDataCleared != null) {
          await onDemoDataCleared!();
        }
        _emit(null);
        return const Success(null);
      }

      final db = firestore;
      final auth = firebaseAuth;
      if (db != null) {
        await _purgeAllUserDocuments(db, active.uid);
      }

      final fbUser = auth?.currentUser;
      if (fbUser != null) {
        try {
          await fbUser.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login' && !kIsWeb) {
            final tokens = await googleSignInClient.authenticateInteractive();
            final reauthCred = GoogleAuthProvider.credential(
              idToken: tokens.idToken,
            );
            await fbUser.reauthenticateWithCredential(reauthCred);
            await fbUser.delete();
          } else {
            rethrow;
          }
        }
      }

      await googleSignInClient.disconnect();
      _emit(null);
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Failure(PermissionDeniedException(e.message ?? e.code));
      }
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateProfilePreferences({
    String? defaultCurrency,
    String? locale,
  }) async {
    final user = _currentUser;
    if (user == null) return const Success(null);

    final updated = user.copyWith(
      defaultCurrency: defaultCurrency ?? user.defaultCurrency,
      locale: locale ?? user.locale,
      updatedAt: DateTime.now(),
    );
    _emit(updated);

    if (user.isDemoUser || firestore == null) {
      return const Success(null);
    }

    try {
      await firestore!.collection('users').doc(user.uid).set({
        'defaultCurrency': ?defaultCurrency,
        'locale': ?locale,
        'updatedAt': Timestamp.fromDate(updated.updatedAt),
      }, SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  Future<AppUser> _ensureUserProfileDocument(User fbUser) async {
    final now = DateTime.now();
    final fallback = _mapFirebaseUser(fbUser, now: now);
    final db = firestore;
    if (db == null) return fallback;

    try {
      final docRef = db.collection('users').doc(fbUser.uid);
      DocumentSnapshot<Map<String, dynamic>>? snapshot;

      // 1. Try local cache first for sub-millisecond response on resume
      try {
        snapshot = await docRef
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 300));
      } catch (_) {
        // Cache miss or test environment
      }

      // 2. Fallback to server with a tight timeout to prevent app hanging indefinitely
      if (snapshot == null || !snapshot.exists || snapshot.data() == null) {
        try {
          snapshot = await docRef
              .get()
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          return fallback;
        }
      }

      if (snapshot.exists && snapshot.data() != null) {
        final existingDto = UserProfileDto.fromJson({
          ...snapshot.data()!,
          'uid': fbUser.uid,
        });
        final refreshed = existingDto.copyWith(
          email: fbUser.email ?? existingDto.email,
          displayName: fbUser.displayName ?? existingDto.displayName,
          photoUrl: fbUser.photoURL ?? existingDto.photoUrl,
          updatedAt: now,
          deletedAt: null,
        );
        unawaited(
          docRef
              .set(refreshed.toJson(), SetOptions(merge: true))
              .catchError((_) {}),
        );
        return refreshed.toDomain();
      }

      final dto = UserProfileDto(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName,
        photoUrl: fbUser.photoURL,
        defaultCurrency: AppCurrencies.defaultCode,
        locale: 'vi',
        createdAt: now,
        updatedAt: now,
      );
      unawaited(
        docRef.set(dto.toJson()).catchError((_) {}),
      );
      return dto.toDomain();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _purgeAllUserDocuments(
    FirebaseFirestore db,
    String uid,
  ) async {
    final userRef = db.collection('users').doc(uid);
    const subcollections = [
      'transactions',
      'budgets',
      'accounts',
      'categories',
      'debts',
      'recurring',
      'savings_goals',
      'ledgers',
    ];

    for (final name in subcollections) {
      final snap = await userRef.collection(name).get();
      final docs = snap.docs;
      for (var i = 0; i < docs.length; i += 400) {
        final batch = db.batch();
        final end = (i + 400 < docs.length) ? i + 400 : docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }
    }

    await userRef.delete();
  }

  AppUser _mapFirebaseUser(User fbUser, {DateTime? now}) {
    final ts = now ?? DateTime.now();
    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName,
      photoUrl: fbUser.photoURL,
      createdAt: fbUser.metadata.creationTime ?? ts,
      updatedAt: ts,
    );
  }

  AppUser _buildDemoUser() {
    final now = DateTime.now();
    return AppUser(
      uid: 'local_demo_user',
      email: 'demo@sothuchi.vn',
      displayName: 'Người dùng Demo',
      defaultCurrency: AppCurrencies.defaultCode,
      locale: 'vi',
      isDemoUser: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  void dispose() {
    unawaited(_firebaseSub?.cancel());
    unawaited(_controller.close());
  }
}