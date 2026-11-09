import 'package:flutter/widgets.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('vi'));

  /// Formats currency with current locale & mask support
  String formatMoney(
    int minorUnits, {
    String currencyCode = 'VND',
    String locale = 'vi',
  }) {
    return Money(minorUnits: minorUnits, currencyCode: currencyCode)
        .format(locale: locale);
  }

  /// Formats date to dd/MM/yyyy
  String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  /// Formats month and year header
  String formatMonthYear(DateTime date, {String locale = 'vi'}) {
    return AppDateUtils.formatMonthYear(date, locale: locale);
  }

  /// Localizes default category name
  String localizeCategory({
    required String categoryId,
    required String fallbackName,
  }) {
    return DefaultCategoryLocalization.resolveName(
      l10n,
      categoryId: categoryId,
      fallbackName: fallbackName,
    );
  }

  String localizeError(Object error) {
    final l = l10n;
    return switch (error) {
      NetworkException() => l.errorNetwork,
      AuthCancelledException() => l.errorAuthCancelled,
      AuthFailedException(:final debugMessage) =>
        debugMessage.isNotEmpty && debugMessage != 'Authentication failed'
            ? '${l.errorAuthFailed}: $debugMessage'
            : l.errorAuthFailed,
      PermissionDeniedException(:final debugMessage) =>
        debugMessage.isNotEmpty ? debugMessage : l.errorPermissionDenied,
      ValidationException(:final debugMessage) =>
        debugMessage.isNotEmpty ? debugMessage : l.errorValidation,
      StorageException(:final debugMessage) =>
        debugMessage.isNotEmpty ? debugMessage : l.errorGeneric,
      NotFoundException(:final debugMessage) =>
        debugMessage.isNotEmpty ? debugMessage : l.errorGeneric,
      _ => l.errorGeneric,
    };
  }
}

/// Resolves default seeded category keys to localized display names when switching vi/en.
abstract final class DefaultCategoryLocalization {
  static String resolveName(
    AppLocalizations l10n, {
    required String categoryId,
    required String fallbackName,
  }) {
    return switch (categoryId) {
      'default_food' => l10n.catFood,
      'default_transport' => l10n.catTransport,
      'default_housing' => l10n.catHousing,
      'default_bills' => l10n.catBills,
      'default_shopping' => l10n.catShopping,
      'default_entertainment' => l10n.catEntertainment,
      'default_health' => l10n.catHealth,
      'default_education' => l10n.catEducation,
      'default_other_expense' => l10n.catOtherExpense,
      'default_salary' => l10n.catSalary,
      'default_bonus' => l10n.catBonus,
      'default_investment' => l10n.catInvestment,
      'default_other_income' => l10n.catOtherIncome,
      _ => fallbackName,
    };
  }
}

