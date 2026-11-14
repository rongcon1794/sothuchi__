import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/navigation/apple_app_bar.dart';
import 'package:so_thu_chi/core/widgets/navigation/apple_bottom_nav_bar.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('AppleAppBar Component Tests', () {
    testWidgets('renders title text, accent icon and actions', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppleAppBar(
              titleText: 'Sổ giao dịch',
              icon: CupertinoIcons.doc_text,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => actionTapped = true,
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Sổ giao dịch'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.doc_text), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tune));
      expect(actionTapped, isTrue);
    });

    testWidgets('automatically shows AppleBackButton when navigator can pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      appBar: AppleAppBar(titleText: 'Màn hình con'),
                      body: SizedBox(),
                    ),
                  ),
                );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Màn hình con'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_left), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Go'), findsOneWidget);
    });
  });

  group('AppleBottomNavBar Component Tests', () {
    testWidgets('renders all destinations and triggers tap callback', (tester) async {
      int selected = 0;

      final destinations = [
        const AppleNavDestination(
          icon: CupertinoIcons.square_grid_2x2,
          activeIcon: CupertinoIcons.square_grid_2x2_fill,
          label: 'Tổng quan',
        ),
        const AppleNavDestination(
          icon: CupertinoIcons.doc_text,
          activeIcon: CupertinoIcons.doc_text_fill,
          label: 'Giao dịch',
          badgeCount: 5,
        ),
        const AppleNavDestination(
          icon: CupertinoIcons.gear_alt,
          activeIcon: CupertinoIcons.gear_alt_fill,
          label: 'Cài đặt',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) => AppleBottomNavBar(
                currentIndex: selected,
                destinations: destinations,
                onTap: (index) {
                  setState(() => selected = index);
                },
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Badge

      // Tap tab 1
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(selected, equals(1));
    });
  });
}

