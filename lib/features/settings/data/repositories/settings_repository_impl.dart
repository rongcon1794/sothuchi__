import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';
import 'package:so_thu_chi/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.prefs,
    required this.secureStorage,
  });

  static const String _keyThemeMode = 'settings.theme_mode';
  static const String _keyLocale = 'settings.locale_code';
  static const String _keyCurrency = 'settings.currency_code';
  static const String _keyHideBalance = 'settings.hide_balance';
  static const String _keyOnboardingDone = 'settings.onboarding_completed';
  static const String _keyBiometricLock = 'settings.biometric_lock_enabled';

  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;

  @override
  Future<AppSettings> loadSettings() async {
    final themeRaw = prefs.getString(_keyThemeMode);
    final themeMode = switch (themeRaw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final localeCode = prefs.getString(_keyLocale) ?? 'vi';
    final currencyCode = AppCurrencies.byCode(
      prefs.getString(_keyCurrency) ?? AppCurrencies.defaultCode,
    ).code;
    final hideBalance = prefs.getBool(_keyHideBalance) ?? false;
    final onboardingCompleted = prefs.getBool(_keyOnboardingDone) ?? false;

    var biometricEnabled = false;
    try {
      final rawBio = await secureStorage.read(key: _keyBiometricLock);
      biometricEnabled = rawBio == 'true';
    } catch (_) {
      biometricEnabled = false;
    }

    return AppSettings(
      themeMode: themeMode,
      localeCode: localeCode,
      currencyCode: currencyCode,
      biometricLockEnabled: biometricEnabled,
      hideBalance: hideBalance,
      onboardingCompleted: onboardingCompleted,
    );
  }

  @override
  Future<Result<void>> setThemeMode(ThemeMode mode) async {
    try {
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_keyThemeMode, value);
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setLocaleCode(String localeCode) async {
    try {
      final normalized = localeCode.toLowerCase().startsWith('en')
          ? 'en'
          : 'vi';
      await prefs.setString(_keyLocale, normalized);
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setCurrencyCode(String currencyCode) async {
    try {
      final valid = AppCurrencies.byCode(currencyCode).code;
      await prefs.setString(_keyCurrency, valid);
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setBiometricLockEnabled(bool enabled) async {
    try {
      await secureStorage.write(
        key: _keyBiometricLock,
        value: enabled ? 'true' : 'false',
      );
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setHideBalance(bool hidden) async {
    try {
      await prefs.setBool(_keyHideBalance, hidden);
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setOnboardingCompleted(bool completed) async {
    try {
      await prefs.setBool(_keyOnboardingDone, completed);
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }
}
