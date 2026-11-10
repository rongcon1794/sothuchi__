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
    final effectiveServerId = (serverClientId?.trim().isNotEmpty ?? false)
        ? serverClientId!.trim()
        : defaultServerClientId;
    final clientId = defaultTargetPlatform == TargetPlatform.iOS
        ? defaultIosClientId
        : null;
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: effectiveServerId,
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
      final desc = e.description?.trim();
      final isGenuineUserCancel = e.code == GoogleSignInExceptionCode.canceled &&
          (desc == null ||
              desc.isEmpty ||
              desc.toLowerCase().contains('user cancelled') ||
              desc.toLowerCase().contains('activity is cancelled'));

      if (isGenuineUserCancel) {
        throw AuthCancelledException(desc ?? 'Google sign-in canceled');
      }
      throw AuthFailedException(
        desc?.isNotEmpty == true
            ? desc!
            : '${e.code.name}: Google authentication error',
      );
    } catch (e) {
      throw AuthFailedException(e.toString());
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

