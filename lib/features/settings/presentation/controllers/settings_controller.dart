import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/data/services/biometric_service.dart';
import 'package:so_thu_chi/data/services/csv_export_service.dart';
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
    }
    return res;
  }

  Future<Result<void>> updateLocale(String localeCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final normalized = localeCode.toLowerCase().startsWith('en') ? 'en' : 'vi';
    final res = await repo.setLocaleCode(normalized);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(localeCode: normalized));
      await ref
          .read(authRepositoryProvider)
          .updateProfilePreferences(locale: normalized);
    }
    return res;
  }

  Future<Result<void>> updateCurrency(String currencyCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setCurrencyCode(currencyCode);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(currencyCode: currencyCode));
      await ref
          .read(authRepositoryProvider)
          .updateProfilePreferences(defaultCurrency: currencyCode);
    }
    return res;
  }

  Future<Result<void>> toggleHideBalance() async {
    final next = !currentOrDefaults.hideBalance;
    final repo = ref.read(settingsRepositoryProvider);
    final res = await repo.setHideBalance(next);
    if (res.isSuccess) {
      state = AsyncData(currentOrDefaults.copyWith(hideBalance: next));
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
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );
