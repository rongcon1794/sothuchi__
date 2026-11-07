import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

/// 3-State Sliding Segmented Pill for Transaction Type with Semantic Accent Color.
class TransactionTypeSegmentedPill extends StatelessWidget {
  const TransactionTypeSegmentedPill({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = context.l10n;
    final segments = [
      (
        type: TransactionType.expense,
        label: l10n.expense,
        icon: CupertinoIcons.arrow_up_right,
        color: AppleTokens.rubyExpense,
      ),
      (
        type: TransactionType.income,
        label: l10n.income,
        icon: CupertinoIcons.arrow_down_left,
        color: AppleTokens.jadePrimary,
      ),
      (
        type: TransactionType.transfer,
        label: l10n.transfer,
        icon: CupertinoIcons.arrow_right_arrow_left,
        color: AppleTokens.cobaltTransfer,
      ),
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      ),
      child: Row(
        children: [
          for (final item in segments)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (item.type != selected) {
                    HapticFeedback.selectionClick();
                    onChanged(item.type);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.type == selected
                        ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    boxShadow: item.type == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 15,
                        color: item.type == selected
                            ? item.color
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.type == selected ? FontWeight.w700 : FontWeight.w500,
                          color: item.type == selected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
