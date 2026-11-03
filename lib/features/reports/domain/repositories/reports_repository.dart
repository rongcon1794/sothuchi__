import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

abstract interface class ReportsRepository {
  MonthlyReportData buildMonthlyReport({
    required DateTime selectedMonth,
    required String currencyCode,
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
  });
}

