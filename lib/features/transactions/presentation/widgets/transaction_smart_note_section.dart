import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Represents a suggested transaction description/note item.
class SmartNoteSuggestion {
  const SmartNoteSuggestion({
    required this.note,
    required this.isFromHistory,
    this.isExactMatch = false,
  });

  final String note;
  final bool isFromHistory;
  final bool isExactMatch;
}

class _NoteAccumulator {
  _NoteAccumulator({
    required this.displayNote,
    required this.bestContextScore,
    required this.isExactMatch,
    required this.mostRecentIndex,
  });

  final String displayNote;
  double bestContextScore;
  bool isExactMatch;
  final int mostRecentIndex;
  int count = 1;
}

/// Builds ranked note suggestions from user transaction history based on
/// transaction type, selected category, entered amount, frequency, and recency,
/// padded with category-aware fallback defaults.
List<SmartNoteSuggestion> buildSmartNoteSuggestions({
  required List<TransactionEntity> transactions,
  required TransactionType type,
  required Category? selectedCategory,
  required int enteredAmountMinor,
  required String currencyCode,
  required String currentQuery,
  required List<String> fallbackSuggestions,
  int maxSuggestions = 10,
}) {
  final queryLower = currentQuery.trim().toLowerCase();
  final Map<String, _NoteAccumulator> historyMap = {};

  final scanLimit = math.min(transactions.length, 1000);
  for (var i = 0; i < scanLimit; i++) {
    final tx = transactions[i];
    if (tx.type != type) continue;

    final note = tx.note.trim();
    if (note.isEmpty || note.length > 80 || note.contains('\n')) continue;

    final key = note.toLowerCase();
    final isSameCurrency = tx.currency == currencyCode;
    final isExactAmount =
        enteredAmountMinor > 0 && isSameCurrency && tx.amount == enteredAmountMinor;
    final isCloseAmount = enteredAmountMinor > 0 &&
        isSameCurrency &&
        !isExactAmount &&
        (tx.amount - enteredAmountMinor).abs() <= enteredAmountMinor * 0.25;

    final isTransfer = type == TransactionType.transfer;
    final isSameCategory = !isTransfer &&
        selectedCategory != null &&
        tx.categoryId == selectedCategory.id;

    double contextScore = 0;
    bool exactContextMatch = false;

    if (isTransfer) {
      contextScore = 200;
      if (isExactAmount) {
        contextScore += 450;
        exactContextMatch = true;
      } else if (isCloseAmount) {
        contextScore += 200;
      }
    } else if (selectedCategory != null) {
      if (isSameCategory) {
        contextScore = 300;
        if (isExactAmount) {
          contextScore += 450;
          exactContextMatch = true;
        } else if (isCloseAmount) {
          contextScore += 200;
        }
      } else if (isExactAmount) {
        // Exact amount match from another category of the same type.
        contextScore = 280;
      } else if (queryLower.isNotEmpty && key.contains(queryLower)) {
        // Active query matches a note previously used in another category.
        contextScore = 50;
      } else {
        continue;
      }
    } else {
      contextScore = 150;
      if (isExactAmount) {
        contextScore += 450;
        exactContextMatch = true;
      } else if (isCloseAmount) {
        contextScore += 200;
      }
    }

    final existing = historyMap[key];
    if (existing == null) {
      historyMap[key] = _NoteAccumulator(
        displayNote: note,
        bestContextScore: contextScore,
        isExactMatch: exactContextMatch,
        mostRecentIndex: i,
      );
    } else {
      existing.count += 1;
      if (contextScore > existing.bestContextScore) {
        existing.bestContextScore = contextScore;
      }
      if (exactContextMatch) {
        existing.isExactMatch = true;
      }
    }
  }

  final scoredEntries = historyMap.entries.map((entry) {
    final acc = entry.value;
    final key = entry.key;

    double queryBonus = 0;
    if (queryLower.isNotEmpty) {
      if (key.startsWith(queryLower)) {
        queryBonus = 600;
      } else if (key.contains(queryLower)) {
        queryBonus = 350;
      }
    }

    final frequencyBonus = math.min(acc.count, 10) * 18.0;
    final recencyBonus = 100.0 / (1.0 + acc.mostRecentIndex * 0.15);
    final totalScore =
        acc.bestContextScore + queryBonus + frequencyBonus + recencyBonus;

    return (acc: acc, score: totalScore);
  }).toList();

  scoredEntries.sort((a, b) {
    final cmp = b.score.compareTo(a.score);
    if (cmp != 0) return cmp;
    return a.acc.mostRecentIndex.compareTo(b.acc.mostRecentIndex);
  });

  final results = <SmartNoteSuggestion>[];
  final seenKeys = <String>{};

  for (final item in scoredEntries) {
    if (results.length >= maxSuggestions) break;
    final note = item.acc.displayNote;
    final key = note.toLowerCase();
    if (seenKeys.add(key)) {
      results.add(
        SmartNoteSuggestion(
          note: note,
          isFromHistory: true,
          isExactMatch: item.acc.isExactMatch,
        ),
      );
    }
  }

  if (results.length < maxSuggestions) {
    final matchingFallbacks = <String>[];
    final otherFallbacks = <String>[];
    for (final fb in fallbackSuggestions) {
      if (seenKeys.contains(fb.toLowerCase())) continue;
      if (queryLower.isNotEmpty && fb.toLowerCase().contains(queryLower)) {
        matchingFallbacks.add(fb);
      } else {
        otherFallbacks.add(fb);
      }
    }

    for (final fb in [...matchingFallbacks, ...otherFallbacks]) {
      if (results.length >= maxSuggestions) break;
      if (seenKeys.add(fb.toLowerCase())) {
        results.add(
          SmartNoteSuggestion(
            note: fb,
            isFromHistory: false,
            isExactMatch: false,
          ),
        );
      }
    }
  }

  return results;
}

/// Smart Note Section with TextCapitalization.sentences, quick clear,
/// and dynamic history-aware suggestions based on category and amount.
class TransactionSmartNoteSection extends ConsumerWidget {
  const TransactionSmartNoteSection({
    super.key,
    required this.noteController,
    required this.type,
    required this.selectedCategory,
    required this.isDark,
    this.amountController,
    this.currencyCode = AppCurrencies.defaultCode,
  });

  final TextEditingController noteController;
  final TextEditingController? amountController;
  final String currencyCode;
  final TransactionType type;
  final Category? selectedCategory;
  final bool isDark;

  List<String> _getCategorySuggestedNotes({bool isVi = true}) {
    if (type == TransactionType.income) {
      return isVi
          ? const [
              'Lương tháng',
              'Thưởng dự án',
              'Thu nhập phụ',
              'Được tặng',
              'Lãi tiết kiệm',
              'Bán đồ cũ',
            ]
          : const [
              'Monthly Salary',
              'Project Bonus',
              'Side Income',
              'Gift Received',
              'Savings Interest',
              'Sold Items',
            ];
    }
    if (type == TransactionType.transfer) {
      return isVi
          ? const [
              'Chuyển tiền',
              'Trả nợ',
              'Gửi gia đình',
              'Nạp ví điện tử',
              'Rút tiền ATM',
            ]
          : const [
              'Transfer Money',
              'Debt Repayment',
              'Family Support',
              'E-Wallet Top-up',
              'ATM Withdrawal',
            ];
    }

    final catName = selectedCategory?.name.toLowerCase() ?? '';
    if (catName.contains('ăn') ||
        catName.contains('food') ||
        catName.contains('uống') ||
        catName.contains('drink') ||
        catName.contains('cafe')) {
      return isVi
          ? const [
              'Ăn sáng',
              'Ăn trưa',
              'Ăn tối',
              'Cà phê',
              'Trà sữa',
              'Đi chợ',
              'Siêu thị',
            ]
          : const [
              'Breakfast',
              'Lunch',
              'Dinner',
              'Coffee',
              'Tea & Boba',
              'Groceries',
              'Supermarket',
            ];
    }
    if (catName.contains('xe') ||
        catName.contains('xăng') ||
        catName.contains('di chuyển') ||
        catName.contains('fuel') ||
        catName.contains('transit') ||
        catName.contains('transport')) {
      return isVi
          ? const [
              'Đổ xăng',
              'Grab / Taxi',
              'Gửi xe',
              'Bảo dưỡng xe',
              'Rửa xe',
            ]
          : const [
              'Gas / Fuel',
              'Taxi / Ride',
              'Parking Fee',
              'Vehicle Maintenance',
              'Car Wash',
            ];
    }
    if (catName.contains('mua') ||
        catName.contains('shop') ||
        catName.contains('sắm')) {
      return isVi
          ? const [
              'Quần áo',
              'Mỹ phẩm',
              'Đồ gia dụng',
              'Shopee',
              'Siêu thị',
            ]
          : const [
              'Clothing',
              'Cosmetics',
              'Household',
              'Online Shopping',
              'Department Store',
            ];
    }
    if (catName.contains('nhà') ||
        catName.contains('điện') ||
        catName.contains('nước') ||
        catName.contains('hóa đơn') ||
        catName.contains('rent') ||
        catName.contains('housing') ||
        catName.contains('bill')) {
      return isVi
          ? const [
              'Tiền điện',
              'Tiền nước',
              'Internet',
              'Tiền phòng / nhà',
              'Dịch vụ số',
            ]
          : const [
              'Electricity Bill',
              'Water Bill',
              'Internet & Wifi',
              'Rent Payment',
              'Digital Subscription',
            ];
    }
    if (catName.contains('giải trí') ||
        catName.contains('chơi') ||
        catName.contains('game') ||
        catName.contains('movie') ||
        catName.contains('entertain')) {
      return isVi
          ? const [
              'Xem phim',
              'Du lịch',
              'Game / Net',
              'Sách / Khóa học',
              'Gặp bạn bè',
            ]
          : const [
              'Movie Tickets',
              'Travel',
              'Games & Gaming',
              'Books & Learning',
              'Outing with Friends',
            ];
    }
    if (catName.contains('sức khỏe') ||
        catName.contains('thuốc') ||
        catName.contains('y tế') ||
        catName.contains('med') ||
        catName.contains('gym') ||
        catName.contains('health')) {
      return isVi
          ? const [
              'Mua thuốc',
              'Khám bệnh',
              'Gym / Thể thao',
              'Thực phẩm bổ sung',
            ]
          : const [
              'Pharmacy / Medicine',
              'Doctor Visit',
              'Gym & Fitness',
              'Vitamins & Supplements',
            ];
    }

    return isVi
        ? const [
            'Ăn uống',
            'Cà phê',
            'Đổ xăng',
            'Mua sắm',
            'Gia đình',
            'Chi tiêu khác',
          ]
        : const [
            'Food & Dining',
            'Coffee',
            'Fuel',
            'Shopping',
            'Family',
            'Other Expense',
          ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final allTxs =
        ref.watch(transactionsStreamProvider).value ?? const <TransactionEntity>[];
    final fallbackSuggestions = _getCategorySuggestedNotes(isVi: isVi);

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
          ListenableBuilder(
            listenable: Listenable.merge([
              noteController,
              ?amountController,
            ]),
            builder: (context, _) {
              final enteredAmountMinor = amountController != null
                  ? (Money.tryParse(
                        amountController!.text,
                        currencyCode: currencyCode,
                      )?.minorUnits ??
                      0)
                  : 0;
              final suggestions = buildSmartNoteSuggestions(
                transactions: allTxs,
                type: type,
                selectedCategory: selectedCategory,
                enteredAmountMinor: enteredAmountMinor,
                currencyCode: currencyCode,
                currentQuery: noteController.text,
                fallbackSuggestions: fallbackSuggestions,
              );
              final currentNoteLower = noteController.text.trim().toLowerCase();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in suggestions)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _SuggestionChip(
                          suggestion: item,
                          isSelected: currentNoteLower.isNotEmpty &&
                              currentNoteLower == item.note.toLowerCase(),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            noteController.value = TextEditingValue(
                              text: item.note,
                              selection: TextSelection.collapsed(
                                offset: item.note.length,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final SmartNoteSuggestion suggestion;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color? borderColor;
    final Color textColor;

    if (isSelected) {
      bgColor = AppleTokens.systemTeal.withValues(alpha: isDark ? 0.26 : 0.14);
      borderColor = AppleTokens.systemTeal.withValues(alpha: 0.55);
      textColor = isDark ? const Color(0xFF5CE1E6) : const Color(0xFF0A8494);
    } else if (suggestion.isExactMatch) {
      bgColor = AppleTokens.systemTeal.withValues(alpha: isDark ? 0.16 : 0.08);
      borderColor = AppleTokens.systemTeal.withValues(alpha: 0.28);
      textColor = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E);
    } else {
      bgColor = isDark
          ? AppleTokens.bgDarkSecondary
          : AppleTokens.bgLightSecondary;
      borderColor = suggestion.isFromHistory
          ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
          : null;
      textColor = isDark
          ? const Color(0xFFE5E5EA)
          : const Color(0xFF3A3A3C);
    }

    return ApplePressable(
      scaleDown: 0.93,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 0.7)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suggestion.isFromHistory) ...[
              Icon(
                Icons.history_rounded,
                size: 12,
                color: isSelected || suggestion.isExactMatch
                    ? AppleTokens.systemTeal
                    : AppleTokens.systemGray,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                suggestion.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected || suggestion.isExactMatch
                          ? FontWeight.w600
                          : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
