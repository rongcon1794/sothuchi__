import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/utils/money.dart';

void main() {
  group('Money (integer minor units, zero double usage)', () {
    test('formats VND in Vietnamese and English locales without decimals', () {
      const m = Money(minorUnits: 1250000);
      expect(m.format(locale: 'vi'), '1.250.000 ₫');
      expect(m.format(locale: 'en'), '1,250,000 ₫');
      expect(m.format(locale: 'vi', showPlusSign: true), '+1.250.000 ₫');
      expect(m.format(locale: 'vi', showMinusSign: true), '-1.250.000 ₫');
      expect((-m).format(locale: 'vi'), '-1.250.000 ₫');
      expect(const Money.zero().format(locale: 'vi', showMinusSign: true), '0 ₫');
      expect(m.format(masked: true), '•••••• ₫');
    });

    test('formats USD with 2 decimal digits accurately', () {
      const usd = Money(minorUnits: 1250, currencyCode: 'USD');
      expect(usd.format(locale: 'en'), r'$12.50');
      expect(usd.format(locale: 'vi'), r'$12,50');
    });

    test('parses formatted VND and USD strings into exact minor units', () {
      expect(
        Money.tryParse('1.250.000', currencyCode: 'VND'),
        const Money(minorUnits: 1250000),
      );
      expect(
        Money.tryParse('50,000 ₫', currencyCode: 'VND'),
        const Money(minorUnits: 50000),
      );
      expect(
        Money.tryParse('19.99', currencyCode: 'USD'),
        const Money(minorUnits: 1999, currencyCode: 'USD'),
      );
      expect(
        Money.tryParse('1,234.5', currencyCode: 'USD'),
        const Money(minorUnits: 123450, currencyCode: 'USD'),
      );
      expect(Money.tryParse('   '), isNull);
    });

    test('performs exact arithmetic and rejects currency mismatch', () {
      const a = Money(minorUnits: 500000);
      const b = Money(minorUnits: 150000);
      expect(a + b, const Money(minorUnits: 650000));
      expect(a - b, const Money(minorUnits: 350000));

      const usd = Money(minorUnits: 100, currencyCode: 'USD');
      expect(() => a + usd, throwsArgumentError);
    });

    test('MoneyInputFormatter formats live thousand separators and decimal currencies across locales', () {
      final vndFormatter = MoneyInputFormatter(currencyCode: 'VND', locale: 'vi');
      final formattedVnd = vndFormatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1250000'),
      );
      expect(formattedVnd.text, '1.250.000');

      const usdOriginal = Money(minorUnits: 123456, currencyCode: 'USD');
      final viInput = usdOriginal.toInputString(locale: 'vi');
      expect(viInput, '1.234,56');
      final usdViFormatter = MoneyInputFormatter(
        currencyCode: 'USD',
        locale: 'vi',
      );
      final viFormatted = usdViFormatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: viInput),
      );
      expect(viFormatted.text, '1.234,56');
      expect(
        Money.tryParse(viFormatted.text, currencyCode: 'USD'),
        usdOriginal,
      );

      final enInput = usdOriginal.toInputString(locale: 'en');
      expect(enInput, '1,234.56');
      final usdEnFormatter = MoneyInputFormatter(
        currencyCode: 'USD',
        locale: 'en',
      );
      final enFormatted = usdEnFormatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: enInput),
      );
      expect(enFormatted.text, '1,234.56');
      expect(
        Money.tryParse(enFormatted.text, currencyCode: 'USD'),
        usdOriginal,
      );
    });
  });
}

