import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';

  static List<_FeatureHighlight> _buildFeatures(AppLocalizations l10n) {
    return [
      _FeatureHighlight(
        icon: CupertinoIcons.layers_alt_fill,
        color: AppleTokens.systemBlue,
        title: l10n.aboutFeature1Title,
        description: l10n.aboutFeature1Desc,
      ),
      _FeatureHighlight(
        icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
        color: AppleTokens.jadePrimary,
        title: l10n.aboutFeature2Title,
        description: l10n.aboutFeature2Desc,
      ),
      _FeatureHighlight(
        icon: CupertinoIcons.gauge,
        color: AppleTokens.systemOrange,
        title: l10n.aboutFeature3Title,
        description: l10n.aboutFeature3Desc,
      ),
      _FeatureHighlight(
        icon: CupertinoIcons.cube_box_fill,
        color: AppleTokens.systemIndigo,
        title: l10n.aboutFeature4Title,
        description: l10n.aboutFeature4Desc,
      ),
      _FeatureHighlight(
        icon: CupertinoIcons.chart_pie_fill,
        color: const Color(0xFFE11D48),
        title: l10n.aboutFeature5Title,
        description: l10n.aboutFeature5Desc,
      ),
      _FeatureHighlight(
        icon: CupertinoIcons.lock_shield_fill,
        color: AppleTokens.systemTeal,
        title: l10n.aboutFeature6Title,
        description: l10n.aboutFeature6Desc,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape = context.isLandscape;
    final features = _buildFeatures(l10n);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.aboutApp),
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
                _AboutIdentityHeroCard(
                  appTitle: l10n.appTitle,
                  versionLabel: l10n.aboutVersionLabel(appVersion),
                  tagline: l10n.appTagline,
                  description: l10n.aboutDescription,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    l10n.aboutCapabilitiesHeader,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                _AboutCapabilitiesCard(features: features),
                const SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.aboutFooterNote,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutIdentityHeroCard extends StatelessWidget {
  const _AboutIdentityHeroCard({
    required this.appTitle,
    required this.versionLabel,
    required this.tagline,
    required this.description,
  });

  final String appTitle;
  final String versionLabel;
  final String tagline;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 26,
      ),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      child: Column(
        children: [
          const SoThuChiLogo(
            size: 76,
            heroTag: 'about_logo_hero',
          ),
          const SizedBox(height: 14),
          Text(
            appTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(
                alpha: isDark ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(
                AppleTokens.radiusPill,
              ),
            ),
            child: Text(
              versionLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCapabilitiesCard extends StatelessWidget {
  const _AboutCapabilitiesCard({required this.features});

  final List<_FeatureHighlight> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppleTokens.hairline,
                indent: 52,
                color: isDark
                    ? AppleTokens.separatorDark
                    : AppleTokens.separatorLight,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppleSquircleBadge(
                    icon: features[i].icon,
                    backgroundColor: features[i].color,
                    size: 38,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          features[i].title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          features[i].description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.42,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureHighlight {
  const _FeatureHighlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}
