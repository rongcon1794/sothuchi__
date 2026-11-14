import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/app_data_loading_view.dart';
import 'package:so_thu_chi/core/widgets/so_thu_chi_logo.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('AppDataLoadingView Widget & Accessibility Tests', () {
    testWidgets(
      'renders SoThuChiLogo, app title, activity indicator and localized messages',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const AppDataLoadingView(),
          ),
        );

        // Advance 1 frame to verify initial render
        await tester.pump(const Duration(milliseconds: 100));

        // Verifies presence of the signature Logo
        expect(find.byType(SoThuChiLogo), findsOneWidget);

        // Verifies presence of App Title
        expect(find.text('Sổ Thu Chi'), findsOneWidget);

        // Verifies presence of default localized status message
        expect(find.text('Đang tải dữ liệu...'), findsOneWidget);

        // Verifies presence of native Cupertino activity indicator
        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

        // Pump animation forward to verify smooth breathing pulse does not throw
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 700));
      },
    );

    testWidgets(
      'renders custom message and subtitle correctly when specified',
      (tester) async {
        const customMsg = 'Đang làm mới dữ liệu...';
        const customSub = 'Đang đồng bộ giao dịch mới nhất';

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const AppDataLoadingView(
              message: customMsg,
              subtitle: customSub,
              showScaffold: false,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(customMsg), findsOneWidget);
        expect(find.text(customSub), findsOneWidget);
      },
    );
  });
}
