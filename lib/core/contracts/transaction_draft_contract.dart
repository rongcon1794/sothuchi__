/// Extensibility contract for future `lib/features/ai/` capabilities
/// (e.g., natural-language parsing `"ăn phở 50k hôm qua"`, receipt OCR,
/// bank notification capture, or smart categorization).
///
/// Future AI modules produce a [TransactionDraft] and pass it via router `extra`
/// to `/transactions/new` without modifying `transactions/`, `accounts/`, or `categories/`.
enum TransactionDraftKind { income, expense, transfer }

class TransactionDraft {
  const TransactionDraft({
    this.amountMinorUnits,
    this.currencyCode,
    this.kind = TransactionDraftKind.expense,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.date,
    this.tags = const [],
    this.source = 'manual',
  });

  final int? amountMinorUnits;
  final String? currencyCode;
  final TransactionDraftKind kind;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;
  final DateTime? date;
  final List<String> tags;

  /// Origin identifier (`'manual'`, `'ai_nlp'`, `'ai_ocr'`, `'notification'`).
  final String source;
}

/// Optional interface that a future `lib/features/ai/` module implements.
abstract interface class TransactionDraftProducer {
  Future<TransactionDraft?> parseInput(String rawInput);
}

