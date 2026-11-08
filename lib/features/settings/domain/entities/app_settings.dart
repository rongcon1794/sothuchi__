import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('vi') String localeCode,
    @Default(AppCurrencies.defaultCode) String currencyCode,
    @Default(false) bool biometricLockEnabled,
    @Default(false) bool hideBalance,
    @Default(false) bool onboardingCompleted,
    @Default(false) bool initialSetupCompleted,
    String? defaultWalletId,
    @Default(0) int accentColorIndex,
    @Default(false) bool oledMode,
  }) = _AppSettings;
}

