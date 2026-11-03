import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/data/services/biometric_service.dart';
import 'package:so_thu_chi/data/services/csv_export_service.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/data/datasources/default_categories_catalog.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/settings_screen.dart';
import 'package:so_thu_chi/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true, this.authSuccess = true});

  final bool available;
  final bool authSuccess;
  int authCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authCalls++;
    return authSuccess;
  }
}

class FakeWidgetCsvExportService implements CsvExportService {
  int exportCalls = 0;

  @override
  String encodeTransactionsCsv({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    String locale = 'vi',
  }) => '';

  @override
  Future<Result<int>> exportAndShareTransactions({
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
    required Map<String, Account> accountsById,
    required String subject,
    String locale = 'vi',
  }) async {
    exportCalls++;
    return Success(transactions.length);
  }
}

void main() {
  group('CsvExportServiceImpl & SettingsScreen Milestone (g)', () {
    test('encodes UTF-8 BOM CSV with Vietnamese diacritics and writes shareable file', () async {
      String? sharedFilePath;
      String? sharedSubject;
      final tempDir = await Directory.systemTemp.createTemp('so_thu_chi_csv_');
      addTearDown(() => tempDir.delete(recursive: true));

      final service = CsvExportServiceImpl(
        tempDirProvider: () async => tempDir,
        shareInvoker: ({required filePath, required subject}) async {
          sharedFilePath = filePath;
          sharedSubject = subject;
        },
      );

      final now = DateTime(2026, 11, 3, 9, 30);
      final categories = {
        for (final c in DefaultCategoriesCatalog.buildDefaults(now)) c.id: c,
      };
      final accounts = {
        'w1': Account(
          id: 'w1',
          name: 'Tiền mặt',
          type: AccountType.cash,
          balance: 1250000,
          currency: 'VND',
          icon: 'cash',
          color: 0xFF0D7C66,
          createdAt: now,
          updatedAt: now,
        ),
      };

      final txs = [
        TransactionEntity(
          id: 'tx_1',
          amount: 1250000,
          type: TransactionType.expense,
          accountId: 'w1',
          categoryId: 'default_food',
          note: 'Tiệc gia đình cuối tuần',
          date: now,
          tags: ['gia đình', 'ẩm thực'],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final res = await service.exportAndShareTransactions(
        transactions: txs,
        categoriesById: categories,
        accountsById: accounts,
        subject: 'Sổ Thu Chi CSV',
      );

      expect(res, isA<Success<int>>());
      expect((res as Success<int>).value, 1);
      expect(sharedSubject, 'Sổ Thu Chi CSV');
      expect(sharedFilePath, isNotNull);

      final rawBytes = await File(sharedFilePath!).readAsBytes();
      // UTF-8 BOM bytes: EF BB BF
      expect(rawBytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);

      final text = await File(sharedFilePath!).readAsString();
      expect(text, contains('Ăn uống'));
      expect(text, contains('1.250.000 ₫'));
      expect(text, contains('Tiệc gia đình cuối tuần'));
    });

    testWidgets('toggles biometric lock after hardware verification and exports CSV', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeBio = FakeBiometricService();
      final fakeCsv = FakeWidgetCsvExportService();

      final accRepo = InMemoryAccountRepository();
      final catRepo = InMemoryCategoryRepository();
      final txRepo = InMemoryTransactionRepository(accountRepo: accRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(fakeBio),
            csvExportServiceProvider.overrideWithValue(fakeCsv),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pumpAndSettle();

      // Enable biometric lock
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(fakeBio.authCalls, 1);

      // Export CSV
      await tester.tap(find.text('Xuất giao dịch ra tệp CSV'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đã tạo tệp CSV'), findsOneWidget);
    });
  });
}

