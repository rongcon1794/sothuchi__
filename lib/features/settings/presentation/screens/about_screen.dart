import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVi = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppleGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SoThuChiLogo(
                  size: 72,
                  heroTag: 'about_logo_hero',
                ),
                const SizedBox(height: 16),
                Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Phase 1 MVP)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 14),
                Text(
                  isVi
                      ? 'Được thiết kế theo kiến trúc Clean Architecture mở rộng (Flutter + Riverpod + Cloud Firestore Offline-First), lưu trữ tiền tệ chính xác tuyệt đối theo đơn vị nguyên và sẵn sàng mở rộng mô-đun AI thông minh.'
                      : 'Engineered with extensible Clean Architecture (Flutter + Riverpod + Offline-First Cloud Firestore), exact integer minor-unit money precision, and future-ready AI module hooks.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

