import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final res = await ref
        .read(authActionControllerProvider.notifier)
        .signInWithGoogle();
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(error))),
        );
      },
    );
  }

  Future<void> _handleOfflineDemo(BuildContext context, WidgetRef ref) async {
    final res = await ref
        .read(authActionControllerProvider.notifier)
        .signInOfflineDemo();
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(error))),
        );
      },
    );
  }

  void _showFirebaseSetupSheet(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isVi
                        ? 'Hướng dẫn cấu hình Firebase & Google Sign-In'
                        : 'Firebase & Google Sign-In Setup Guide',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isVi
                        ? '1. Tạo dự án trên Firebase Console, bật Authentication -> Google và tạo Cloud Firestore Database.\n'
                              '2. Chạy `flutterfire configure` ở thư mục gốc dự án.\n'
                              '3. Thêm chứng chỉ SHA-1 & SHA-256 cho Android (`cd android && ./gradlew signingReport`) rồi tải lại `google-services.json` đặt vào `android/app/`.\n'
                              '4. Trên iOS, đặt `GoogleService-Info.plist` vào `ios/Runner/` và dán `REVERSED_CLIENT_ID` vào `CFBundleURLSchemes` trong `Info.plist`.\n'
                              '5. Triển khai quy tắc bảo mật: `firebase deploy --only firestore:rules,firestore:indexes`.'
                        : '1. Create a Firebase project, enable Google Auth, and create a Cloud Firestore database.\n'
                              '2. Run `flutterfire configure` in the project root.\n'
                              '3. Add SHA-1 & SHA-256 fingerprints for Android and place `google-services.json` in `android/app/`.\n'
                              '4. Place `GoogleService-Info.plist` in `ios/Runner/` and add `REVERSED_CLIENT_ID` to `Info.plist`.\n'
                              '5. Deploy security rules: `firebase deploy --only firestore:rules,firestore:indexes`.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(ctx.l10n.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financeColors = context.financeColors;
    final actionState = ref.watch(authActionControllerProvider);
    final isLoading = actionState.isLoading;
    final isCloudConfigured = ref
        .watch(authActionControllerProvider.notifier)
        .isCloudAuthConfigured;
    final currentLocale =
        ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'vi', label: Text('VI')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {currentLocale},
                      onSelectionChanged: (selection) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateLocale(selection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 46,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.signInTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _handleGoogleSignIn(context, ref),
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(l10n.signInWithGoogle),
                  ),
                  if (!isCloudConfigured) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: financeColors.warningContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: financeColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: financeColors.onWarningContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.firebaseUnconfiguredBanner,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: financeColors.onWarningContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => _handleOfflineDemo(context, ref),
                                icon: const Icon(Icons.offline_bolt_rounded),
                                label: Text(l10n.tryOfflineDemo),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _showFirebaseSetupSheet(context),
                                icon: const Icon(Icons.menu_book_rounded),
                                label: Text(l10n.viewSetupGuide),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

