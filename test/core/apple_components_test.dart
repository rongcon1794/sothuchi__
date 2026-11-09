import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

void main() {
  group('Apple HIG Shared Component System Tests', () {
    testWidgets('AppleButton renders variants, handles clicks, and shows loading indicator', (tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppleButton.primary(
                  label: 'Lưu giao dịch',
                  icon: CupertinoIcons.check_mark,
                  onPressed: () => clicked = true,
                ),
                const AppleButton.secondary(
                  label: 'Hủy bỏ',
                ),
                const AppleButton.destructive(
                  label: 'Xóa mục',
                ),
                const AppleButton(
                  label: 'Đang lưu...',
                  isLoading: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Lưu giao dịch'), findsOneWidget);
      expect(find.text('Hủy bỏ'), findsOneWidget);
      expect(find.text('Xóa mục'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      await tester.tap(find.text('Lưu giao dịch'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(clicked, isTrue);
    });

    testWidgets('AppleTextField accepts input, triggers onChanged, and clears text', (tester) async {
      String value = '';
      final controller = TextEditingController(text: 'Ăn tối');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleTextField(
              controller: controller,
              label: 'Ghi chú',
              placeholder: 'Nhập ghi chú...',
              clearable: true,
              onChanged: (val) => value = val,
            ),
          ),
        ),
      );

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text('Ăn tối'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.clear_circled_solid), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(CupertinoIcons.clear_circled_solid));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(value, isEmpty);
    });

    testWidgets('AppleCard renders child and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleCard(
              onTap: () => tapped = true,
              child: const Text('Thẻ thông tin'),
            ),
          ),
        ),
      );

      expect(find.text('Thẻ thông tin'), findsOneWidget);
      await tester.tap(find.text('Thẻ thông tin'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AppleDatePickerTile displays formatted date and opens date picker on tap', (tester) async {
      DateTime pickedDate = DateTime(2026, 11, 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleDatePickerTile(
              label: 'Ngày giao dịch',
              selectedDate: pickedDate,
              onDateSelected: (d) => pickedDate = d,
            ),
          ),
        ),
      );

      expect(find.text('Ngày giao dịch'), findsOneWidget);
      expect(find.textContaining('04/11/2026'), findsOneWidget);

      await tester.tap(find.byType(AppleDatePickerTile));
      await tester.pumpAndSettle();
      // DatePicker dialog opens
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('AppleModalSheetLayout renders title, body, and bottom action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleModalSheetLayout(
              title: 'Thêm mục mới',
              subtitle: 'Điền thông tin chi tiết',
              bottomAction: AppleButton(label: 'Xác nhận'),
              child: Text('Nội dung biểu mẫu'),
            ),
          ),
        ),
      );

      expect(find.text('Thêm mục mới'), findsOneWidget);
      expect(find.text('Điền thông tin chi tiết'), findsOneWidget);
      expect(find.text('Nội dung biểu mẫu'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);
    });

    testWidgets('OLED True Black applies pitch black background and card surfaces', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AppTheme.seedColor, true),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    const AppleCard(child: Text('Card Content')),
                    const AppleGlassCard(child: Text('Glass Card Content')),
                    Text('Is OLED: ${context.isOled}'),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Is OLED: true'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Glass Card Content'), findsOneWidget);

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.scaffoldBackgroundColor, equals(AppleTokens.bgOledPrimary));
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
    });

    testWidgets('ApplePopupMenuButton renders 3-dots trigger, opens menu, and handles selection', (tester) async {
      String? selectedVal;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ApplePopupMenuButton<String>(
                tooltip: 'Tùy chọn',
                onSelected: (val) => selectedVal = val,
                itemBuilder: (ctx) => [
                  ApplePopupMenuItem(
                    value: 'edit',
                    icon: CupertinoIcons.pencil,
                    title: 'Chỉnh sửa',
                  ),
                  ApplePopupMenuItem(
                    value: 'delete',
                    icon: CupertinoIcons.trash,
                    title: 'Xóa mục',
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 3-dots trigger
      final trigger = find.byType(ApplePopupMenuButton<String>);
      expect(trigger, findsOneWidget);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);

      // Tap trigger to open menu
      await tester.tap(trigger);
      await tester.pumpAndSettle();

      // Menu items displayed
      expect(find.text('Chỉnh sửa'), findsOneWidget);
      expect(find.text('Xóa mục'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);

      // Tap item 'edit'
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(selectedVal, 'edit');
    });
  });
}
