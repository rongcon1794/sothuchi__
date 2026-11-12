import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Interactive Apple HIG date picker tile.
/// Displays an iOS-style squircle calendar badge, label, and formatted date,
/// and triggers a themed DatePicker on tap with tactile feedback.
class AppleDatePickerTile extends StatelessWidget {
  const AppleDatePickerTile({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label,
    this.firstDate,
    this.lastDate,
    this.locale = 'vi',
    this.icon = CupertinoIcons.calendar,
    this.iconColor = AppleTokens.systemBlue,
    this.backgroundColor,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String locale;
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;

  Future<void> _pickDate(BuildContext context) async {
    unawaited(HapticFeedback.selectionClick());
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 10),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.primary,
                    surface: AppleTokens.bgDarkCard,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      unawaited(HapticFeedback.lightImpact());
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final isVi = locale.toLowerCase().startsWith('vi');
    final effectiveLabel = label ?? (isVi ? 'Ngày' : 'Date');
    final formattedDate = AppDateUtils.formatFullDate(selectedDate, locale: locale);
    final displayText = isToday
        ? '${isVi ? 'Hôm nay' : 'Today'}, $formattedDate'
        : formattedDate;

    final bg = backgroundColor ??
        (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary);

    return ApplePressable(
      onTap: () => _pickDate(context),
      scaleDown: 0.98,
      borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: AppleTokens.hairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    effectiveLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6C6C70),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}
