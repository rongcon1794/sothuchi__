import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  bool get isCloudAuthConfigured;
  Stream<AppUser?> watchAuthState();
  AppUser? get currentUser;
  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInOfflineDemo();
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccountAndAllData();
  Future<Result<void>> updateProfilePreferences({
    String? defaultCurrency,
    String? locale,
  });
}
