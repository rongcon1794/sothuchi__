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

  /// Default Web Client ID (OAuth client_type 3) configured in Firebase project `sochitieu-2dca6`.
  /// Required by CredentialManager on Android and Firebase Auth to obtain an OpenID Connect `idToken`.
  static const String defaultServerClientId =
      '835896714104-gft5f5vbotbn063a16pkga9ail9g6s5m.apps.googleusercontent.com';

  /// Default iOS Client ID from `GoogleService-Info.plist`.
  static const String defaultIosClientId =
      '835896714104-vegeqvb0vndjekrn0uepumanakce7oq6.apps.googleusercontent.com';

  final String? serverClientId;
  static bool _globalInitialized = false;
  static Future<void>? _globalInitFuture;

  /// Visible for testing to reset state between tests.
  @visibleForTesting
  static void resetGlobalInitializationState() {
    _globalInitialized = false;
    _globalInitFuture = null;
  }

  @override
  Future<void> ensureInitialized() async {
    if (_globalInitialized || kIsWeb) {
      return;
    }
    try {
      await (_globalInitFuture ??= _doInitialize());
    } catch (e) {
      _globalInitFuture = null;
      rethrow;
    }
  }

  Future<void> _doInitialize() async {
    final effectiveServerId = (serverClientId?.trim().isNotEmpty ?? false)
        ? serverClientId!.trim()
        : defaultServerClientId;
    final clientId = defaultTargetPlatform == TargetPlatform.iOS
        ? defaultIosClientId
        : null;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: effectiveServerId,
      );
    } on UnimplementedError {
      // In flutter_test headless environments without native platform runner
    }
    _globalInitialized = true;
  }

  @override
  Future<GoogleAuthTokens> authenticateInteractive() async {
    await ensureInitialized();
    try {
      final account = await _authenticateWithRetry();
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
      final desc = e.description?.trim();
      throw AuthFailedException(
        desc?.isNotEmpty == true
            ? desc!
            : '${e.code.name}: Google authentication error',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthFailedException(e.toString());
    }
  }

  Future<GoogleSignInAccount> _authenticateWithRetry() async {
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        rethrow;
      }
      // If Android CredentialManager or activity was in transition on cold start,
      // retry once after a short delay before surfacing an error to the user.
      if (e.code == GoogleSignInExceptionCode.uiUnavailable ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        return await GoogleSignIn.instance.authenticate();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb) return;
    try {
      await ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {
    if (kIsWeb) return;
    try {
      await ensureInitialized();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}

final googleSignInClientProvider = Provider<GoogleSignInClient>((ref) {
  const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  return GoogleSignInV7Client(
    serverClientId: serverClientId.trim().isNotEmpty
        ? serverClientId
        : GoogleSignInV7Client.defaultServerClientId,
  );
});

