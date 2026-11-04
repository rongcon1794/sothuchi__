import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/debts/data/repositories/firestore_debt_repository.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/screens/debts_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi', null);
  });

  group('InMemoryDebtRepository Unit Tests', () {
    late InMemoryDebtRepository repo;

    setUp(() {
      repo = InMemoryDebtRepository();
      repo.clear();
    });

    test('adds a lent debt successfully', () async {
      final res = await repo.addDebt(
        personName: 'Nguyễn Văn A',
        phoneNumber: '0912345678',
        type: DebtType.lent,
        amount: 1000000,
        currency: AppCurrencies.defaultCode,
        note: 'Tiền ăn liên hoan',
      );

      expect(res.isSuccess, isTrue);
      final debt = res.valueOrNull!;
      expect(debt.personName, 'Nguyễn Văn A');
      expect(debt.type, DebtType.lent);
      expect(debt.amount, 1000000);
      expect(debt.remainingAmount, 1000000);
      expect(debt.isSettled, isFalse);
    });

    test('records partial and full repayment', () async {
      final addRes = await repo.addDebt(
        personName: 'Trần Thị B',
        type: DebtType.borrowed,
        amount: 500000,
        currency: AppCurrencies.defaultCode,
      );
      final debtId = addRes.valueOrNull!.id;

      // Partial repayment
      final repayRes1 = await repo.recordRepayment(
        debtId: debtId,
        amount: 200000,
      );
      expect(repayRes1.isSuccess, isTrue);

      var updated = await repo.getDebtById(debtId);
      expect(updated!.remainingAmount, 300000);
      expect(updated.isSettled, isFalse);
      expect(updated.paidAmount, 200000);

      // Full repayment of remaining balance
      final repayRes2 = await repo.recordRepayment(
        debtId: debtId,
        amount: 300000,
      );
      expect(repayRes2.isSuccess, isTrue);

      updated = await repo.getDebtById(debtId);
      expect(updated!.remainingAmount, 0);
      expect(updated.isSettled, isTrue);
      expect(updated.progress, 1.0);
    });

    test('soft deletes a debt record', () async {
      final addRes = await repo.addDebt(
        personName: 'Lê Văn C',
        type: DebtType.lent,
        amount: 300000,
      );
      final debtId = addRes.valueOrNull!.id;

      final delRes = await repo.softDeleteDebt(debtId);
      expect(delRes.isSuccess, isTrue);

      final fetched = await repo.getDebtById(debtId);
      expect(fetched, isNull);
    });
  });

  group('DebtsScreen Widget Tests', () {
    testWidgets('renders DebtsScreen with summary and seed items', (tester) async {
      final inMem = InMemoryDebtRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debtRepositoryProvider.overrideWithValue(inMem),
          ],
          child: const MaterialApp(
            home: DebtsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & stats
      expect(find.text('Sổ Ghi Nợ'), findsOneWidget);
      expect(find.text('Người nợ tôi'), findsOneWidget);
      expect(find.text('Tôi nợ người ta'), findsOneWidget);
      expect(find.text('Ghi nợ mới'), findsOneWidget);

      // Verify seeded items
      expect(find.text('Nguyễn Văn Nam'), findsOneWidget);
      expect(find.text('Anh Ba Hàng Xóm'), findsOneWidget);
    });

    testWidgets('filters debts by tab segmented control', (tester) async {
      final inMem = InMemoryDebtRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debtRepositoryProvider.overrideWithValue(inMem),
          ],
          child: const MaterialApp(
            home: DebtsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to "Cho vay" filter
      await tester.tap(
        find.descendant(
          of: find.byType(AppleSegmentedPill<DebtFilterMode>),
          matching: find.text('Cho vay'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn Nam'), findsOneWidget);
      expect(find.text('Anh Ba Hàng Xóm'), findsNothing);

      // Switch to "Đi vay" filter
      await tester.tap(
        find.descendant(
          of: find.byType(AppleSegmentedPill<DebtFilterMode>),
          matching: find.text('Đi vay'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Văn Nam'), findsNothing);
      expect(find.text('Anh Ba Hàng Xóm'), findsOneWidget);
    });

    testWidgets('creates a new debt via DebtFormSheet', (tester) async {
      final inMem = InMemoryDebtRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debtRepositoryProvider.overrideWithValue(inMem),
          ],
          child: const MaterialApp(
            home: DebtsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Ghi nợ mới" button
      await tester.tap(find.text('Ghi nợ mới'));
      await tester.pumpAndSettle();

      // Form Sheet should be open
      expect(find.text('Ghi nhận nợ mới'), findsOneWidget);

      // Enter person name
      final nameField = find.widgetWithText(TextFormField, 'Người vay (Ai nợ bạn?) *');
      await tester.enterText(nameField, 'Chị Lan');

      // Enter amount
      final amountField = find.widgetWithText(TextFormField, 'Số tiền nợ (VND) *');
      await tester.enterText(amountField, '750000');

      // Tap Save button
      final saveBtn = find.text('Ghi nhận nợ');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Form sheet should close and list should now have "Chị Lan"
      expect(find.text('Chị Lan'), findsOneWidget);
    });
  });
}
