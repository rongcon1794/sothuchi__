import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/settings/domain/repositories/csv_export_service.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

export 'package:so_thu_chi/features/settings/domain/repositories/csv_export_service.dart';

typedef FileShareInvoker = Future<void> Function({
  required String filePath,
  required String subject,
});

class CsvExportServiceImpl implements CsvExportService {
  CsvExportServiceImpl({
    Future<Directory> Function()? tempDirProvider,
    FileShareInvoker? shareInvoker,
  }) : _tempDirProvider = tempDirProvider ?? getTemporaryDirectory,
       _shareInvoker = shareInvoker ?? _defaultShareInvoker;

  final Future<Directory> Function() _tempDirProvider;
  final FileShareInvoker _shareInvoker;

  static Future<void> _defaultShareInvoker({
    required String filePath,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/csv')],
        subject: subject,
      ),
    );
  }

  /// Neutralizes spreadsheet formula injection (`=`, `+`, `-`, `@`, `\t`, `\r`)
  /// when opening exported user notes/names in Excel or Google Sheets.
  static String sanitizeCell(String value) {
    if (value.isEmpty) return value;
    final first = value[0];
    if (first == '=' ||
        first == '+' ||
        first == '-' ||
        first == '@' ||
        first == '\t' ||
        first == '\r') {
      return "'$value";
    }
    return value;
  }

  @override
  String encodeTransactionsCsv({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    String locale = 'vi',
  }) {
    final isEn = locale.toLowerCase().startsWith('en');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<dynamic>>[
      isEn
          ? <String>[
              'ID',
              'Date',
              'Type',
              'AmountMinorUnits',
              'FormattedAmount',
              'Currency',
              'Category',
              'SourceWallet',
              'DestinationWallet',
              'Note',
              'Tags',
            ]
          : <String>[
              'ID',
              'Ngay',
              'Loai',
              'SoTienMinorUnits',
              'SoTienDinhDang',
              'TienTe',
              'DanhMuc',
              'ViNguon',
              'ViDich',
              'GhiChu',
              'TheTag',
            ],
    ];

    for (final tx in transactions) {
      final rawCategoryName = tx.type == TransactionType.transfer
          ? (isEn ? 'Transfer' : 'Chuyển khoản')
          : (categoriesById[tx.categoryId]?.localizedName(locale) ??
                tx.categoryId);
      final sourceWallet = accountsById[tx.accountId]?.name ?? tx.accountId;
      final destWallet = tx.toAccountId != null
          ? (accountsById[tx.toAccountId!]?.name ?? tx.toAccountId!)
          : '';
      final typeLabel = switch (tx.type) {
        TransactionType.income => isEn ? 'Income' : 'Thu nhập',
        TransactionType.expense => isEn ? 'Expense' : 'Chi tiêu',
        TransactionType.transfer => isEn ? 'Transfer' : 'Chuyển khoản',
      };

      rows.add(<dynamic>[
        sanitizeCell(tx.id),
        dateFmt.format(tx.date),
        typeLabel,
        tx.amount,
        tx.money.format(locale: locale),
        tx.currency,
        sanitizeCell(rawCategoryName),
        sanitizeCell(sourceWallet),
        sanitizeCell(destWallet),
        sanitizeCell(tx.note),
        sanitizeCell(tx.tags.join(', ')),
      ]);
    }

    return Csv(addBom: true).encode(rows);
  }

  @override
  Future<Result<int>> exportAndShareTransactions({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    required String subject,
    String locale = 'vi',
  }) async {
    try {
      final csvContent = encodeTransactionsCsv(
        transactions: transactions,
        categoriesById: categoriesById,
        accountsById: accountsById,
        locale: locale,
      );
      final tempDir = await _tempDirProvider();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File.fromUri(
        tempDir.uri.resolve('so_thu_chi_$stamp.csv'),
      );
      await file.writeAsString(csvContent, encoding: utf8, flush: true);

      await _shareInvoker(filePath: file.path, subject: subject);
      return Success(transactions.length);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }
}

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportServiceImpl();
});
