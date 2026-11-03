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
  });
}

