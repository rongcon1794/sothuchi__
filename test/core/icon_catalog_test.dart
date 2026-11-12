import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('AppIconCatalog & IconAndColorPicker Tests', () {
    test('covers all catalog keys in groupedKeys and walletKeys cleanly', () {
      expect(AppIconCatalog.icons.length, greaterThanOrEqualTo(60));
      expect(AppIconCatalog.walletIconItems.length, greaterThanOrEqualTo(15));
      expect(AppIconCatalog.savingsIcons.length, greaterThanOrEqualTo(20));
      expect(AppIconCatalog.ledgerIcons.length, greaterThanOrEqualTo(20));

      final groupedFlat = AppIconCatalog.groupedKeys.values
          .expand((keys) => keys)
          .toList();
      // Every grouped key exists in icons and has no duplicates across groups
      expect(groupedFlat.toSet().length, equals(groupedFlat.length));
      expect(groupedFlat.toSet(), equals(AppIconCatalog.icons.keys.toSet()));

      for (final key in AppIconCatalog.walletKeys) {
        expect(AppIconCatalog.icons.containsKey(key), isTrue);
      }

      for (final item in AppIconCatalog.savingsIcons) {
        expect(AppIconCatalog.resolveSavingsIcon(item.$1), equals(item.$2));
      }

      for (final item in AppIconCatalog.ledgerIcons) {
        expect(AppIconCatalog.resolveLedgerIcon(item.$1), equals(item.$2));
      }
    });

    testWidgets('IconAndColorPicker filters by group and selects new icons', (
      tester,
    ) async {
      String selectedIcon = 'food';
      int selectedColor = AppIconCatalog.palette.first;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return IconAndColorPicker(
                    selectedIcon: selectedIcon,
                    selectedColor: selectedColor,
                    onIconChanged: (v) => setState(() => selectedIcon = v),
                    onColorChanged: (v) => setState(() => selectedColor = v),
                    iconSectionLabel: 'Chọn biểu tượng',
                    colorSectionLabel: 'Chọn màu',
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially shows all catalog icons
      expect(find.text('${AppIconCatalog.icons.length} icon'), findsOneWidget);

      // Filter by 'Ăn uống'
      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();

      final foodKeys = AppIconCatalog.keysForGroup(AppIconGroup.food);
      expect(find.text('${foodKeys.length} icon'), findsOneWidget);

      // Select 'Đi chợ / Siêu thị' ('groceries') inside filtered group
      final groceriesSemantic = find.bySemanticsLabel(
        'Chọn biểu tượng: Siêu thị & Đi chợ',
      );
      expect(groceriesSemantic, findsOneWidget);
      await tester.tap(groceriesSemantic);
      await tester.pumpAndSettle();

      expect(selectedIcon, equals('groceries'));
    });
  });
}

