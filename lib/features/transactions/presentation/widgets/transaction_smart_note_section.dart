import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

/// Smart Note Section with TextCapitalization.sentences, quick clear, and category-aware suggested notes.
class TransactionSmartNoteSection extends StatelessWidget {
  const TransactionSmartNoteSection({
    super.key,
    required this.noteController,
    required this.type,
    required this.selectedCategory,
    required this.isDark,
  });

  final TextEditingController noteController;
  final TransactionType type;
  final Category? selectedCategory;
  final bool isDark;

  List<String> _getCategorySuggestedNotes() {
    if (type == TransactionType.income) {
      return const [
        'Lương tháng',
        'Thưởng dự án',
        'Thu nhập phụ',
        'Được tặng',
        'Lãi tiết kiệm',
        'Bán đồ cũ',
      ];
    }
    if (type == TransactionType.transfer) {
      return const [
        'Chuyển tiền',
        'Trả nợ',
        'Gửi gia đình',
        'Nạp ví điện tử',
        'Rút tiền ATM',
      ];
    }

    final catName = selectedCategory?.name.toLowerCase() ?? '';
    if (catName.contains('ăn') ||
        catName.contains('food') ||
        catName.contains('uống') ||
        catName.contains('cafe')) {
      return const [
        'Ăn sáng',
        'Ăn trưa',
        'Ăn tối',
        'Cà phê',
        'Trà sữa',
        'Đi chợ',
        'Siêu thị',
      ];
    }
    if (catName.contains('xe') ||
        catName.contains('xăng') ||
        catName.contains('di chuyển') ||
        catName.contains('transport')) {
      return const [
        'Đổ xăng',
        'Grab / Taxi',
        'Gửi xe',
        'Bảo dưỡng xe',
        'Rửa xe',
      ];
    }
    if (catName.contains('mua') ||
        catName.contains('shop') ||
        catName.contains('sắm')) {
      return const [
        'Quần áo',
        'Mỹ phẩm',
        'Đồ gia dụng',
        'Shopee',
        'Siêu thị',
      ];
    }
    if (catName.contains('nhà') ||
        catName.contains('điện') ||
        catName.contains('nước') ||
        catName.contains('hóa đơn') ||
        catName.contains('bill')) {
      return const [
        'Tiền điện',
        'Tiền nước',
        'Internet',
        'Tiền phòng / nhà',
        'Dịch vụ số',
      ];
    }
    if (catName.contains('giải trí') ||
        catName.contains('chơi') ||
        catName.contains('entertain')) {
      return const [
        'Xem phim',
        'Du lịch',
        'Game / Net',
        'Sách / Khóa học',
        'Gặp bạn bè',
      ];
    }
    if (catName.contains('sức khỏe') ||
        catName.contains('thuốc') ||
        catName.contains('y tế') ||
        catName.contains('health')) {
      return const [
        'Mua thuốc',
        'Khám bệnh',
        'Gym / Thể thao',
        'Thực phẩm bổ sung',
      ];
    }

    return const [
      'Ăn uống',
      'Cà phê',
      'Đổ xăng',
      'Mua sắm',
      'Gia đình',
      'Chi tiêu khác',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = _getCategorySuggestedNotes();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppleSquircleBadge(
                icon: CupertinoIcons.text_alignleft,
                backgroundColor: AppleTokens.systemTeal,
                size: 36,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: noteController,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: const [
                    FirstLetterCapitalizationFormatter(),
                  ],
                  maxLines: null,
                  maxLength: 1000,
                  scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 360),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: l10n.noteHint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF6C6C70)
                          : const Color(0xFF8E8E93),
                    ),
                    counterText: '',
                    suffixIcon: ListenableBuilder(
                      listenable: noteController,
                      builder: (context, _) {
                        if (noteController.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return GestureDetector(
                          onTap: () {
                            noteController.clear();
                            HapticFeedback.lightImpact();
                          },
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 18,
                            color: AppleTokens.systemGray,
                          ),
                        );
                      },
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final note in suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ApplePressable(
                      scaleDown: 0.93,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        noteController.text = note;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppleTokens.bgDarkSecondary
                              : AppleTokens.bgLightSecondary,
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE5E5EA)
                                : const Color(0xFF3A3A3C),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
