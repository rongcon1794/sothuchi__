import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';

class TransactionWalletPickerSheet extends StatelessWidget {
  const TransactionWalletPickerSheet({
    super.key,
    required this.wallets,
    required this.selectedId,
    required this.locale,
    required this.title,
    this.onCreateNew,
    this.defaultWalletId,
  });

  final List<Account> wallets;
  final String? selectedId;
  final String locale;
  final String title;
  final VoidCallback? onCreateNew;
  final String? defaultWalletId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled = context.isOled;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: isOled
            ? AppleTokens.bgOledCard
            : (isDark ? AppleTokens.bgDarkCard : Colors.white),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusSheet),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (onCreateNew != null) ...[
                      ApplePressable(
                        scaleDown: 0.92,
                        onTap: () {
                          Navigator.of(context).pop();
                          onCreateNew!();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.plus,
                                  size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                locale.startsWith('vi')
                                    ? 'Thêm ví'
                                    : 'Add wallet',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill,
                          color: AppleTokens.systemGray),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppleTokens.hairline),
              Expanded(
                child: wallets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.creditcard,
                                  size: 48, color: AppleTokens.systemGray),
                              const SizedBox(height: 12),
                              Text(
                                locale.startsWith('vi')
                                    ? 'Chưa có ví tiền nào'
                                    : 'No wallets available',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (onCreateNew != null)
                                AppleButton.primary(
                                  label: locale.startsWith('vi')
                                      ? 'Tạo ví mới ngay'
                                      : 'Create new wallet',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    onCreateNew!();
                                  },
                                ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: wallets.length + (onCreateNew != null ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(
                            indent: 56, height: AppleTokens.hairline),
                        itemBuilder: (context, index) {
                          if (onCreateNew != null && index == 0) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              leading: AppleSquircleBadge(
                                icon: CupertinoIcons.plus,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: isDark ? 0.25 : 0.12),
                                iconColor: theme.colorScheme.primary,
                                size: 40,
                                iconSize: 20,
                              ),
                              title: Text(
                                locale.startsWith('vi')
                                    ? 'Thêm ví mới...'
                                    : 'Add new wallet...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                                onCreateNew!();
                              },
                            );
                          }

                          final actualIndex =
                              onCreateNew != null ? index - 1 : index;
                          final wallet = wallets[actualIndex];
                          final isSelected = wallet.id == selectedId;
                          final walletColor = Color(wallet.color);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            leading: AppleSquircleBadge(
                              icon: AppIconCatalog.resolve(wallet.icon),
                              backgroundColor: walletColor,
                              size: 40,
                              iconSize: 20,
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    wallet.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (wallet.id == defaultWalletId) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB800)
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill),
                                      border: Border.all(
                                        color: const Color(0xFFFFB800)
                                            .withValues(alpha: 0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star_rounded,
                                            size: 10, color: Color(0xFFFFB800)),
                                        SizedBox(width: 2),
                                        Text(
                                          'Mặc định',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFFB800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              wallet.balanceMoney.format(locale: locale),
                              style: TextStyle(
                                fontFeatures: AppTheme.tabularFigures,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6C6C70),
                              ),
                            ),
                            trailing: isSelected
                              ? Icon(CupertinoIcons.checkmark_circle_fill,
                                  color: theme.colorScheme.primary)
                              : null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).pop(wallet.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
