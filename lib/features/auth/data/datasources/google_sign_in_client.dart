import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';

/// Authentication payload returned from Google Sign-In v7.
class GoogleAuthTokens {
  const GoogleAuthTokens({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
}

/// Testable wrapper over `google_sign_in` v7.x singleton API.
abstract interface class GoogleSignInClient {
  Future<void> ensureInitialized();
  Future<GoogleAuthTokens> authenticateInteractive();
  Future<void> signOut();
  Future<void> disconnect();
}

/// Production implementation strictly using `GoogleSignIn.instance` (v7.x API).
class GoogleSignInV7Client implements GoogleSignInClient {
  GoogleSignInV7Client({this.serverClientId});

  final String? serverClientId;
  bool _initialized = false;
  Future<void>? _initFuture;

  @override
  Future<void> ensureInitialized() {
    if (_initialized || kIsWeb) {
      return Future<void>.value();
    }
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    final trimmedServerId = (serverClientId?.trim().isEmpty ?? true)
        ? null
        : serverClientId!.trim();
    final clientId = defaultTargetPlatform == TargetPlatform.iOS
        ? '835896714104-vegeqvb0vndjekrn0uepumanakce7oq6.apps.googleusercontent.com'
        : null;
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: trimmedServerId,
    );
    _initialized = true;
  }

  @override
  Future<GoogleAuthTokens> authenticateInteractive() async {
    await ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      return GoogleAuthTokens(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: auth.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException(e.description ?? 'Google sign-in canceled');
      }
      throw AuthFailedException(
        '${e.code.name}: ${e.description ?? 'Google authentication error'}',
      );
    } catch (e) {
      throw AuthFailedException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb || !_initialized) return;
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> disconnect() async {
    if (kIsWeb || !_initialized) return;
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      await GoogleSignIn.instance.signOut();
    }
  }
}

final googleSignInClientProvider = Provider<GoogleSignInClient>((ref) {
  const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  return GoogleSignInV7Client(serverClientId: serverClientId);
});

