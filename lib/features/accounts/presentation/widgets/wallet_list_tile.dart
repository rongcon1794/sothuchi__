import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';

/// Apple HIG & Lucian styled card displaying a single wallet/account.
/// Features squircle badge, default indicator, tabular financial figures, and context actions.
class WalletListTile extends StatelessWidget {
  const WalletListTile({
    super.key,
    required this.account,
    required this.typeLabel,
    required this.locale,
    required this.hideBalance,
    required this.onTap,
    required this.onEdit,
    required this.onToggleArchive,
    this.isDefault = false,
    this.onSetDefault,
    this.onDelete,
  });

  final Account account;
  final String typeLabel;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  IconData _typeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.qr_code_2_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isVi = locale.startsWith('vi');

    final walletColor = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );

    final balanceText = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: onTap,
      child: AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: isDefault
            ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.45 : 0.35)
            : (isDark ? Colors.white.withValues(alpha: 0.10) : AppleTokens.borderLight),
        boxShadow: isDefault
            ? [
                BoxShadow(
                  color: const Color(0xFFFFB800).withValues(alpha: isDark ? 0.12 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Squircle Icon Badge with gradient & soft elevation
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    walletColor,
                    Color.lerp(
                      walletColor,
                      Colors.black,
                      isDark ? 0.30 : 0.18,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.45),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: walletColor.withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                AppIconCatalog.resolve(account.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Middle Content (Name, Badges, Type, Balance)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Name + Badges
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            letterSpacing: -0.2,
                            decoration: account.archived
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800).withValues(alpha: isDark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: const Color(0xFFFFB800).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.star_fill,
                                size: 10,
                                color: Color(0xFFFF9500),
                              ),
                              const SizedBox(width: 2.5),
                              Text(
                                isVi ? 'Mặc định' : 'Default',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFFCC00) : const Color(0xFFB45309),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (account.archived) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppleTokens.rubyExpense.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            l10n.archivedWallets,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.rubyExpense,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Line 2: Type info & Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _typeIcon(account.type),
                            size: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$typeLabel • ${account.currency.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          balanceText,
                          semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // 3. Apple 3-dots Context Menu Button
            ApplePopupMenuButton<String>(
              tooltip: l10n.moreOptions,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onToggleArchive();
                if (value == 'set_default') onSetDefault?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                if (!isDefault && onSetDefault != null)
                  ApplePopupMenuItem(
                    value: 'set_default',
                    icon: CupertinoIcons.star_fill,
                    title: isVi ? 'Đặt làm ví mặc định' : 'Set as default',
                  ),
                ApplePopupMenuItem(
                  value: 'edit',
                  icon: CupertinoIcons.pencil,
                  title: l10n.edit,
                ),
                ApplePopupMenuItem(
                  value: 'archive',
                  icon: account.archived
                      ? CupertinoIcons.arrow_counterclockwise
                      : CupertinoIcons.archivebox,
                  title: account.archived
                      ? l10n.unarchiveWallet
                      : l10n.archiveWallet,
                ),
                if (onDelete != null)
                  ApplePopupMenuItem(
                    value: 'delete',
                    icon: CupertinoIcons.trash,
                    title: l10n.delete,
                    isDestructive: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
