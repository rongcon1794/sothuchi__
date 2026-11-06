import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/lucian_live_kpi_card.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LucianTokens & Curves', () {
    test('resolves light and dark colors correctly', () {
      expect(LucianTokens.resolveAccent(false), LucianTokens.accentLight);
      expect(LucianTokens.resolveAccent(true), LucianTokens.accentDark);
      expect(LucianTokens.resolveMint(false), LucianTokens.mintLight);
      expect(LucianTokens.resolveMint(true), LucianTokens.mintDark);
      expect(LucianTokens.resolveDanger(false), LucianTokens.dangerLight);
      expect(LucianTokens.resolveDanger(true), LucianTokens.dangerDark);
      expect(LucianTokens.resolveWarn(false), LucianTokens.warnLight);
      expect(LucianTokens.resolveWarn(true), LucianTokens.warnDark);
    });

    test('motion curves are defined properly', () {
      expect(LucianTokens.ease, isA<Cubic>());
      expect(LucianTokens.spring, isA<Cubic>());
      expect(LucianTokens.digitRoll, isA<Cubic>());
    });
  });

  group('LucianHoldToDeleteButton Widget Tests', () {
    testWidgets('renders initial label and trash icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LucianHoldToDeleteButton(
                label: 'Giữ để xóa',
                onConfirmed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Giữ để xóa'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
    });

    testWidgets('cancels hold if released early before completion', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LucianHoldToDeleteButton(
                duration: const Duration(milliseconds: 600),
                onConfirmed: () => confirmed = true,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(LucianHoldToDeleteButton)));
      await tester.pump(const Duration(milliseconds: 200));

      // Release early at 200ms
      await gesture.up();
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets('holding for full duration triggers onConfirmed', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LucianHoldToDeleteButton(
                duration: const Duration(milliseconds: 400),
                holdingLabel: 'Giữ...',
                confirmedLabel: 'Đã xóa!',
                onConfirmed: () => confirmed = true,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(LucianHoldToDeleteButton)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Giữ...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Đã xóa!'), findsOneWidget);
      await gesture.up();
    });
  });

  group('LucianLiveKpiCard Widget Tests', () {
    testWidgets('renders balance amount, delta badge, and metric tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LucianLiveKpiCard(
                totalBalance: const Money(minorUnits: 1550000000, currencyCode: 'VND'),
                monthSummary: const MonthlyCashflowSummary(
                  income: Money(minorUnits: 2500000000, currencyCode: 'VND'),
                  expense: Money(minorUnits: 950000000, currencyCode: 'VND'),
                  net: Money(minorUnits: 1550000000, currencyCode: 'VND'),
                ),
                locale: 'vi',
                hideBalance: false,
                onToggleVisibility: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check tabs
      expect(find.text('Tổng tài sản ròng'), findsWidgets);
      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Switch tab to Chi tiêu
      await tester.tap(find.text('Chi tiêu'));
      await tester.pump();

      expect(find.text('Chi tiêu'), findsWidgets);
    });

    testWidgets('calculates real trend curve and formats delta badge accurately without negative sign glitch', (tester) async {
      final now = DateTime.now();
      final txList = [
        TransactionEntity(
          id: 'tx1',
          amount: 500000000,
          currency: 'VND',
          type: TransactionType.income,
          accountId: 'acc1',
          categoryId: 'cat_salary',
          date: now.subtract(const Duration(days: 3)),
          note: 'Lương',
          createdAt: now,
          updatedAt: now,
        ),
        TransactionEntity(
          id: 'tx2',
          amount: 200000000,
          currency: 'VND',
          type: TransactionType.expense,
          accountId: 'acc1',
          categoryId: 'cat_food',
          date: now.subtract(const Duration(days: 1)),
          note: 'Ăn uống',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LucianLiveKpiCard(
                totalBalance: const Money(minorUnits: 1300000000, currencyCode: 'VND'),
                monthSummary: const MonthlyCashflowSummary(
                  income: Money(minorUnits: 500000000, currencyCode: 'VND'),
                  expense: Money(minorUnits: 200000000, currencyCode: 'VND'),
                  net: Money(minorUnits: 300000000, currencyCode: 'VND'),
                ),
                transactions: txList,
                locale: 'vi',
                hideBalance: false,
                onToggleVisibility: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Delta label shows savings rate (300 / 500 = 60%)
      expect(find.text('+60% tích lũy tháng'), findsOneWidget);

      // Verify custom painter is present and painted
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('LucianProgressBar Widget Tests', () {
    testWidgets('renders progress bar with fraction and glow state without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LucianProgressBar(
                value: 0.75,
                height: 10,
                showGlow: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LucianProgressBar), findsOneWidget);
    });
  });

  group('LucianStretchySwitch Widget Tests', () {
    testWidgets('renders stretchy switch and triggers onChanged on tap', (tester) async {
      var switchVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return LucianStretchySwitch(
                    value: switchVal,
                    semanticLabel: 'Khóa sinh trắc học',
                    onChanged: (val) => setState(() => switchVal = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LucianStretchySwitch), findsOneWidget);
      expect(switchVal, isFalse);

      await tester.tap(find.byType(LucianStretchySwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(switchVal, isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('LucianSlidingPillTabs Widget Tests', () {
    testWidgets('renders sliding pill tabs with label and switches on tap', (tester) async {
      var selectedVal = 'A';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return LucianSlidingPillTabs<String>(
                    items: const [
                      LucianTabItem(value: 'A', label: 'Tab A'),
                      LucianTabItem(value: 'B', label: 'Tab B'),
                    ],
                    selected: selectedVal,
                    onChanged: (val) => setState(() => selectedVal = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
      expect(selectedVal, 'A');

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(selectedVal, 'B');
    });
  });
}
