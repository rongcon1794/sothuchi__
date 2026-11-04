import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/features/ai/domain/vietnamese_finance_nlp_parser.dart';

void main() {
  const parser = VietnameseFinanceNlpParser();

  group('VietnameseFinanceNlpParser Tests', () {
    test('extracts food expense with colloquial "k" unit', () {
      final draft = parser.parse('Ăn phở bò 45k');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 45000);
      expect(draft.currencyCode, 'VND');
      expect(draft.kind, TransactionDraftKind.expense);
      expect(draft.categoryId, 'default_food');
      expect(draft.note, 'Ăn phở bò');
    });

    test('extracts transport expense with "k" and explicit cash wallet', () {
      final draft = parser.parse('Đổ xăng xe máy 70k tiền mặt');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 70000);
      expect(draft.kind, TransactionDraftKind.expense);
      expect(draft.categoryId, 'default_transport');
      expect(draft.accountId, 'cash');
    });

    test('extracts salary income with "tr" / "triệu"', () {
      final draft = parser.parse('Nhận lương tháng 20tr về Techcombank');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 20000000);
      expect(draft.kind, TransactionDraftKind.income);
      expect(draft.categoryId, 'default_salary');
      expect(draft.accountId, 'techcombank');
    });

    test('extracts amount with "củ" slang', () {
      final draft = parser.parse('Cho vay 2 củ');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 2000000);
    });

    test('extracts decimal million format "1.5tr"', () {
      final draft = parser.parse('Mua quần áo 1.5tr');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 1500000);
      expect(draft.categoryId, 'default_shopping');
    });

    test('extracts "hôm qua" date correctly', () {
      final draft = parser.parse('Uống trà sữa 35k hôm qua');
      expect(draft, isNotNull);
      expect(draft!.amountMinorUnits, 35000);
      expect(draft.date, isNotNull);

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(draft.date!.day, yesterday.day);
      expect(draft.date!.month, yesterday.month);
    });

    test('returns null when no amount is present', () {
      final draft = parser.parse('Hôm nay trời đẹp quá');
      expect(draft, isNull);
    });
  });
}

