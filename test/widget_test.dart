import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_thu_chi/app.dart';
import 'package:so_thu_chi/data/firebase/firebase_providers.dart';

void main() {
  testWidgets('App boots in Vietnamese by default and shows Onboarding slide 1', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseBootstrapStateProvider.overrideWithValue(
            const FirebaseBootstrapState.unconfigured('Test environment'),
          ),
        ],
        child: const SoThuChiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ghi chép thu chi trong 3 giây'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
  });
}
