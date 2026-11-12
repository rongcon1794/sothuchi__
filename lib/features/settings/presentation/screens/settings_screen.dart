import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/widgets/default_wallet_picker_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exportingCsv = false;

  Future<void> _handleToggleBiometric(bool enable) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    if (enable) {
      final available = await settingsNotifier.isBiometricAvailable();
      if (!available) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.biometricNotAvailable)),
        );
        return;
      }
      final authenticated = await settingsNotifier.authenticateBiometric(
        localizedReason: l10n.biometricPromptReason,
      );
      if (!authenticated) return;
    }

    final res = await settingsNotifier.updateBiometricLock(enable);
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _handleExportCsv() async {
    if (_exportingCsv) return;
    setState(() => _exportingCsv = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await ref
          .read(settingsControllerProvider.notifier)
          .exportTransactionsCsv(subject: '${l10n.appTitle} - CSV');

      if (!mounted) return;
      res.fold(
        onSuccess: (count) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.exportCsvSuccess(count))),
          );
        },
        onFailure: (err) {
          messenger.showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _exportingCsv = false);
      }
    }
  }

  Future<void> _pickLanguage(String current) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusHero)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.language,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              AppleGlassCard(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Text('🇻🇳', style: TextStyle(fontSize: 22)),
                      title: Text(l10n.languageVietnamese, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: current == 'vi'
                          ? Icon(CupertinoIcons.checkmark_alt_circle_fill, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop('vi'),
                    ),
                    Divider(height: AppleTokens.hairline, indent: 56, color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight),
                    ListTile(
                      leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                      title: Text(l10n.languageEnglish, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: current == 'en'
                          ? Icon(CupertinoIcons.checkmark_alt_circle_fill, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(ctx).pop('en'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    await ref.read(settingsControllerProvider.notifier).updateLocale(picked);
  }

  Future<void> _pickCurrency(String current) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppleTokens.radiusHero)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.defaultCurrency,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              AppleGlassCard(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: Column(
                  children: [
                    for (int i = 0; i < AppCurrencies.supported.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: AppleTokens.hairline,
                          indent: 56,
                          color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                        ),
                      ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppleTokens.systemYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            AppCurrencies.supported[i].symbol,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppleTokens.systemOrange),
                          ),
                        ),
                        title: Text(
                          '${AppCurrencies.supported[i].code} (${AppCurrencies.supported[i].symbol})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.localeName.startsWith('vi')
                              ? AppCurrencies.supported[i].nameVi
                              : AppCurrencies.supported[i].nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: current == AppCurrencies.supported[i].code
                            ? Icon(CupertinoIcons.checkmark_alt_circle_fill, color: theme.colorScheme.primary)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(AppCurrencies.supported[i].code),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    await ref.read(settingsControllerProvider.notifier).updateCurrency(picked);
  }

  Future<void> _confirmSignOut() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref.read(authActionControllerProvider.notifier).signOut();
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAccountAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(authActionControllerProvider.notifier)
        .deleteAccountAndAllData();
    if (!mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _showDefaultWalletPicker(
    BuildContext context,
    List<Account> wallets,
    String? currentDefaultId,
    String locale,
  ) async {
    if (wallets.isEmpty) {
      final isVi = locale.toLowerCase().startsWith('vi');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVi ? 'Chưa có ví tiền nào để chọn' : 'No wallets available to select',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await DefaultWalletPickerSheet.show(
      context: context,
      wallets: wallets,
      currentDefaultId: currentDefaultId,
      locale: locale,
      onSelected: (walletId) async {
        await ref
            .read(settingsControllerProvider.notifier)
            .setDefaultWalletId(walletId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ?? const AppSettings();
    final authBusy = ref.watch(authActionControllerProvider).isLoading;
    final activeCurrencyInfo = AppCurrencies.byCode(settings.currencyCode);

    final activeWallets = ref.watch(activeAccountsProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final debtsAsync = ref.watch(debtsStreamProvider);
    final unsettledDebtsCount = (debtsAsync.value ?? const [])
        .where((d) => !d.isSettled)
        .length;

    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 20
        : AppleTokens.scrollBottomPaddingNoFab;

    final profileCard = user != null
        ? AppleGlassCard(
            padding: EdgeInsets.all(isLandscape ? 12 : 16),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Row(
              children: [
                AppleUserAvatar(
                  photoUrl: user.photoUrl,
                  displayName: user.displayName,
                  email: user.email,
                  size: isLandscape ? 44 : 52,
                  borderRadius: isLandscape ? 14 : 16,
                ),
                SizedBox(width: isLandscape ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isLandscape ? 15 : 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: isLandscape ? 11 : 12,
                        ),
                      ),
                      SizedBox(height: isLandscape ? 3 : 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isDemoUser
                              ? AppleTokens.systemOrange.withValues(alpha: 0.14)
                              : AppleTokens.systemGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isDemoUser
                                  ? CupertinoIcons.device_phone_portrait
                                  : CupertinoIcons.checkmark_seal_fill,
                              size: 10.5,
                              color: user.isDemoUser
                                  ? AppleTokens.systemOrange
                                  : AppleTokens.systemGreen,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.isDemoUser ? l10n.settingsAccountGuest : l10n.settingsAccountGoogle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: user.isDemoUser
                                      ? AppleTokens.systemOrange
                                      : AppleTokens.systemGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quick Action: Sign Out only (safely separated from destructive actions)
                AppleIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: l10n.signOut,
                  size: isLandscape ? 34 : 38,
                  iconSize: isLandscape ? 17 : 19,
                  foregroundColor: AppleTokens.systemOrange,
                  backgroundColor: AppleTokens.systemOrange.withValues(alpha: 0.12),
                  borderColor: AppleTokens.systemOrange.withValues(alpha: 0.22),
                  onTap: authBusy ? null : _confirmSignOut,
                ),
              ],
            ),
          )
        : null;

    final dataSection = AppleListGroup(
      header: l10n.settingsDataAndManagement,
      margin: EdgeInsets.only(bottom: isLandscape ? 14 : 20),
      children: [
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.account_balance_wallet_rounded,
            backgroundColor: AppleTokens.systemGreen,
          ),
          title: Text(l10n.walletsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  isVi ? '${activeWallets.length} ví' : '${activeWallets.length} wallets',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => context.push(AppRoutes.accounts),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.star_rounded,
            backgroundColor: Color(0xFFFFB800),
          ),
          title: Text(
            isVi ? 'Ví mặc định chi tiêu' : 'Default Spending Wallet',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            activeWallets
                    .where((w) => w.id == settings.defaultWalletId)
                    .firstOrNull
                    ?.name ??
                (activeWallets.isNotEmpty
                    ? (isVi ? 'Chưa thiết lập' : 'Not set')
                    : (isVi ? 'Chưa có ví' : 'No wallets')),
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => _showDefaultWalletPicker(
            context,
            activeWallets,
            settings.defaultWalletId,
            settings.localeCode,
          ),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.category_rounded,
            backgroundColor: AppleTokens.systemOrange,
          ),
          title: Text(l10n.categoriesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            isVi
                ? '${expenseCategories.length} khoản chi • ${incomeCategories.length} khoản thu'
                : '${expenseCategories.length} expense • ${incomeCategories.length} income',
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  isVi ? '${categoriesMap.length} mục' : '${categoriesMap.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => context.push(AppRoutes.categories),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: CupertinoIcons.person_2_fill,
            backgroundColor: AppleTokens.systemIndigo,
          ),
          title: Text(l10n.debtsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.settingsDebtsSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unsettledDebtsCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppleTokens.systemIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Text(
                    isVi ? '$unsettledDebtsCount nợ' : '$unsettledDebtsCount open',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppleTokens.systemIndigo,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => context.push(AppRoutes.debts),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: CupertinoIcons.repeat,
            backgroundColor: AppleTokens.systemTeal,
          ),
          title: Text(l10n.recurringTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.settingsRecurringSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => context.push(AppRoutes.recurring),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: CupertinoIcons.cube_box_fill,
            backgroundColor: AppleTokens.systemOrange,
          ),
          title: Text(l10n.savingsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.settingsSavingsSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => context.push(AppRoutes.savings),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: CupertinoIcons.layers_alt_fill,
            backgroundColor: AppleTokens.systemBlue,
          ),
          title: Text(l10n.ledgersTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.settingsLedgersSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => context.push(AppRoutes.ledgers),
        ),
        ListTile(
          dense: isLandscape,
          leading: _exportingCsv
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : const AppleSquircleBadge(
                  icon: Icons.table_view_rounded,
                  backgroundColor: AppleTokens.jadePrimary,
                ),
          title: Text(l10n.exportCsv, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.exportCsvSubtitle, style: const TextStyle(fontSize: 12)),
          trailing: AppleIconButton(
            icon: Icons.ios_share_rounded,
            size: 34,
            iconSize: 18,
            tooltip: l10n.exportCsv,
            foregroundColor: AppleTokens.jadePrimary,
            backgroundColor: AppleTokens.jadePrimary.withValues(alpha: 0.12),
            borderColor: AppleTokens.jadePrimary.withValues(alpha: 0.2),
            onTap: _exportingCsv ? null : _handleExportCsv,
          ),
          onTap: _exportingCsv ? null : _handleExportCsv,
        ),
      ],
    );

    // Section 2: Appearance & Preferences (With Icon Theme Selector)
    final appearanceSection = AppleListGroup(
      header: l10n.appearanceSection,
      margin: EdgeInsets.only(bottom: isLandscape ? 14 : 20),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLandscape ? 8 : 11,
          ),
          child: Row(
            children: [
              const AppleSquircleBadge(
                icon: Icons.palette_rounded,
                backgroundColor: AppleTokens.systemIndigo,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.themeMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isLandscape ? 14 : 15,
                  ),
                ),
              ),
              // Icon-driven Theme Mode Pill (Saves massive screen space)
              AppleIconSegmentedPill<ThemeMode>(
                selected: settings.themeMode,
                height: isLandscape ? 30 : 34,
                onChanged: (mode) => ref
                    .read(settingsControllerProvider.notifier)
                    .updateThemeMode(mode),
                segments: [
                  AppleIconSegment(
                    value: ThemeMode.system,
                    icon: CupertinoIcons.circle_righthalf_fill,
                    tooltip: l10n.themeSystem,
                  ),
                  AppleIconSegment(
                    value: ThemeMode.light,
                    icon: CupertinoIcons.sun_max_fill,
                    tooltip: l10n.themeLight,
                    accentColor: AppleTokens.systemOrange,
                  ),
                  AppleIconSegment(
                    value: ThemeMode.dark,
                    icon: CupertinoIcons.moon_stars_fill,
                    tooltip: l10n.themeDark,
                    accentColor: AppleTokens.systemIndigo,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (settings.themeMode == ThemeMode.dark || (settings.themeMode == ThemeMode.system && isDark))
          ListTile(
            dense: isLandscape,
            leading: const AppleSquircleBadge(
              icon: CupertinoIcons.circle_fill,
              backgroundColor: Colors.black,
            ),
            title: const Text('OLED True Black', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              isVi
                  ? 'Màu đen sâu (#000000) tối ưu pin cho màn hình AMOLED'
                  : 'True black (#000000) saves battery on AMOLED displays',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: CupertinoSwitch(
              value: settings.oledMode,
              activeTrackColor: AppleTokens.systemGreen,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                ref.read(settingsControllerProvider.notifier).updateOledMode(val);
              },
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLandscape ? 8 : 10,
          ),
          child: Row(
            children: [
              const AppleSquircleBadge(
                icon: CupertinoIcons.sparkles,
                backgroundColor: AppleTokens.systemPink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.accentColor,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isLandscape ? 14 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppTheme.localizedPaletteName(
                        settings.accentColorIndex,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: isLandscape ? 6 : 8,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < AppTheme.palettes.length; i++)
                    ApplePressable(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateAccentColor(i);
                      },
                      child: Semantics(
                        label: AppTheme.localizedPaletteName(
                          i,
                          locale: Localizations.localeOf(context).languageCode,
                        ),
                        button: true,
                        selected: settings.accentColorIndex == i,
                        child: Container(
                          width: isLandscape ? 25 : 28,
                          height: isLandscape ? 25 : 28,
                          decoration: BoxDecoration(
                            color: AppTheme.palettes[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (settings.accentColorIndex == i)
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              if (settings.accentColorIndex == i)
                                BoxShadow(
                                  color: AppTheme.palettes[i].withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: settings.accentColorIndex == i
                              ? Icon(
                                  CupertinoIcons.checkmark,
                                  size: isLandscape ? 12.5 : 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.translate_rounded,
            backgroundColor: AppleTokens.systemTeal,
          ),
          title: Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  settings.localeCode == 'en' ? '🇺🇸 EN' : '🇻🇳 VI',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => _pickLanguage(settings.localeCode),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.monetization_on_rounded,
            backgroundColor: AppleTokens.systemYellow,
          ),
          title: Text(l10n.defaultCurrency, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  '${activeCurrencyInfo.symbol} ${activeCurrencyInfo.code}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => _pickCurrency(settings.currencyCode),
        ),
      ],
    );

    // Section 3: Security & Privacy
    final securitySection = AppleListGroup(
      header: l10n.securitySection,
      margin: EdgeInsets.only(bottom: isLandscape ? 14 : 20),
      children: [
        SwitchListTile.adaptive(
          dense: isLandscape,
          secondary: const AppleSquircleBadge(
            icon: Icons.fingerprint_rounded,
            backgroundColor: AppleTokens.systemBlue,
          ),
          title: Text(l10n.biometricLock, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.biometricLockSubtitle, style: const TextStyle(fontSize: 12)),
          value: settings.biometricLockEnabled,
          activeTrackColor: theme.colorScheme.primary,
          onChanged: _handleToggleBiometric,
        ),
      ],
    );

    // Section 4: About & Legal
    final aboutSection = AppleListGroup(
      header: l10n.aboutSection,
      margin: EdgeInsets.only(bottom: isLandscape ? 16 : 24),
      children: [
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.shield_outlined,
            backgroundColor: AppleTokens.systemMint,
          ),
          title: Text(l10n.privacyPolicy, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => context.push(AppRoutes.privacy),
        ),
        ListTile(
          dense: isLandscape,
          leading: const AppleSquircleBadge(
            icon: Icons.info_outline_rounded,
            backgroundColor: Color(0xFF8E8E93),
          ),
          title: Text(l10n.aboutApp, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => context.push(AppRoutes.about),
        ),
      ],
    );

    // Compact, isolated Delete Account & Data Button (subtle & safe from mistaps)
    final deleteAccountButton = user != null
        ? Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLandscape ? 16 : 28),
            child: Center(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                minimumSize: const Size(0, 32),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.12 : 0.08),
                onPressed: authBusy ? null : _confirmDeleteAccount,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (authBusy)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppleTokens.systemRed,
                        ),
                      )
                    else
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 15,
                        color: AppleTokens.systemRed,
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.deleteAccount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemRed,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: AppleHeaderTitle(
          title: l10n.settingsTitle,
          isLandscape: isLandscape,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isLandscape ? 20 : 16,
                isLandscape ? 6 : 8,
                isLandscape ? 20 : 16,
                scrollBottomPadding,
              ),
              children: [
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột 1: Thông tin tài khoản & Quản lý dữ liệu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (profileCard != null) ...[
                              profileCard,
                              SizedBox(height: isLandscape ? 12 : 18),
                            ],
                            dataSection,
                          ],
                        ),
                      ),
                      SizedBox(width: isLandscape ? 16 : 20),
                      // Cột 2: Giao diện trải nghiệm, Bảo mật, Giới thiệu & Xóa tài khoản
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            appearanceSection,
                            securitySection,
                            aboutSection,
                            ?deleteAccountButton,
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  if (profileCard != null) ...[
                    profileCard,
                    const SizedBox(height: 18),
                  ],
                  dataSection,
                  appearanceSection,
                  securitySection,
                  aboutSection,
                  ?deleteAccountButton,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
