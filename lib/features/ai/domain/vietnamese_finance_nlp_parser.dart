import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';

/// Intelligent parser extracting financial transaction details from natural Vietnamese text.
///
/// Handles colloquial patterns like:
/// - "ăn trưa phở bò 45k" -> 45,000 VND, expense, category: food, note: "phở bò"
/// - "đổ xăng 70k ví tiền mặt" -> 70,000 VND, expense, category: transport, account: cash
/// - "lương tháng 11 20tr về techcombank" -> 20,000,000 VND, income, category: salary, account: bank
/// - "chuyển 500k cho mẹ từ tiền mặt sang momo" -> 500,000 VND, transfer
class VietnameseFinanceNlpParser implements TransactionDraftProducer {
  const VietnameseFinanceNlpParser();

  /// Synchronous parsing method for instant UI feedback and unit tests.
  TransactionDraft? parse(String rawInput) {
    final text = rawInput.trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();

    // 1. Extract money amount - if no amount found, cannot form a financial transaction
    final amount = _extractAmount(lower);
    if (amount == null || amount <= 0) return null;

    // 2. Determine transaction kind
    final kind = _detectKind(lower);

    // 3. Extract category id (for income / expense)
    final categoryId = kind != TransactionDraftKind.transfer
        ? _detectCategory(lower, kind)
        : null;

    // 4. Extract wallet/account
    final accountId = _detectWallet(lower);

    // 5. Extract date if specified (hôm nay, hôm qua, hôm kia)
    final date = _detectDate(lower);

    // 6. Clean note (remove detected amount tokens and keywords for a clean title)
    final note = _cleanNote(text, lower);

    return TransactionDraft(
      amountMinorUnits: amount,
      currencyCode: AppCurrencies.defaultCode,
      kind: kind,
      accountId: accountId,
      categoryId: categoryId,
      date: date,
      note: note.isNotEmpty ? note : text,
      source: 'ai_nlp',
    );
  }

  @override
  Future<TransactionDraft?> parseInput(String rawInput) async => parse(rawInput);

  String? _detectWallet(String lower) {
    if (lower.contains('tiền mặt') || lower.contains('cash')) {
      return 'cash';
    }
    if (lower.contains('techcombank') || lower.contains('tcb')) {
      return 'techcombank';
    }
    if (lower.contains('vietcombank') || lower.contains('vcb')) {
      return 'vietcombank';
    }
    if (lower.contains('momo')) {
      return 'momo';
    }
    if (lower.contains('mb') || lower.contains('mbbank')) {
      return 'mbbank';
    }
    return null;
  }

  TransactionDraftKind _detectKind(String lower) {
    // Transfer keywords
    if (lower.contains('chuyển') ||
        lower.contains('bắn tiền') ||
        lower.contains('rút tiền') ||
        lower.contains('nạp tiền') ||
        lower.contains('sang ví') ||
        lower.contains('vào ví')) {
      return TransactionDraftKind.transfer;
    }

    // Income keywords
    if (lower.contains('lương') ||
        lower.contains('thưởng') ||
        lower.contains('nhận tiền') ||
        lower.contains('được cho') ||
        lower.contains('thu nhập') ||
        lower.contains('tiền lãi') ||
        lower.contains('hoàn tiền') ||
        lower.contains('bán được') ||
        lower.contains('thu vào') ||
        lower.contains('cổ tức')) {
      return TransactionDraftKind.income;
    }

    // Default to expense
    return TransactionDraftKind.expense;
  }

  int? _extractAmount(String lower) {
    // Match patterns:
    // 1. "1.5tr", "1,5tr", "1tr5", "2tr", "20tr", "2 củ"
    final trPattern = RegExp(
      r'(\d+)(?:[.,](\d+))?\s*(?:tr|triệu|củ)(?:\s|$|[^\p{L}\p{N}])',
      unicode: true,
    );
    final trMatch = trPattern.firstMatch(lower);
    if (trMatch != null) {
      final whole = int.tryParse(trMatch.group(1) ?? '0') ?? 0;
      final fracStr = trMatch.group(2);
      if (fracStr != null && fracStr.isNotEmpty) {
        final frac = double.tryParse('0.$fracStr') ?? 0.0;
        return ((whole + frac) * 1000000).round();
      }
      return whole * 1000000;
    }

    // Pattern: "1tr5", "2tr3"
    final trShortPattern = RegExp(r'(\d+)tr(\d+)(?:\s|$|[^\p{L}\p{N}])', unicode: true);
    final trShortMatch = trShortPattern.firstMatch(lower);
    if (trShortMatch != null) {
      final whole = int.tryParse(trShortMatch.group(1) ?? '0') ?? 0;
      final fracStr = trShortMatch.group(2) ?? '0';
      final fracVal = (int.tryParse(fracStr) ?? 0) * (fracStr.length == 1 ? 100000 : 10000);
      return (whole * 1000000) + fracVal;
    }

    // 2. "50k", "100k", "500k", "50 ngàn", "50 nghìn"
    final kPattern = RegExp(
      r'(\d+)(?:[.,](\d+))?\s*(?:k|nghìn|ngàn|ng)(?:\s|$|[^\p{L}\p{N}])',
      unicode: true,
    );
    final kMatch = kPattern.firstMatch(lower);
    if (kMatch != null) {
      final whole = int.tryParse(kMatch.group(1) ?? '0') ?? 0;
      final fracStr = kMatch.group(2);
      if (fracStr != null && fracStr.isNotEmpty) {
        final frac = double.tryParse('0.$fracStr') ?? 0.0;
        return ((whole + frac) * 1000).round();
      }
      return whole * 1000;
    }

    // 3. "50.000", "500.000", "1.500.000"
    final dotSeparatedPattern = RegExp(r'(?:^|\s)(\d{1,3}(?:\.\d{3})+)(?:\s*(?:đ|vnd|đồng))?(?:\s|$|[^\p{L}\p{N}])', unicode: true);
    final dotMatch = dotSeparatedPattern.firstMatch(lower);
    if (dotMatch != null) {
      final raw = dotMatch.group(1)!.replaceAll('.', '');
      return int.tryParse(raw);
    }

    // 4. Standalone plain number with optional VND suffix (e.g. "50000", "200000 đ")
    final numPattern = RegExp(r'(?:^|\s)(\d{4,9})\s*(?:đ|vnd|đồng)?(?:\s|$|[^\p{L}\p{N}])', unicode: true);
    final numMatch = numPattern.firstMatch(lower);
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1)!);
    }

    return null;
  }

  bool _hasWord(String text, List<String> keywords) {
    final tokens = text.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true));
    for (final kw in keywords) {
      if (kw.contains(' ')) {
        if (text.contains(kw)) return true;
      } else {
        if (tokens.contains(kw)) return true;
      }
    }
    return false;
  }

  String? _detectCategory(String lower, TransactionDraftKind kind) {
    if (kind == TransactionDraftKind.income) {
      if (_hasWord(lower, ['lương', 'tiền lương'])) {
        return 'default_salary';
      }
      if (_hasWord(lower, ['thưởng', 'hoa hồng'])) {
        return 'default_bonus';
      }
      if (_hasWord(lower, ['lãi', 'cổ tức', 'đầu tư'])) {
        return 'default_investment';
      }
      return 'default_other_income';
    }

    // Expense categories
    if (_hasWord(lower, [
      'xăng', 'đổ xăng', 'xe', 'xe máy', 'grab', 'be', 'taxi', 'gửi xe',
      'bảo dưỡng', 'rửa xe', 'vé tàu', 'vé máy bay', 'cầu đường'
    ])) {
      return 'default_transport';
    }

    if (_hasWord(lower, [
      'ăn', 'uống', 'cà phê', 'cafe', 'bún', 'phở', 'cơm', 'bánh',
      'trà sữa', 'nhậu', 'buffet', 'trưa', 'sáng', 'tối', 'chè', 'nước'
    ])) {
      return 'default_food';
    }

    if (_hasWord(lower, [
      'điện', 'tiền điện', 'nước', 'tiền nước', 'internet', 'wifi', 'hóa đơn',
      'nạp đt', 'nạp thẻ', '4g', '3g', 'phí dịch vụ', 'rác'
    ])) {
      return 'default_bills';
    }

    if (_hasWord(lower, [
      'mua', 'shopee', 'lazada', 'tiki', 'quần áo', 'giày', 'dép',
      'siêu thị', 'chợ'
    ])) {
      return 'default_shopping';
    }

    if (_hasWord(lower, [
      'phim', 'cinema', 'game', 'du lịch', 'karaoke', 'netflix', 'spotify', 'chơi'
    ])) {
      return 'default_entertainment';
    }

    if (_hasWord(lower, [
      'thuốc', 'khám', 'bệnh', 'bác sĩ', 'nha khoa', 'răng', 'gym', 'yoga'
    ])) {
      return 'default_health';
    }

    if (_hasWord(lower, [
      'học', 'học phí', 'sách', 'vở', 'khóa học', 'gia sư'
    ])) {
      return 'default_education';
    }

    if (_hasWord(lower, [
      'nhà', 'tiền phòng', 'thuê nhà', 'sửa nhà'
    ])) {
      return 'default_housing';
    }

    return 'default_other_expense';
  }

  DateTime? _detectDate(String lower) {
    final now = DateTime.now();
    if (lower.contains('hôm qua')) {
      return now.subtract(const Duration(days: 1));
    }
    if (lower.contains('hôm kia')) {
      return now.subtract(const Duration(days: 2));
    }
    if (lower.contains('hôm nay')) {
      return now;
    }
    return null;
  }

  String _cleanNote(String original, String lower) {
    // Strip common amount patterns and date references for a crisp, readable title
    var note = original;
    final removals = [
      RegExp(r'\b\d+(?:[.,]\d+)?\s*(?:tr|triệu|củ|k|nghìn|ngàn|ng|vnd|đ|đồng)\b', caseSensitive: false),
      RegExp(r'\b\d{1,3}(?:\.\d{3})+\b'),
      RegExp(r'\b\d{4,9}\b'),
      RegExp(r'\b(hôm qua|hôm nay|hôm kia)\b', caseSensitive: false),
      RegExp(r'\b(ví|tiền mặt|ngân hàng|techcombank|vcb|vietcombank|momo)\b', caseSensitive: false),
    ];

    for (final reg in removals) {
      note = note.replaceAll(reg, ' ');
    }

    // Capitalize first letter and trim multiple whitespaces
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (note.isEmpty) return original;
    return note[0].toUpperCase() + note.substring(1);
  }
}
