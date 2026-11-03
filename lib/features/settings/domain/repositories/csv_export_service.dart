import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

abstract interface class CsvExportService {
  /// Pure CSV string generator with UTF-8 BOM (`\uFEFF`) so Vietnamese diacritics
  /// open cleanly in Microsoft Excel, Numbers, and Google Sheets.
  String encodeTransactionsCsv({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    String locale = 'vi',
  });

  /// Writes the CSV file to temporary storage and invokes the OS share sheet.
  /// Returns the number of exported transactions.
  Future<Result<int>> exportAndShareTransactions({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    required String subject,
    String locale = 'vi',
  });
}

