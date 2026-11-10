import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/data/services/biometric_service.dart';
import 'package:so_thu_chi/data/services/csv_export_service.dart';
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(settingsRepositoryProvider).loadSettings();
  }

  AppSettings get currentOrDefaults => state.value ?? const AppSettings();

  Future<bool> isBiometricAvailable() {
    return ref.read(biometricServiceProvider).isAvailable();
  }

  Future<bool> authenticateBiometric({required String localizedReason}) {
    return ref
        .read(biometricServiceProvider)
        .authenticate(localizedReason: localizedReason);
  }

  Future<Result<int>> exportTransactionsCsv({required String subject}) async {
    final txs = await ref.read(transactionRepositoryProvider).getTransactions();
    final categoriesList = await ref
        .read(categoryRepositoryProvider)
        .getCategories();
    final accountsList = await ref
        .read(accountRepositoryProvider)
        .getAccounts(includeArchived: true);
    final categories = {for (final c in categoriesList) c.id: c};
    final accounts = {for (final a in accountsList) a.id: a};
    final locale = currentOrDefaults.localeCode;
    return ref
        .read(csvExportServiceProvider)
        .exportAndShareTransactions(
          transactions: txs,
          categoriesById: categories,
          accountsById: accounts,
          subject: subject,
          locale: locale,
        );
  }

  Future<Result<void>> updateThemeMode(ThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setThemeMode(mode);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(themeMode: mode));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          themeMode: mode.name,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> updateLocale(String localeCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final normalized = localeCode.toLowerCase().startsWith('en') ? 'en' : 'vi';
    final res = await repo.setLocaleCode(normalized);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(localeCode: normalized));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          locale: normalized,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> updateCurrency(String currencyCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setCurrencyCode(currencyCode);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(currencyCode: currencyCode));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          defaultCurrency: currencyCode,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> toggleHideBalance() async {
    final next = !currentOrDefaults.hideBalance;
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setHideBalance(next);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(hideBalance: next));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          hideBalance: next,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> updateBiometricLock(bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setBiometricLockEnabled(enabled);
    if (res.isSuccess) {
      state = AsyncData(
        currentOrDefaults.copyWith(biometricLockEnabled: enabled),
      );
    }
    return res;
  }

  Future<Result<void>> completeOnboarding() async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setOnboardingCompleted(true);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(onboardingCompleted: true));
    }
    return res;
  }

  Future<Result<void>> completeInitialSetup({String? uid}) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setInitialSetupCompleted(true, uid: uid);
    if (res.isSuccess) {
      state = AsyncData(
        currentOrDefaults.copyWith(initialSetupCompleted: true),
      );
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          initialSetupCompleted: true,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> resetInitialSetup({String? uid}) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setInitialSetupCompleted(false, uid: uid);
    await repo.setDefaultWalletId(null);
    if (res.isSuccess) {
      state = AsyncData(
        currentOrDefaults.copyWith(
          initialSetupCompleted: false,
          defaultWalletId: null,
        ),
      );
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          initialSetupCompleted: false,
          defaultWalletId: '',
        ),
      );
    }
    return res;
  }

  Future<Result<void>> setDefaultWalletId(String? walletId) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setDefaultWalletId(walletId);
    if (res.isSuccess) {
      state = AsyncData(
        currentOrDefaults.copyWith(defaultWalletId: walletId),
      );
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          defaultWalletId: walletId ?? '',
        ),
      );
    }
    return res;
  }

  Future<Result<void>> updateAccentColor(int index) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setAccentColorIndex(index);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(accentColorIndex: index));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          accentColorIndex: index,
        ),
      );
    }
    return res;
  }

  Future<Result<void>> updateOledMode(bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setOledMode(enabled);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(oledMode: enabled));
      unawaited(
        ref.read(authRepositoryProvider).updateProfilePreferences(
          oledMode: enabled,
        ),
      );
    }
    return res;
  }

  /// Restores user settings stored in Firestore cloud document when user signs in
  Future<void> restoreFromCloudUser(AppUser user) async {
    final repo = ref.read(settingsRepositoryProvider);

    // 1. Theme mode
    if (user.themeMode != null && user.themeMode!.isNotEmpty) {
      final theme = switch (user.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      await repo.setThemeMode(theme);
    }

    // 2. Locale
    if (user.locale.isNotEmpty) {
      await repo.setLocaleCode(user.locale);
    }

    // 3. Currency
    if (user.defaultCurrency.isNotEmpty) {
      await repo.setCurrencyCode(user.defaultCurrency);
    }

    // 4. Accent Color
    if (user.accentColorIndex != null) {
      await repo.setAccentColorIndex(user.accentColorIndex!);
    }

    // 5. Default Wallet
    if (user.defaultWalletId != null) {
      await repo.setDefaultWalletId(
        user.defaultWalletId!.isEmpty ? null : user.defaultWalletId,
      );
    }

    // 6. OLED Mode
    if (user.oledMode != null) {
      await repo.setOledMode(user.oledMode!);
    }

    // 7. Hide Balance
    if (user.hideBalance != null) {
      await repo.setHideBalance(user.hideBalance!);
    }

    // 8. Initial Setup Completed
    if (user.initialSetupCompleted != null) {
      await repo.setInitialSetupCompleted(
        user.initialSetupCompleted!,
        uid: user.uid,
      );
    }

    state = AsyncData(await repo.loadSettings());
  }

  /// Backs up all current local settings to the user's Firestore cloud document
  Future<void> backupToCloudUser() async {
    final current = currentOrDefaults;
    await ref.read(authRepositoryProvider).updateProfilePreferences(
      themeMode: current.themeMode.name,
      locale: current.localeCode,
      defaultCurrency: current.currencyCode,
      accentColorIndex: current.accentColorIndex,
      defaultWalletId: current.defaultWalletId ?? '',
      oledMode: current.oledMode,
      hideBalance: current.hideBalance,
      initialSetupCompleted: current.initialSetupCompleted,
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );
