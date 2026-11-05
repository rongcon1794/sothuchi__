import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/widgets/apple_user_avatar.dart';

void main() {
  group('AppleUserAvatar Widget Tests', () {
    testWidgets('renders fallback initials when photoUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleUserAvatar(
              displayName: 'Nguyễn Văn A',
              email: 'nguyen@example.com',
              size: 50,
            ),
          ),
        ),
      );

      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('renders email initial when displayName is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleUserAvatar(
              email: 'huy@gmail.com',
              size: 48,
            ),
          ),
        ),
      );

      expect(find.text('H'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleUserAvatar(
              displayName: 'Antigravity User',
              size: 48,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppleUserAvatar));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
