import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Apple HIG Month & Year direct picker modal bottom sheet.
///
/// Allows 1-tap direct selection of any specific month (1..12) and year,
/// eliminating the need to sequentially step through individual months.
class AppleMonthYearPickerSheet extends StatefulWidget {
  const AppleMonthYearPickerSheet({
    super.key,
    this.initialMonth,
    required this.onMonthSelected,
    this.allowAllOption = false,
  });

  /// The currently selected month anchor (or null for "all time").
  final DateTime? initialMonth;

  /// Callback when a month is chosen or cleared (null for all time).
  final ValueChanged<DateTime?> onMonthSelected;

  /// Whether to display an option for "All Time" (e.g. For transactions filter).
  final bool allowAllOption;

  /// Displays the picker sheet modally with Apple HIG bottom sheet styling.
  static Future<void> show(
    BuildContext context, {
    DateTime? initialMonth,
    required ValueChanged<DateTime?> onMonthSelected,
    bool allowAllOption = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppleMonthYearPickerSheet(
        initialMonth: initialMonth,
        onMonthSelected: onMonthSelected,
        allowAllOption: allowAllOption,
      ),
    );
  }

  @override
  State<AppleMonthYearPickerSheet> createState() => _AppleMonthYearPickerSheetState();
}

class _AppleMonthYearPickerSheetState extends State<AppleMonthYearPickerSheet> {
  late int _displayYear;
  late int? _selectedMonth;
  late int? _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.initialMonth != null) {
      _displayYear = widget.initialMonth!.year;
      _selectedYear = widget.initialMonth!.year;
      _selectedMonth = widget.initialMonth!.month;
    } else {
      _displayYear = now.year;
      _selectedYear = null;
      _selectedMonth = null;
    }
  }

  void _onMonthTap(int month) {
    unawaited(HapticFeedback.lightImpact());
    final picked = DateTime(_displayYear, month, 1);
    widget.onMonthSelected(picked);
    Navigator.of(context).pop();
  }

  void _onSelectAllTime() {
    unawaited(HapticFeedback.lightImpact());
    widget.onMonthSelected(null);
    Navigator.of(context).pop();
  }

  void _onSelectCurrentMonth() {
    unawaited(HapticFeedback.lightImpact());
    final now = DateTime.now();
    widget.onMonthSelected(DateTime(now.year, now.month, 1));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final isVi = locale.startsWith('vi');
    final now = DateTime.now();
    final primaryColor = theme.colorScheme.primary;

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;

    // Subtitle text
    final String subtitle;
    if (_selectedYear != null && _selectedMonth != null) {
      subtitle = AppDateUtils.formatMonthYear(
        DateTime(_selectedYear!, _selectedMonth!, 1),
        locale: locale,
      );
    } else {
      subtitle = isVi ? 'Tất cả các tháng' : 'All time';
    }

    return AppleModalSheetLayout(
      title: isVi ? 'Chọn thời gian' : 'Select Month',
      subtitle: subtitle,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick shortcuts row
          Row(
            children: [
              if (widget.allowAllOption) ...[
                Expanded(
                  child: _buildShortcutChip(
                    label: isVi ? 'Toàn thời gian' : 'All time',
                    isSelected: _selectedYear == null && _selectedMonth == null,
                    icon: CupertinoIcons.infinite,
                    onTap: _onSelectAllTime,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _buildShortcutChip(
                  label: isVi ? 'Tháng này' : 'This Month',
                  isSelected: _selectedYear == now.year && _selectedMonth == now.month,
                  icon: CupertinoIcons.calendar_today,
                  onTap: _onSelectCurrentMonth,
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Year Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                width: AppleTokens.hairline,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: isVi ? 'Năm trước' : 'Previous Year',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _displayYear--);
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isVi ? 'Năm $_displayYear' : 'Year $_displayYear',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_displayYear != now.year) ...[
                      const SizedBox(width: 8),
                      ApplePressable(
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          setState(() => _displayYear = now.year);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            isVi ? 'Về ${now.year}' : 'Reset ${now.year}',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  tooltip: isVi ? 'Năm sau' : 'Next Year',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                  onPressed: () {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _displayYear++);
                  },
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 12 Months Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLandscape ? 4 : 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: isLandscape ? 2.4 : 2.0,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = _selectedYear == _displayYear && _selectedMonth == month;
              final isCurrent = now.year == _displayYear && now.month == month;

              // Format Month name
              final String monthName;
              if (isVi) {
                monthName = 'Tháng $month';
              } else {
                monthName = DateFormat('MMMM', locale).format(DateTime(_displayYear, month, 1));
              }

              return ApplePressable(
                onTap: () => _onMonthTap(month),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isCurrent
                              ? primaryColor.withValues(alpha: 0.6)
                              : (isDark
                                  ? AppleTokens.separatorDark
                                  : AppleTokens.separatorLight)),
                      width: isCurrent && !isSelected ? 1.5 : AppleTokens.hairline,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: -0.2,
                            color: isSelected
                                ? Colors.white
                                : (isCurrent
                                    ? primaryColor
                                    : (isDark ? Colors.white : Colors.black87)),
                          ),
                        ),
                        if (isCurrent && !isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    required bool isDark,
  }) {
    return ApplePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.16)
              : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary),
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight),
            width: isSelected ? 1.2 : AppleTokens.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
