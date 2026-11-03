/// Metadata for supported ISO 4217 currencies.
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.decimalDigits,
    required this.nameVi,
    required this.nameEn,
    required this.symbolAtEnd,
  });

  final String code;
  final String symbol;
  final int decimalDigits;
  final String nameVi;
  final String nameEn;
  final bool symbolAtEnd;

  int get minorUnitFactor {
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    return factor;
  }
}

/// Registry of selectable currencies, defaulting to Vietnamese Dong (VND).
abstract final class AppCurrencies {
  static const String defaultCode = 'VND';

  static const CurrencyInfo vnd = CurrencyInfo(
    code: 'VND',
    symbol: '₫',
    decimalDigits: 0,
    nameVi: 'Đồng Việt Nam (VND)',
    nameEn: 'Vietnamese Dong (VND)',
    symbolAtEnd: true,
  );

  static const CurrencyInfo usd = CurrencyInfo(
    code: 'USD',
    symbol: r'$',
    decimalDigits: 2,
    nameVi: 'Đô la Mỹ (USD)',
    nameEn: 'US Dollar (USD)',
    symbolAtEnd: false,
  );

  static const CurrencyInfo eur = CurrencyInfo(
    code: 'EUR',
    symbol: '€',
    decimalDigits: 2,
    nameVi: 'Euro (EUR)',
    nameEn: 'Euro (EUR)',
    symbolAtEnd: false,
  );

  static const CurrencyInfo jpy = CurrencyInfo(
    code: 'JPY',
    symbol: '¥',
    decimalDigits: 0,
    nameVi: 'Yên Nhật (JPY)',
    nameEn: 'Japanese Yen (JPY)',
    symbolAtEnd: false,
  );

  static const CurrencyInfo krw = CurrencyInfo(
    code: 'KRW',
    symbol: '₩',
    decimalDigits: 0,
    nameVi: 'Won Hàn Quốc (KRW)',
    nameEn: 'South Korean Won (KRW)',
    symbolAtEnd: false,
  );

  static const List<CurrencyInfo> supported = [vnd, usd, eur, jpy, krw];

  static CurrencyInfo byCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final item in supported) {
      if (item.code == normalized) {
        return item;
      }
    }
    return vnd;
  }
}

