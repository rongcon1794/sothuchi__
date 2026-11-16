import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';

/// Modal bottom sheet providing one-tap smart wallet sorting strategies and manual drag-and-drop.
class SmartWalletSortSheet extends StatelessWidget {
  const SmartWalletSortSheet({
    super.key,
    required this.activeAccounts,
    required this.defaultWalletId,
    required this.locale,
    required this.onApplyOrder,
    required this.onStartManualReorder,
  });

  final List<Account> activeAccounts;
  final String? defaultWalletId;
  final String locale;
  final ValueChanged<List<String>> onApplyOrder;
  final VoidCallback onStartManualReorder;

  static Future<void> show({
    required BuildContext context,
    required List<Account> activeAccounts,
    required String? defaultWalletId,
    required String locale,
    required ValueChanged<List<String>> onApplyOrder,
    required VoidCallback onStartManualReorder,
  }) {
    return AppleModalSheetLayout.show<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => SmartWalletSortSheet(
        activeAccounts: activeAccounts,
        defaultWalletId: defaultWalletId,
        locale: locale,
        onApplyOrder: onApplyOrder,
        onStartManualReorder: onStartManualReorder,
      ),
    );
  }

  void _applySort(BuildContext context, List<String> orderedIds, String message) {
    unawaited(HapticFeedback.mediumImpact());
    onApplyOrder(orderedIds);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isVi = locale.startsWith('vi');

    return AppleModalSheetLayout(
      title: isVi ? 'Sắp xếp ví & tài khoản' : 'Sort & Reorder Wallets',
      subtitle: isVi
          ? 'Thứ tự sắp xếp sẽ tự động đồng bộ ở Trang chủ, Ghi thu chi và Chuyển tiền'
          : 'Order syncs across Home, New Transaction, and Transfer',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
          // 1. Default wallet first
          _SortOptionCard(
            icon: CupertinoIcons.star_fill,
            iconColor: const Color(0xFFFF9500),
            title: isVi ? 'Ví mặc định lên đầu' : 'Default wallet first',
            subtitle: isVi
                ? 'Đưa ví chi tiêu mặc định lên vị trí đầu tiên'
                : 'Places default spending wallet at the top (#1)',
            isDark: isDark,
            onTap: () {
              final list = List<Account>.from(activeAccounts);
              list.sort((a, b) {
                if (a.id == defaultWalletId) return -1;
                if (b.id == defaultWalletId) return 1;
                return 0;
              });
              _applySort(
                context,
                list.map((a) => a.id).toList(),
                isVi ? 'Đã đưa ví mặc định lên đầu' : 'Default wallet moved to top',
              );
            },
          ),
          const SizedBox(height: 10),

          // 2. Balance: High to Low
          _SortOptionCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppleTokens.jadePrimary,
            title: isVi ? 'Số dư: Cao nhất → Thấp nhất' : 'Balance: High to Low',
            subtitle: isVi
                ? 'Sắp xếp từ ví có nhiều tiền nhất đến ít nhất'
                : 'Wallets with highest balance appear first',
            isDark: isDark,
            onTap: () {
              final list = List<Account>.from(activeAccounts)
                ..sort((a, b) => b.balance.compareTo(a.balance));
              _applySort(
                context,
                list.map((a) => a.id).toList(),
                isVi ? 'Đã sắp xếp: Số dư cao nhất đến thấp nhất' : 'Sorted: Balance high to low',
              );
            },
          ),
          const SizedBox(height: 10),

          // 3. Balance: Low to High
          _SortOptionCard(
            icon: Icons.trending_down_rounded,
            iconColor: AppleTokens.systemTeal,
            title: isVi ? 'Số dư: Thấp nhất → Cao nhất' : 'Balance: Low to High',
            subtitle: isVi
                ? 'Sắp xếp từ ví ít tiền nhất lên đầu'
                : 'Wallets with lowest balance appear first',
            isDark: isDark,
            onTap: () {
              final list = List<Account>.from(activeAccounts)
                ..sort((a, b) => a.balance.compareTo(b.balance));
              _applySort(
                context,
                list.map((a) => a.id).toList(),
                isVi ? 'Đã sắp xếp: Số dư thấp nhất đến cao nhất' : 'Sorted: Balance low to high',
              );
            },
          ),
          const SizedBox(height: 10),

          // 4. By Wallet Type
          _SortOptionCard(
            icon: CupertinoIcons.creditcard_fill,
            iconColor: AppleTokens.systemPurple,
            title: isVi ? 'Theo loại ví' : 'Group by wallet type',
            subtitle: isVi
                ? 'Tiền mặt → Ngân hàng → Ví điện tử → Thẻ'
                : 'Cash → Bank → E-wallet → Card',
            isDark: isDark,
            onTap: () {
              const typeOrder = [
                AccountType.cash,
                AccountType.bank,
                AccountType.ewallet,
                AccountType.card,
              ];
              final list = List<Account>.from(activeAccounts)
                ..sort((a, b) {
                  final orderA = typeOrder.indexOf(a.type);
                  final orderB = typeOrder.indexOf(b.type);
                  if (orderA != orderB) return orderA.compareTo(orderB);
                  return b.balance.compareTo(a.balance);
                });
              _applySort(
                context,
                list.map((a) => a.id).toList(),
                isVi ? 'Đã sắp xếp theo phân loại ví' : 'Sorted by wallet type',
              );
            },
          ),
          const SizedBox(height: 10),

          // 5. Alphabetical A-Z
          _SortOptionCard(
            icon: CupertinoIcons.textformat_abc,
            iconColor: AppleTokens.systemBlue,
            title: isVi ? 'Tên ví: A → Z' : 'Wallet name: A → Z',
            subtitle: isVi
                ? 'Sắp xếp theo thứ tự bảng chữ cái'
                : 'Sort alphabetically by name',
            isDark: isDark,
            onTap: () {
              final list = List<Account>.from(activeAccounts)
                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              _applySort(
                context,
                list.map((a) => a.id).toList(),
                isVi ? 'Đã sắp xếp theo tên A-Z' : 'Sorted by name A-Z',
              );
            },
          ),
          const SizedBox(height: 10),

          // 6. Manual Drag & Drop
          _SortOptionCard(
            icon: CupertinoIcons.arrow_up_arrow_down,
            iconColor: AppleTokens.systemGray,
            title: isVi ? 'Kéo và thả thủ công' : 'Custom Drag & Drop',
            subtitle: isVi
                ? 'Tự do di chuyển từng ví theo ý thích'
                : 'Manually drag and drop wallets in any order',
            isDark: isDark,
            isHighlighted: true,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              Navigator.of(context).pop();
              onStartManualReorder();
            },
          ),
          const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SortOptionCard extends StatelessWidget {
  const _SortOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ApplePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: isHighlighted
            ? AppleTokens.systemBlue.withValues(alpha: isDark ? 0.35 : 0.25)
            : (isDark ? Colors.white.withValues(alpha: 0.10) : AppleTokens.borderLight),
        child: Row(
          children: [
            AppleSquircleBadge(
              icon: icon,
              backgroundColor: iconColor,
              size: 38,
              iconSize: 20,
              radius: 11,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppleTokens.systemGray,
            ),
          ],
        ),
      ),
    );
  }
}
