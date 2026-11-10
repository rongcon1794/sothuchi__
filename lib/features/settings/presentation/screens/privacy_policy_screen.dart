import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static List<_PolicySectionData> _buildSections(AppLocalizations l10n) {
    return [
      _PolicySectionData(
        icon: CupertinoIcons.doc_text_search,
        color: AppleTokens.systemBlue,
        title: l10n.privacySection1Title,
        bullets: [
          l10n.privacySection1Item1,
          l10n.privacySection1Item2,
          l10n.privacySection1Item3,
          l10n.privacySection1Item4,
        ],
      ),
      _PolicySectionData(
        icon: CupertinoIcons.lock_shield_fill,
        color: AppleTokens.jadePrimary,
        title: l10n.privacySection2Title,
        bullets: [
          l10n.privacySection2Item1,
          l10n.privacySection2Item2,
          l10n.privacySection2Item3,
        ],
      ),
      _PolicySectionData(
        icon: CupertinoIcons.hand_raised_fill,
        color: AppleTokens.systemOrange,
        title: l10n.privacySection3Title,
        bullets: [
          l10n.privacySection3Item1,
          l10n.privacySection3Item2,
        ],
      ),
      _PolicySectionData(
        icon: CupertinoIcons.slider_horizontal_3,
        color: AppleTokens.systemIndigo,
        title: l10n.privacySection4Title,
        bullets: [
          l10n.privacySection4Item1,
          l10n.privacySection4Item2,
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLandscape = context.isLandscape;
    final sections = _buildSections(l10n);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.privacyPolicy),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppleTokens.maxContentWidth,
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                _PrivacyHeroBanner(
                  title: l10n.privacyHeroTitle,
                  subtitle: l10n.privacyHeroSubtitle,
                  body: l10n.privacyHeroBody,
                ),
                const SizedBox(height: 14),
                for (final section in sections) ...[
                  _PolicySectionCard(section: section),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyHeroBanner extends StatelessWidget {
  const _PrivacyHeroBanner({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppleGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: AppleTokens.jadePrimary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppleTokens.jadePrimary.withValues(
                    alpha: isDark ? 0.22 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: AppleTokens.jadePrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.48,
              color: scheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppleGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppleSquircleBadge(
                icon: section.icon,
                backgroundColor: section.color,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < section.bullets.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: section.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.bullets[i],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.icon,
    required this.color,
    required this.title,
    required this.bullets,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> bullets;
}
