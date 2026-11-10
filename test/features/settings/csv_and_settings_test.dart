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
import 'package:so_thu_chi/features/auth/domain/entities/app_user.dart';
import 'package:so_thu_chi/features/categories/data/datasources/default_categories_catalog.dart';
import 'package:so_thu_chi/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/settings/presentation/screens/settings_screen.dart';
import 'package:so_thu_chi/features/settings/presentation/widgets/default_wallet_picker_sheet.dart';
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
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            currentUserProvider.overrideWithValue(
              AppUser(
                uid: 'u1',
                email: 'test@example.com',
                displayName: 'Huy Nguyen',
                isDemoUser: false,
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
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

    testWidgets('renders and updates theme accent palette', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            currentUserProvider.overrideWithValue(
              AppUser(
                uid: 'u1',
                email: 'test@example.com',
                displayName: 'Huy Nguyen',
                isDemoUser: false,
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
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

      expect(find.text('Màu ứng dụng'), findsOneWidget);
      expect(find.text('Ngọc Bích'), findsOneWidget);

      // Verify English locale renders English palette names
      SharedPreferences.setMockInitialValues({'settings.locale_code': 'en'});
      final enPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(enPrefs),
            biometricServiceProvider.overrideWithValue(fakeBio),
            csvExportServiceProvider.overrideWithValue(fakeCsv),
            accountRepositoryProvider.overrideWithValue(accRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            transactionRepositoryProvider.overrideWithValue(txRepo),
            currentUserProvider.overrideWithValue(
              AppUser(
                uid: 'u1',
                email: 'test@example.com',
                displayName: 'Huy Nguyen',
                isDemoUser: false,
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Theme Accent Color'), findsOneWidget);
      expect(find.text('Emerald Jade'), findsOneWidget);
    });

    test('AppTheme.localizedPaletteName returns Vietnamese and English names accurately', () {
      expect(AppTheme.localizedPaletteName(0, locale: 'vi'), 'Ngọc Bích');
      expect(AppTheme.localizedPaletteName(1, locale: 'vi'), 'Đại Dương');
      expect(AppTheme.localizedPaletteName(2, locale: 'vi'), 'Hoàng Hôn');
      expect(AppTheme.localizedPaletteName(3, locale: 'vi'), 'Thạch Anh');

      expect(AppTheme.localizedPaletteName(0, locale: 'en'), 'Emerald Jade');
      expect(AppTheme.localizedPaletteName(1, locale: 'en'), 'Ocean Blue');
      expect(AppTheme.localizedPaletteName(2, locale: 'en'), 'Sunset Amber');
      expect(AppTheme.localizedPaletteName(3, locale: 'en'), 'Amethyst Violet');
    });

    testWidgets('places delete account & data in dedicated Danger Zone section away from quick actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            currentUserProvider.overrideWithValue(
              AppUser(
                uid: 'u1',
                email: 'test@example.com',
                displayName: 'Huy Nguyen',
                isDemoUser: false,
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
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

      // Top profile card only has sign-out quick button, no delete button
      expect(find.byTooltip('Đăng xuất'), findsOneWidget);

      // Scroll to bottom to find compact delete button
      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.text('Xóa tài khoản & toàn bộ dữ liệu'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('displays OLED True Black mode toggle in dark theme', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'settings.theme_mode': 'dark',
      });
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
            theme: AppTheme.dark(AppTheme.seedColor, true),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OLED True Black'), findsOneWidget);
    });

    testWidgets('DefaultWalletPickerSheet renders hero banner, active default card, and updates selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final now = DateTime(2026, 11, 1);
      final w1 = Account(
        id: 'w1',
        name: 'Tiền mặt',
        type: AccountType.cash,
        balance: 1500000,
        currency: 'VND',
        icon: 'cash',
        color: 0xFF0D7C66,
        createdAt: now,
        updatedAt: now,
      );
      final w2 = Account(
        id: 'w2',
        name: 'Vietcombank',
        type: AccountType.bank,
        balance: 12000000,
        currency: 'VND',
        icon: 'bank',
        color: 0xFF1D5BD6,
        createdAt: now,
        updatedAt: now,
      );

      String? selectedId = 'w1';

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DefaultWalletPickerSheet.show(
                    context: context,
                    wallets: [w1, w2],
                    currentDefaultId: selectedId,
                    onSelected: (id) => selectedId = id,
                  );
                },
                child: const Text('Open Default Wallet Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Default Wallet Sheet'));
      await tester.pumpAndSettle();

      // Check Header and Info banner
      expect(find.text('Ví mặc định chi tiêu'), findsOneWidget);
      expect(find.text('Tiết kiệm thao tác nhập liệu'), findsOneWidget);

      // Check Active Default Hero card
      expect(find.text('VÍ ĐANG ĐƯỢC CHỌN MẶC ĐỊNH'), findsOneWidget);
      expect(find.text('MẶC ĐỊNH'), findsOneWidget);

      // Check all wallets list
      expect(find.text('TẤT CẢ VÍ & TÀI KHOẢN (2)'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);

      // Tap Vietcombank to set it as default
      await tester.tap(find.text('Vietcombank'));
      await tester.pumpAndSettle();

      expect(selectedId, 'w2');

      // Re-open and tap 'Không đặt ví mặc định'
      await tester.tap(find.text('Open Default Wallet Sheet'));
      await tester.pumpAndSettle();

      final clearDefaultBtn = find.text('Không đặt ví mặc định');
      expect(clearDefaultBtn, findsOneWidget);
      await tester.ensureVisible(clearDefaultBtn);
      await tester.tap(clearDefaultBtn);
      await tester.pumpAndSettle();

      expect(selectedId, isNull);
    });
  });
}

