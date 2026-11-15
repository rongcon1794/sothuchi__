import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/so_thu_chi_logo.dart';

void main() {
  group('SoThuChiLogo widget tests', () {
    testWidgets('renders SoThuChiLogo with specified size without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SoThuChiLogo(size: 64),
            ),
          ),
        ),
      );

      expect(find.byType(SoThuChiLogo), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
