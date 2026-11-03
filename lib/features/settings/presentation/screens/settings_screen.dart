import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

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
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                current == 'vi'
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
              ),
              title: Text(l10n.languageVietnamese),
              onTap: () => Navigator.of(ctx).pop('vi'),
            ),
            ListTile(
              leading: Icon(
                current == 'en'
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
              ),
              title: Text(l10n.languageEnglish),
              onTap: () => Navigator.of(ctx).pop('en'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked == current || !mounted) return;
    await ref.read(settingsControllerProvider.notifier).updateLocale(picked);
  }

  Future<void> _pickCurrency(String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in AppCurrencies.supported)
                ListTile(
                  leading: Icon(
                    current == c.code
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text('${c.code} (${c.symbol})'),
                  onTap: () => Navigator.of(ctx).pop(c.code),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
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
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ?? const AppSettings();
    final authBusy = ref.watch(authActionControllerProvider).isLoading;
    final activeCurrencyInfo = AppCurrencies.byCode(settings.currencyCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // User Profile Header Card
          if (user != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppleTokens.jadePrimary,
                      child: Text(
                        (user.displayName?.isNotEmpty == true
                                ? user.displayName![0]
                                : user.email.isNotEmpty
                                ? user.email[0]
                                : 'S')
                            .toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? l10n.appTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Wallets & Categories Quick Access
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.account_balance_wallet_rounded,
                    backgroundColor: AppleTokens.systemGreen,
                  ),
                  title: Text(l10n.walletsTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.accounts),
                ),
                const Divider(indent: 58),
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.category_rounded,
                    backgroundColor: AppleTokens.systemOrange,
                  ),
                  title: Text(l10n.categoriesTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const Divider(indent: 58),
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: CupertinoIcons.person_2_fill,
                    backgroundColor: AppleTokens.systemIndigo,
                  ),
                  title: const Text('Sổ Ghi Nợ'),
                  subtitle: const Text('Quản lý tiền cho vay & đi vay'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.debts),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Appearance & Localization Section
          _SectionHeader(title: l10n.appearanceSection),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppleSquircleBadge(
                            icon: Icons.palette_rounded,
                            backgroundColor: AppleTokens.systemIndigo,
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.themeMode, style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.themeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (sel) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateThemeMode(sel.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.translate_rounded,
                    backgroundColor: AppleTokens.systemTeal,
                  ),
                  title: Text(l10n.language),
                  subtitle: Text(
                    settings.localeCode == 'en'
                        ? l10n.languageEnglish
                        : l10n.languageVietnamese,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickLanguage(settings.localeCode),
                ),
                const Divider(indent: 58),
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.monetization_on_rounded,
                    backgroundColor: AppleTokens.systemYellow,
                  ),
                  title: Text(l10n.defaultCurrency),
                  subtitle: Text(
                    '${activeCurrencyInfo.code} (${activeCurrencyInfo.symbol})',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickCurrency(settings.currencyCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Security & Data Export Section
          _SectionHeader(title: l10n.securitySection),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const AppleSquircleBadge(
                    icon: Icons.fingerprint_rounded,
                    backgroundColor: AppleTokens.systemBlue,
                  ),
                  title: Text(l10n.biometricLock),
                  subtitle: Text(l10n.biometricLockSubtitle),
                  value: settings.biometricLockEnabled,
                  onChanged: _handleToggleBiometric,
                ),
                const Divider(indent: 58),
                ListTile(
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
                  title: Text(l10n.exportCsv),
                  subtitle: Text(l10n.exportCsvSubtitle),
                  trailing: const Icon(Icons.ios_share_rounded, size: 20),
                  onTap: _exportingCsv ? null : _handleExportCsv,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Legal & About Section
          _SectionHeader(title: l10n.aboutSection),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.shield_outlined,
                    backgroundColor: AppleTokens.systemMint,
                  ),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                const Divider(indent: 58),
                ListTile(
                  leading: const AppleSquircleBadge(
                    icon: Icons.info_outline_rounded,
                    backgroundColor: Color(0xFF8E8E93),
                  ),
                  title: Text(l10n.aboutApp),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Account Actions (Sign Out & Delete Account + All Data)
          _SectionHeader(title: l10n.accountSection),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  enabled: !authBusy,
                  leading: const AppleSquircleBadge(
                    icon: Icons.logout_rounded,
                    backgroundColor: AppleTokens.systemOrange,
                  ),
                  title: Text(l10n.signOut),
                  onTap: _confirmSignOut,
                ),
                const Divider(indent: 58),
                ListTile(
                  enabled: !authBusy,
                  leading: const AppleSquircleBadge(
                    icon: Icons.delete_forever_rounded,
                    backgroundColor: AppleTokens.systemRed,
                  ),
                  title: Text(
                    l10n.deleteAccount,
                    style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
