import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
    await initializeDateFormatting('en');
  });

  group('AppDateUtils', () {
    test('computes month boundaries accurately across leap and standard months', () {
      final febLeap = DateTime(2024, 2, 15, 14, 30);
      expect(AppDateUtils.startOfMonth(febLeap), DateTime(2024, 2, 1));
      expect(
        AppDateUtils.endOfMonth(febLeap),
        DateTime(2024, 2, 29, 23, 59, 59, 999),
      );
    });

    test('formats Today, Yesterday, and Month headers in Vietnamese', () {
      final anchor = DateTime(2026, 11, 3, 18, 0);
      expect(
        AppDateUtils.formatDayHeader(
          anchor,
          locale: 'vi',
          todayLabel: 'Hôm nay',
          yesterdayLabel: 'Hôm qua',
          nowOverride: anchor,
        ),
        'Hôm nay • 03/11/2026',
      );
      expect(
        AppDateUtils.formatDayHeader(
          DateTime(2026, 11, 2, 9, 0),
          locale: 'vi',
          todayLabel: 'Hôm nay',
          yesterdayLabel: 'Hôm qua',
          nowOverride: anchor,
        ),
        'Hôm qua • 02/11/2026',
      );
      expect(
        AppDateUtils.formatMonthYear(anchor, locale: 'vi'),
        'Tháng 11, 2026',
      );
    });

    test('formats compact transaction tile date for Today, Yesterday, and other dates', () {
      final now = DateTime(2026, 11, 8, 14, 0);
      final todayTx = DateTime(2026, 11, 8, 9, 30);
      final yesterdayTx = DateTime(2026, 11, 7, 20, 15);
      final olderTxThisYear = DateTime(2026, 11, 2, 8, 0);
      final lastYearTx = DateTime(2025, 12, 25, 12, 0);

      expect(
        AppDateUtils.formatTransactionTileDate(todayTx, locale: 'vi', nowOverride: now),
        'Hôm nay, 08/11',
      );
      expect(
        AppDateUtils.formatTransactionTileDate(yesterdayTx, locale: 'vi', nowOverride: now),
        'Hôm qua, 07/11',
      );
      expect(
        AppDateUtils.formatTransactionTileDate(olderTxThisYear, locale: 'vi', nowOverride: now),
        '02/11/2026',
      );
      expect(
        AppDateUtils.formatTransactionTileDate(lastYearTx, locale: 'vi', nowOverride: now),
        '25/12/2025',
      );

      // English locale
      expect(
        AppDateUtils.formatTransactionTileDate(todayTx, locale: 'en', nowOverride: now),
        'Today, 08/11',
      );
      expect(
        AppDateUtils.formatTransactionTileDate(yesterdayTx, locale: 'en', nowOverride: now),
        'Yesterday, 07/11',
      );
    });
  });
}

