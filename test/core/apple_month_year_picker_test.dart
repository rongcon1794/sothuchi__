import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:so_thu_chi/features/reports/presentation/controllers/reports_controller.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/reports_screen.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

Widget _buildTestApp({required Widget child, Size size = const Size(390, 844)}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('en')],
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });

  group('AppleMonthYearPickerSheet & AppleCompactMonthSwitcher Unit and Widget Tests', () {
    testWidgets('AppleMonthYearPickerSheet displays 12 months, year navigation, and handles month picking', (tester) async {
      DateTime? pickedMonth;
      final initial = DateTime(2026, 5, 1);

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppleMonthYearPickerSheet.show(
                    context,
                    initialMonth: initial,
                    allowAllOption: true,
                    onMonthSelected: (m) => pickedMonth = m,
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open picker sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify sheet title & year
      expect(find.text('Chọn thời gian'), findsOneWidget);
      expect(find.text('Năm 2026'), findsOneWidget);
      expect(find.text('Toàn thời gian'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);

      // Verify months in grid: Tháng 1 .. Tháng 12
      expect(find.text('Tháng 1'), findsOneWidget);
      expect(find.text('Tháng 5'), findsOneWidget);
      expect(find.text('Tháng 12'), findsOneWidget);

      // Increment year
      final nextYearBtn = find.byTooltip('Năm sau');
      expect(nextYearBtn, findsOneWidget);
      await tester.tap(nextYearBtn);
      await tester.pumpAndSettle();
      expect(find.text('Năm 2027'), findsOneWidget);

      // Pick Tháng 8 (in year 2027)
      await tester.tap(find.text('Tháng 8'));
      await tester.pumpAndSettle();

      // Picker should dismiss and pickedMonth should be Aug 2027
      expect(pickedMonth, isNotNull);
      expect(pickedMonth?.year, 2027);
      expect(pickedMonth?.month, 8);
    });

    testWidgets('AppleMonthYearPickerSheet "Toàn thời gian" returns null and dismisses', (tester) async {
      DateTime? pickedMonth = DateTime(2026, 11, 1);

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppleMonthYearPickerSheet.show(
                    context,
                    initialMonth: pickedMonth,
                    allowAllOption: true,
                    onMonthSelected: (m) => pickedMonth = m,
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Tap "Toàn thời gian"
      await tester.tap(find.text('Toàn thời gian'));
      await tester.pumpAndSettle();

      // Should return null
      expect(pickedMonth, isNull);
    });

    testWidgets('TransactionsScreen portrait month switcher taps open month picker sheet and updates provider', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi'), Locale('en')],
            home: TransactionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify compact month switcher is present
      expect(find.byType(AppleCompactMonthSwitcher), findsOneWidget);

      // Tap on the switcher's month label capsule (find calendar icon or month text)
      final calendarIconFinder = find.byIcon(CupertinoIcons.calendar);
      expect(calendarIconFinder, findsOneWidget);
      await tester.tap(calendarIconFinder);
      await tester.pumpAndSettle();

      // Month picker sheet should now be open
      expect(find.byType(AppleMonthYearPickerSheet), findsOneWidget);

      // Tap Tháng 3
      await tester.tap(find.text('Tháng 3'));
      await tester.pumpAndSettle();

      // Sheet should be closed
      expect(find.byType(AppleMonthYearPickerSheet), findsNothing);

      // Verify selectedTransactionMonthProvider was updated to month 3
      final selectedMonth = container.read(selectedTransactionMonthProvider);
      expect(selectedMonth, isNotNull);
      expect(selectedMonth?.month, 3);
    });

    testWidgets('BudgetsScreen portrait month switcher taps open month picker sheet and updates provider', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi'), Locale('en')],
            home: BudgetsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppleCompactMonthSwitcher), findsOneWidget);

      final calendarIconFinder = find.byIcon(CupertinoIcons.calendar);
      expect(calendarIconFinder, findsOneWidget);
      await tester.tap(calendarIconFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppleMonthYearPickerSheet), findsOneWidget);

      // Tap Tháng 9
      await tester.tap(find.text('Tháng 9'));
      await tester.pumpAndSettle();

      expect(find.byType(AppleMonthYearPickerSheet), findsNothing);
      final selectedMonth = container.read(selectedBudgetMonthProvider);
      expect(selectedMonth.month, 9);
    });

    testWidgets('ReportsScreen landscape month switcher in AppBar taps open month picker sheet and updates provider', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi'), Locale('en')],
            home: MediaQuery(
              data: MediaQueryData(size: Size(844, 390)),
              child: ReportsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In landscape, month switcher is in AppBar actions
      expect(find.byType(AppleCompactMonthSwitcher), findsOneWidget);

      // Tapping on the month text inside AppBar actions opens the sheet
      final monthTextFinder = find.descendant(
        of: find.byType(AppleCompactMonthSwitcher),
        matching: find.byType(Text),
      );
      expect(monthTextFinder, findsOneWidget);
      await tester.tap(monthTextFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppleMonthYearPickerSheet), findsOneWidget);

      // Tap Tháng 4
      await tester.tap(find.text('Tháng 4'));
      await tester.pumpAndSettle();

      expect(find.byType(AppleMonthYearPickerSheet), findsNothing);
      final selectedMonth = container.read(selectedReportMonthProvider);
      expect(selectedMonth.month, 4);
    });
  });
}
