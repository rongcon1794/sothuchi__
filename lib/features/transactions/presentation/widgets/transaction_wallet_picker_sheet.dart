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
  });

  final List<Account> wallets;
  final String? selectedId;
  final String locale;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkCard : Colors.white,
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
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: wallets.length,
                  separatorBuilder: (_, _) =>
                      const Divider(indent: 56, height: AppleTokens.hairline),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
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
                      title: Text(
                        wallet.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 16,
                        ),
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
