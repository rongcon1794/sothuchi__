import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';

/// Apple Human Interface Guidelines sheet for selecting the default expense wallet.
class DefaultWalletPickerSheet extends StatelessWidget {
  const DefaultWalletPickerSheet({
    super.key,
    required this.wallets,
    required this.currentDefaultId,
    required this.onSelected,
    this.locale = 'vi',
  });

  final List<Account> wallets;
  final String? currentDefaultId;
  final ValueChanged<String?> onSelected;
  final String locale;

  static Future<void> show({
    required BuildContext context,
    required List<Account> wallets,
    required String? currentDefaultId,
    required ValueChanged<String?> onSelected,
    String locale = 'vi',
  }) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => DefaultWalletPickerSheet(
        wallets: wallets,
        currentDefaultId: currentDefaultId,
        onSelected: onSelected,
        locale: locale,
      ),
    );
  }

  String _formatType(AccountType type, BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      AccountType.cash => l10n.walletTypeCash,
      AccountType.bank => l10n.walletTypeBank,
      AccountType.ewallet => l10n.walletTypeEwallet,
      AccountType.card => l10n.walletTypeCard,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const goldColor = Color(0xFFFFB800);

    final currentDefault = wallets.where((w) => w.id == currentDefaultId).firstOrNull;

    return AppleModalSheetLayout(
      title: 'Ví mặc định chi tiêu',
      subtitle: 'Tự động chọn sẵn mỗi khi bạn thêm khoản thu chi mới',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glassmorphic Info Banner
          AppleGlassCard(
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            padding: const EdgeInsets.all(14),
            borderColor: goldColor.withValues(alpha: isDark ? 0.35 : 0.25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      goldColor.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.45),
                    ]
                  : [
                      goldColor.withValues(alpha: 0.12),
                      Colors.white,
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: isDark ? 0.25 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: goldColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiết kiệm thao tác nhập liệu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Các giao dịch mới sẽ tự động dùng số dư và tiền tệ của ví này giúp bạn ghi chép nhanh hơn.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppleTokens.systemGray,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Active Default Hero Card
          if (currentDefault != null) ...[
            Text(
              'VÍ ĐANG ĐƯỢC CHỌN MẶC ĐỊNH',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppleTokens.systemGray,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                color: isDark
                    ? goldColor.withValues(alpha: 0.12)
                    : goldColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: goldColor.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(currentDefault.color).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Color(currentDefault.color).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      AppIconCatalog.resolve(currentDefault.icon),
                      color: AppIconCatalog.contrastSafeColor(
                        Color(currentDefault.color),
                        theme.brightness,
                      ),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentDefault.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                border: Border.all(
                                  color: goldColor.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 12, color: goldColor),
                                  SizedBox(width: 3),
                                  Text(
                                    'MẶC ĐỊNH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: goldColor,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Số dư: ${currentDefault.balanceMoney.format(locale: locale)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            fontFeatures: AppTheme.tabularFigures,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Wallets List Header
          Text(
            'TẤT CẢ VÍ & TÀI KHOẢN (${wallets.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppleTokens.systemGray,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),

          // Wallets List
          for (final w in wallets) ...[
            Builder(
              builder: (context) {
                final isSelected = w.id == currentDefaultId;
                final walletColor = AppIconCatalog.contrastSafeColor(
                  Color(w.color),
                  theme.brightness,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ApplePressable(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      onSelected(w.id);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chọn "${w.name}" làm ví mặc định chi tiêu'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: AppleGlassCard(
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      borderColor: isSelected
                          ? goldColor.withValues(alpha: 0.65)
                          : null,
                      child: Row(
                        children: [
                          // Squircle Badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: walletColor.withValues(alpha: isDark ? 0.22 : 0.14),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: walletColor.withValues(alpha: isDark ? 0.40 : 0.28),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(w.icon),
                              color: walletColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name and Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: isSelected && !isDark ? theme.textTheme.titleMedium?.color : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                      ),
                                      child: Text(
                                        _formatType(w.type, context),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.systemGray,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      w.balanceMoney.format(locale: locale),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: AppTheme.tabularFigures,
                                        color: AppleTokens.systemGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Selection Radio / Checkmark
                          if (isSelected)
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: goldColor,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                            )
                          else
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.20),
                                  width: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 8),

          // Option: Không đặt ví mặc định (Manual Selection)
          Builder(
            builder: (context) {
              final isNone = currentDefaultId == null || currentDefaultId!.isEmpty;

              return ApplePressable(
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  onSelected(null);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã hủy ví mặc định. Bạn sẽ chọn ví thủ công khi tạo giao dịch.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: AppleGlassCard(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderColor: isNone ? AppleTokens.systemBlue.withValues(alpha: 0.5) : null,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppleTokens.systemGray.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          CupertinoIcons.clear_circled,
                          color: AppleTokens.systemGray,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Không đặt ví mặc định',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Chọn thủ công ví tiền mỗi khi ghi chép',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppleTokens.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isNone)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppleTokens.systemBlue,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Quick Button: Thêm ví mới
          AppleButton.secondary(
            onPressed: () async {
              unawaited(HapticFeedback.lightImpact());
              final created = await WalletFormSheet.show(context);
              if (created != null && context.mounted) {
                onSelected(created.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã tạo và đặt "${created.name}" làm ví mặc định chi tiêu'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(CupertinoIcons.plus, size: 16),
            label: '+ Thêm ví mới...',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

