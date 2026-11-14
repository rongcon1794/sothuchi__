import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/so_thu_chi_logo.dart';

/// Standardized, branded Apple-grade Data Loading Screen.
///
/// Displayed whenever the application needs to warm up or reload data:
/// - During cold start / process restore while settings or auth are initializing.
/// - When resuming the app after being idle in the background for a long time.
/// - During biometric authentication or critical stream re-synchronization.
///
/// Features the signature [SoThuChiLogo] with a gentle breathing pulse,
/// clear status messaging, and an Apple-style activity indicator to ensure
/// the user never experiences a frozen or unresponsive screen.
class AppDataLoadingView extends StatefulWidget {
  const AppDataLoadingView({
    super.key,
    this.message,
    this.subtitle,
    this.logoSize = 88.0,
    this.showScaffold = true,
  });

  /// Optional custom message displayed below the app title.
  /// Defaults to [context.l10n.loadingData].
  final String? message;

  /// Optional reassuring subtitle (e.g., sync status or security note).
  final String? subtitle;

  /// Size of the [SoThuChiLogo]. Defaults to 88.0.
  final double logoSize;

  /// Whether to wrap the content in a [Scaffold] with [Theme.scaffoldBackgroundColor].
  final bool showScaffold;

  @override
  State<AppDataLoadingView> createState() => _AppDataLoadingViewState();
}

class _AppDataLoadingViewState extends State<AppDataLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // In automated widget tests, avoid infinite repeat so pumpAndSettle can settle cleanly.
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final effectiveMessage = widget.message ?? l10n.loadingData;
    final effectiveSubtitle = widget.subtitle ?? l10n.syncingDataMessage;

    final content = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: '$effectiveMessage. $effectiveSubtitle',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Branded App Logo with gentle breathing pulse
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: SoThuChiLogo(
                    size: widget.logoSize,
                    heroTag: 'app_logo_hero',
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Primary Loading Status Message
                Text(
                  effectiveMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Reassuring Subtitle / Security Context
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    effectiveSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // iOS-Style Activity Indicator
                CupertinoActivityIndicator(
                  radius: 12,
                  animating: !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.showScaffold) {
      return Material(
        color: theme.scaffoldBackgroundColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: content,
    );
  }
}
