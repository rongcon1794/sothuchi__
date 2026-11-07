import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> loadSettings();
  Future<Result<void>> setThemeMode(ThemeMode mode);
  Future<Result<void>> setLocaleCode(String localeCode);
  Future<Result<void>> setCurrencyCode(String currencyCode);
  Future<Result<void>> setBiometricLockEnabled(bool enabled);
  Future<Result<void>> setHideBalance(bool hidden);
  Future<Result<void>> setOnboardingCompleted(bool completed);
  Future<Result<void>> setInitialSetupCompleted(bool completed, {String? uid});
  Future<Result<void>> setDefaultWalletId(String? walletId);
  Future<Result<void>> setAccentColorIndex(int index);
}

