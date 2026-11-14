import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/router/app_router.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/widgets/apple_dynamic_ambient_background.dart';
import 'package:so_thu_chi/core/widgets/biometric_lock_gate.dart';
import 'package:so_thu_chi/core/widgets/keyboard_accessory_bar.dart';
import 'package:so_thu_chi/features/settings/domain/entities/app_settings.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Wrapper injected around the router content (Biometric App Lock gate by default).
final appRootWrapperProvider =
    Provider<Widget Function(BuildContext, Widget)>((ref) {
      return (_, child) => BiometricLockGate(child: child);
    });

class SoThuChiApp extends ConsumerWidget {
  const SoThuChiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (themeMode, accentColorIndex, oledMode, localeCode) = ref.watch(
      settingsControllerProvider.select((s) {
        final v = s.value ?? const AppSettings();
        return (v.themeMode, v.accentColorIndex, v.oledMode, v.localeCode);
      }),
    );
    final router = ref.watch(goRouterProvider);
    final rootWrapper = ref.watch(appRootWrapperProvider);

    final accentIndex =
        (accentColorIndex >= 0 && accentColorIndex < AppTheme.palettes.length)
            ? accentColorIndex
            : 0;
    final seedColor = AppTheme.palettes[accentIndex];

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(seedColor),
      darkTheme: AppTheme.dark(seedColor, oledMode),
      themeMode: themeMode,
      locale: Locale(localeCode),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final content = rootWrapper(context, child ?? const SizedBox.shrink());
        return Consumer(
          builder: (context, ref, _) {
            final ambientIndex = ref.watch(ambientBackgroundIndexProvider);
            return AppleDynamicAmbientBackground(
              currentIndex: ambientIndex,
              child: KeyboardDismissBarOverlay(child: content),
            );
          },
        );
      },
    );
  }
}

