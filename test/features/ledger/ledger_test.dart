import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/ledger/data/repositories/firestore_ledger_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_selector_pill.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_switcher_sheet.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('LedgerBook Domain Entity Tests', () {
    test('defaultPersonal returns initialized entity with isDefault = true', () {
      final book = LedgerBook.defaultPersonal();
      expect(book.id, LedgerBook.defaultPersonalId);
      expect(book.name, 'Sổ Cá Nhân');
      expect(book.isDefault, isTrue);
      expect(book.type, LedgerType.personal);
    });

    test('copyWith properly overrides fields', () {
      final book = LedgerBook.defaultPersonal();
      final updated = book.copyWith(name: 'Sổ Riêng', color: 0xFF5856D6);
      expect(updated.name, 'Sổ Riêng');
      expect(updated.color, 0xFF5856D6);
      expect(updated.id, book.id);
    });
  });

  group('InMemoryLedgerRepository Unit Tests', () {
    test('seeds default books, creates new book, and prevents deleting default', () async {
      final repo = InMemoryLedgerRepository();
      var books = await repo.watchLedgers().first;
      expect(books.length, 2);
      expect(books.any((b) => b.id == LedgerBook.defaultPersonalId), isTrue);

      // Create new business book
      final createRes = await repo.createLedger(
        LedgerBook(
          id: 'ledger_biz',
          name: 'Quỹ Dự Án Nhỏ',
          type: LedgerType.business,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(createRes.isSuccess, isTrue);
      books = await repo.watchLedgers().first;
      expect(books.length, 3);

      // Trying to delete default personal book fails
      final delDefaultRes = await repo.deleteLedger(LedgerBook.defaultPersonalId);
      expect(delDefaultRes.isFailure, isTrue);

      // Deleting custom book succeeds
      final delCustomRes = await repo.deleteLedger('ledger_biz');
      expect(delCustomRes.isSuccess, isTrue);
      books = await repo.watchLedgers().first;
      expect(books.length, 2);
    });
  });

  group('LedgerSelectorPill and Switcher Widget Tests', () {
    late InMemoryLedgerRepository ledgerRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'locale_code': 'vi',
        'active_ledger_id': LedgerBook.defaultPersonalId,
      });
      prefs = await SharedPreferences.getInstance();
      ledgerRepo = InMemoryLedgerRepository();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            appBar: null,
            body: Center(
              child: LedgerSelectorPill(),
            ),
          ),
        ),
      );
    }

    testWidgets('renders active book name and opens switcher modal', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Renders active book name "Sổ Cá Nhân"
      expect(find.text('Sổ Cá Nhân'), findsOneWidget);

      // Tap on pill
      await tester.tap(find.byType(LedgerSelectorPill));
      await tester.pumpAndSettle();

      // Switcher bottom sheet opened
      expect(find.byType(LedgerSwitcherSheet), findsOneWidget);
      expect(find.text('Chuyển Sổ Thu Chi'), findsOneWidget);
      expect(find.text('Sổ Gia Đình'), findsOneWidget);

      // Tap to switch to "Sổ Gia Đình"
      await tester.tap(find.text('Sổ Gia Đình'));
      await tester.pumpAndSettle();

      // Active ledger on pill switched to "Sổ Gia Đình"
      expect(find.text('Sổ Gia Đình'), findsOneWidget);
    });

    testWidgets('compact mode renders icon button and opens switcher modal on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(
                child: LedgerSelectorPill(compact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LedgerSelectorPill), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.byType(LedgerSelectorPill));
      await tester.pumpAndSettle();

      expect(find.byType(LedgerSwitcherSheet), findsOneWidget);
      expect(find.text('Chuyển Sổ Thu Chi'), findsOneWidget);
    });
  });
}

