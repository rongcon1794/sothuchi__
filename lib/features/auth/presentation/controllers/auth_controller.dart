import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';

export 'package:so_thu_chi/data/providers/repository_providers.dart'
    show authStateStreamProvider, currentUserProvider;

/// Action controller for Google Sign-In, Sign-Out, and Account Deletion.
class AuthActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  bool get isCloudAuthConfigured =>
      ref.read(authRepositoryProvider).isCloudAuthConfigured;

  Future<Result<AppUser>> signInWithGoogle() async {
    state = const AsyncLoading();
    final res = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (err) => AsyncError(err, StackTrace.current),
    );
    return res;
  }

  Future<Result<AppUser>> signInOfflineDemo() async {
    state = const AsyncLoading();
    final res = await ref.read(authRepositoryProvider).signInOfflineDemo();
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (err) => AsyncError(err, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> signOut() async {
    state = const AsyncLoading();
    final res = await ref.read(authRepositoryProvider).signOut();
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (err) => AsyncError(err, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> deleteAccountAndAllData() async {
    state = const AsyncLoading();
    final res = await ref
        .read(authRepositoryProvider)
        .deleteAccountAndAllData();
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (err) => AsyncError(err, StackTrace.current),
    );
    return res;
  }
}

final authActionControllerProvider =
    NotifierProvider<AuthActionController, AsyncValue<void>>(
      AuthActionController.new,
    );

