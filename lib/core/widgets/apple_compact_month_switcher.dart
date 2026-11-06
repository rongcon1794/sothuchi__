import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Highly compact Apple HIG month switcher widget.
///
/// Supports two rendering modes:
/// 1. [isHeaderMode] = true: Ultra-compact 26dp pill designed for AppBar actions in landscape.
/// 2. [isHeaderMode] = false: Modern compact 32dp centered capsule for portrait body,
///    replacing bulky full-width cards.
///
/// Tapping the month text opens [AppleMonthYearPickerSheet] for direct 1-tap month/year picking,
/// while the left/right chevrons allow quick single-month stepping.
class AppleCompactMonthSwitcher extends StatelessWidget {
  const AppleCompactMonthSwitcher({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectMonth,
    this.allowAllOption = false,
    this.isHeaderMode = false,
  });

  /// The currently selected month anchor (or null for all time).
  final DateTime? selectedMonth;

  /// Invoked when stepping back one month.
  final VoidCallback onPrevious;

  /// Invoked when stepping forward one month.
  final VoidCallback onNext;

  /// Invoked when a direct month is picked or cleared via sheet.
  final ValueChanged<DateTime?> onSelectMonth;

  /// Whether the picker sheet should provide "All time" option.
  final bool allowAllOption;

  /// When true, renders at 26dp height for AppBar actions.
  final bool isHeaderMode;

  void _openPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    AppleMonthYearPickerSheet.show(
      context,
      initialMonth: selectedMonth,
      allowAllOption: allowAllOption,
      onMonthSelected: onSelectMonth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final primaryColor = theme.colorScheme.primary;

    final monthLabel = selectedMonth != null
        ? AppDateUtils.formatMonthYear(selectedMonth!, locale: locale)
        : l10n.all;

    if (isHeaderMode) {
      // 26dp height pill for AppBar actions in landscape
      return AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        child: SizedBox(
          height: 26,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.previousMonth,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 24),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onPrevious();
                },
                icon: const Icon(Icons.chevron_left_rounded, size: 16),
              ),
              ApplePressable(
                onTap: () => _openPicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 9,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.nextMonth,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 24),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onNext();
                },
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
              ),
            ],
          ),
        ),
      );
    }

    // 32dp height centered capsule for portrait body
    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.previousMonth,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                HapticFeedback.selectionClick();
                onPrevious();
              },
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
            ),
            ApplePressable(
              onTap: () => _openPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 13,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.nextMonth,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                HapticFeedback.selectionClick();
                onNext();
              },
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
