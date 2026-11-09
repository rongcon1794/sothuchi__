import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';
import 'package:so_thu_chi/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders first slide, brand logo, and progresses through all 5 feature slides', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932)); // iPhone 15 Pro portrait
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'settings.onboarding_completed': false});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar brand & skip button
      expect(find.text('Sổ Thu Chi'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);

      // Slide 1: Ghi chép & Đa ví
      expect(find.text('GHI CHÉP & ĐA VÍ'), findsOneWidget);
      expect(find.text('Ghi chép thu chi trong 3 giây'), findsOneWidget);
      expect(find.text('Vietcombank Digital'), findsOneWidget);
      expect(find.text('42.500.000 ₫'), findsOneWidget);
      expect(find.text('Cà phê sáng'), findsOneWidget);
      expect(find.text('Lương tháng 11'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Go to Slide 2: Ngân sách thông minh
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('NGÂN SÁCH THÔNG MINH'), findsOneWidget);
      expect(find.text('Ngân sách & Kiểm soát chi tiêu'), findsOneWidget);
      expect(find.text('NGÂN SÁCH THÁNG'), findsOneWidget);
      expect(find.text('6.800.000 ₫'), findsOneWidget);
      expect(find.text('240.000 ₫'), findsOneWidget);

      // Go to Slide 3: Mục tiêu & Hóa đơn
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('MỤC TIÊU & HÓA ĐƠN'), findsOneWidget);
      expect(find.text('Mục tiêu tiết kiệm & Hóa đơn định kỳ'), findsOneWidget);
      expect(find.text('MUA MACBOOK PRO M3'), findsOneWidget);
      expect(find.text('22.500.000 ₫'), findsOneWidget);
      expect(find.text('Hóa đơn điện EVN'), findsOneWidget);

      // Go to Slide 4: Báo cáo tài chính
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('BÁO CÁO TÀI CHÍNH'), findsOneWidget);
      expect(find.text('Báo cáo trực quan & Phân tích chuyên sâu'), findsOneWidget);
      expect(find.text('DÒNG TIỀN THÁNG'), findsOneWidget);
      expect(find.text('+35.000.000 ₫'), findsOneWidget);
      expect(find.text('+15.500.000 ₫'), findsOneWidget);

      // Go to Slide 5: Bảo mật & Đồng bộ
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('BẢO MẬT & ĐỒNG BỘ'), findsOneWidget);
      expect(find.text('Bảo mật riêng tư & Đồng bộ đám mây'), findsOneWidget);
      expect(find.text('Ngoại tuyến 100%'), findsOneWidget);
      expect(find.text('Đồng bộ Firebase'), findsOneWidget);
      expect(find.text('Bắt đầu ngay'), findsOneWidget);

      // Tap "Bắt đầu ngay" -> Completes onboarding
      await tester.tap(find.text('Bắt đầu ngay'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('settings.onboarding_completed'), isTrue);
    });

    testWidgets('Skip button completes onboarding immediately', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'settings.onboarding_completed': false});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();

      expect(prefs.getBool('settings.onboarding_completed'), isTrue);
    });

    testWidgets('Wide / landscape screen renders responsive side-by-side layout without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 600)); // Landscape / tablet
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({'settings.onboarding_completed': false});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(),
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ghi chép thu chi trong 3 giây'), findsOneWidget);
      expect(find.text('Vietcombank Digital'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });
  });
}
