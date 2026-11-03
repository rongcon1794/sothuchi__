import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';

/// Immutable monetary value stored strictly in integer minor units.
///
/// Never uses `double` for storage, parsing, or arithmetic.
/// Examples:
/// - `Money(minorUnits: 1250000, currencyCode: 'VND')` -> `1.250.000 ₫`
/// - `Money(minorUnits: 1250, currencyCode: 'USD')` -> `$12.50`
class Money implements Comparable<Money> {
  const Money({
    required this.minorUnits,
    this.currencyCode = AppCurrencies.defaultCode,
  });

  const Money.zero([this.currencyCode = AppCurrencies.defaultCode])
    : minorUnits = 0;

  final int minorUnits;
  final String currencyCode;

  CurrencyInfo get currency => AppCurrencies.byCode(currencyCode);

  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;
  bool get isNegative => minorUnits < 0;

  Money abs() => Money(minorUnits: minorUnits.abs(), currencyCode: currencyCode);

  Money operator -() =>
      Money(minorUnits: -minorUnits, currencyCode: currencyCode);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(
      minorUnits: minorUnits - other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  void _assertSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError(
        'Cannot combine Money of different currencies: $currencyCode vs ${other.currencyCode}',
      );
    }
  }

  /// Parses user input into [Money] using pure integer arithmetic.
  ///
  /// For 0-decimal currencies (VND, JPY, KRW), strips all grouping punctuation
  /// and parses integer digits directly.
  /// For 2-decimal currencies (USD, EUR), accepts `.` or `,` as the decimal
  /// separator when followed by 1..2 fractional digits.
  static Money? tryParse(
    String rawInput, {
    String currencyCode = AppCurrencies.defaultCode,
  }) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;

    final info = AppCurrencies.byCode(currencyCode);
    final isNeg = trimmed.startsWith('-');
    final unsigned = isNeg ? trimmed.substring(1).trim() : trimmed;

    if (info.decimalDigits == 0) {
      final digitsOnly = unsigned.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) return null;
      final parsed = int.tryParse(digitsOnly);
      if (parsed == null) return null;
      return Money(
        minorUnits: isNeg ? -parsed : parsed,
        currencyCode: info.code,
      );
    }

    // Decimal currency (e.g. USD/EUR with 2 decimal digits).
    final cleaned = unsigned.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (cleaned.isEmpty) return null;

    final lastDot = cleaned.lastIndexOf('.');
    final lastComma = cleaned.lastIndexOf(',');
    final lastSep = lastDot > lastComma ? lastDot : lastComma;

    String majorDigits;
    var fractionDigits = '';

    if (lastSep >= 0 && cleaned.length - lastSep - 1 <= info.decimalDigits) {
      majorDigits = cleaned
          .substring(0, lastSep)
          .replaceAll(RegExp(r'[^0-9]'), '');
      fractionDigits = cleaned
          .substring(lastSep + 1)
          .replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      majorDigits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    }

    if (majorDigits.isEmpty && fractionDigits.isEmpty) return null;
    final major = majorDigits.isEmpty ? 0 : int.tryParse(majorDigits);
    if (major == null) return null;

    final paddedFraction = fractionDigits.padRight(info.decimalDigits, '0');
    final fraction = paddedFraction.isEmpty
        ? 0
        : int.tryParse(paddedFraction.substring(0, info.decimalDigits));
    if (fraction == null) return null;

    final totalMinor = major * info.minorUnitFactor + fraction;
    return Money(
      minorUnits: isNeg ? -totalMinor : totalMinor,
      currencyCode: info.code,
    );
  }

  /// Formats monetary value with exact integer grouping (e.g. `1.250.000 ₫` in `vi`).
  String format({
    String locale = 'vi',
    bool showPlusSign = false,
    bool masked = false,
  }) {
    final info = currency;
    if (masked) {
      return info.symbolAtEnd ? '•••••• ${info.symbol}' : '${info.symbol}••••••';
    }

    final isVi = locale.toLowerCase().startsWith('vi');
    final groupSep = isVi ? '.' : ',';
    final decimalSep = isVi ? ',' : '.';

    final absMinor = minorUnits.abs();
    String numberPart;

    if (info.decimalDigits == 0) {
      numberPart = groupInteger(absMinor, separator: groupSep);
    } else {
      final factor = info.minorUnitFactor;
      final major = absMinor ~/ factor;
      final rem = absMinor % factor;
      final majorGrouped = groupInteger(major, separator: groupSep);
      final fractionStr = rem.toString().padLeft(info.decimalDigits, '0');
      numberPart = '$majorGrouped$decimalSep$fractionStr';
    }

    final signPrefix = minorUnits < 0
        ? '-'
        : (showPlusSign && minorUnits > 0 ? '+' : '');

    if (info.symbolAtEnd) {
      return '$signPrefix$numberPart ${info.symbol}';
    }
    return '$signPrefix${info.symbol}$numberPart';
  }

  /// Formats only the plain input string without currency symbol for form fields.
  String toInputString({String locale = 'vi'}) {
    if (minorUnits == 0) return '';
    final info = currency;
    final isVi = locale.toLowerCase().startsWith('vi');
    final groupSep = isVi ? '.' : ',';
    final decimalSep = isVi ? ',' : '.';
    final absMinor = minorUnits.abs();

    if (info.decimalDigits == 0) {
      return groupInteger(absMinor, separator: groupSep);
    }
    final factor = info.minorUnitFactor;
    final major = absMinor ~/ factor;
    final rem = absMinor % factor;
    final majorGrouped = groupInteger(major, separator: groupSep);
    final fractionStr = rem.toString().padLeft(info.decimalDigits, '0');
    return '$majorGrouped$decimalSep$fractionStr';
  }

  /// Pure integer digit grouping (e.g. `1250000` -> `'1.250.000'`).
  static String groupInteger(int nonNegativeValue, {String separator = '.'}) {
    final raw = nonNegativeValue.abs().toString();
    if (raw.length <= 3) return raw;
    final buffer = StringBuffer();
    final firstGroupLen = raw.length % 3;
    if (firstGroupLen > 0) {
      buffer.write(raw.substring(0, firstGroupLen));
    }
    for (var i = firstGroupLen; i < raw.length; i += 3) {
      if (buffer.isNotEmpty) buffer.write(separator);
      buffer.write(raw.substring(i, i + 3));
    }
    return buffer.toString();
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.minorUnits == minorUnits &&
          other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}

/// Real-time thousand-separator input formatter for integer/decimal currencies.
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter({
    this.currencyCode = AppCurrencies.defaultCode,
    this.locale = 'vi',
  });

  final String currencyCode;
  final String locale;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final info = AppCurrencies.byCode(currencyCode);
    final isVi = locale.toLowerCase().startsWith('vi');
    final groupSep = isVi ? '.' : ',';

    if (info.decimalDigits == 0) {
      final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        return const TextEditingValue();
      }
      // Guard against overflow > 15 digits (quadrillions).
      final capped = digits.length > 15 ? digits.substring(0, 15) : digits;
      final value = int.tryParse(capped);
      if (value == null) return oldValue;
      final formatted = Money.groupInteger(value, separator: groupSep);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Decimal currencies (USD, EUR): locale-aware grouping and decimal separator.
    final decimalSep = isVi ? ',' : '.';
    var rawText = newValue.text;

    // Convenience for Vietnamese locale: if user presses '.' on a numeric keypad
    // at the end of input when no ',' is present yet, treat that trailing '.' as ','.
    if (isVi &&
        !rawText.contains(',') &&
        rawText.length == oldValue.text.length + 1 &&
        rawText.endsWith('.')) {
      rawText = '${rawText.substring(0, rawText.length - 1)},';
    }

    // Strip grouping separators first, then retain only digits and the active decimal separator.
    final withoutGroups = rawText.replaceAll(groupSep, '');
    final allowedPattern = isVi ? RegExp(r'[^0-9,]') : RegExp(r'[^0-9.]');
    final allowed = withoutGroups.replaceAll(allowedPattern, '');
    if (allowed.isEmpty) {
      return const TextEditingValue();
    }

    final parts = allowed.split(decimalSep);
    if (parts.length > 2) return oldValue;
    final majorRaw = parts[0].length > 12
        ? parts[0].substring(0, 12)
        : parts[0];
    final majorVal = majorRaw.isEmpty ? 0 : (int.tryParse(majorRaw) ?? 0);
    final majorFormatted = majorRaw.isEmpty
        ? ''
        : Money.groupInteger(majorVal, separator: groupSep);

    String result;
    if (parts.length == 2) {
      final frac = parts[1].length > info.decimalDigits
          ? parts[1].substring(0, info.decimalDigits)
          : parts[1];
      result =
          '${majorFormatted.isEmpty ? '0' : majorFormatted}$decimalSep$frac';
    } else {
      result = majorFormatted;
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

